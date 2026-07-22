import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../models/listing_filter_model.dart';
import '../models/listing_card_model.dart';
import '../../../shared/services/distance_service.dart';
import '../../../shared/services/location_service.dart';
import '../../../shared/services/search_token_service.dart';
import 'search_rank_service.dart';

class ListingQueryService {
  final FirebaseFirestore _db;
  final DistanceService _distanceService;
  final SearchRankService _searchRankService;
  final LocationService _locationService;

  ListingQueryService({
    FirebaseFirestore? db,
    DistanceService? distanceService,
    SearchRankService? searchRankService,
    LocationService? locationService,
  })  : _db = db ?? FirebaseFirestore.instance,
        _distanceService = distanceService ?? DistanceService(),
        _searchRankService = searchRankService ?? SearchRankService(),
        _locationService = locationService ?? LocationService();

  // PERF FIX: Reduced from 50 to 15. Loading 50 docs + running polygon distance
  // calculation on each caused significant main-thread work on every page fetch.
  // 15 items fills a typical phone screen and loads 3x faster.
  static const int pageSize = 15;
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  String _lastSearchQuery = '';
  ListingFilterModel _lastFilter = ListingFilterModel.empty;

  
  List<String> _getSearchTokens(String query) {
    if (query.isEmpty) return [];
    final normalizedQuery = SearchTokenService.normalize(query);
    final tokens = normalizedQuery.split(' ').where((e) => e.length > 2).toList();
    final expanded = <String>{};
    for (final token in tokens) {
      expanded.add(token);
      expanded.addAll(SearchTokenService.expandWithSynonyms(token));
      expanded.addAll(SearchTokenService.generateNGrams(token));
    }
    final uniqueList = expanded.toList();
    return uniqueList.length > 10 ? uniqueList.sublist(0, 10) : uniqueList;
  }

  List<ListingCardModel> _applyFilters(
    List<ListingCardModel> listings,
    ListingFilterModel filter,
  ) {
    return listings.where((item) {
      if (filter.roadAccess != null && item.roadAccess != filter.roadAccess) return false;
      if (filter.soilType != null && item.soilType != filter.soilType) return false;
      if (filter.waterSource != null && item.waterSource != filter.waterSource) return false;
      if (filter.minAreaSqM != null && item.areaInSqMeters < filter.minAreaSqM!) return false;
      if (filter.maxAreaSqM != null && item.areaInSqMeters > filter.maxAreaSqM!) return false;
      return true;
    }).toList();
  }

  ListingCardModel _docToModel(DocumentSnapshot doc, Position? position) {
    final data = doc.data() as Map<String, dynamic>;
    final List<String> searchTokens = List<String>.from(data['search_tokens'] ?? []);
    final boundaryPoints = (data['boundary_points'] as List)
        .map((p) => mapbox.Point(coordinates: mapbox.Position(p['lng'], p['lat'])))
        .toList();

    final double? distanceMeters = position == null
        ? null
        : _distanceService.distanceToPolygon(
            userLat: position.latitude,
            userLng: position.longitude,
            boundaryPoints: boundaryPoints,
          );

    final double? centerLat = data['center_lat'] as double? ??
        (boundaryPoints.isEmpty ? null : boundaryPoints.map((p) => p.coordinates.lat).reduce((a, b) => a + b) / boundaryPoints.length);
    final double? centerLng = data['center_lng'] as double? ??
        (boundaryPoints.isEmpty ? null : boundaryPoints.map((p) => p.coordinates.lng).reduce((a, b) => a + b) / boundaryPoints.length);

    return ListingCardModel(
      id: doc.id,
      title: data['title'],
      price: (data['price'] as num).toDouble(),
      description: data['description'],
      areaInSqMeters: (data['area_sq_m'] as num).toDouble(),
      boundaryPoints: boundaryPoints,
      photoPaths: List<String>.from(data['photo_paths'] ?? []),
      distanceMeters: distanceMeters,
      roadAccess: data['road_access'] as bool?,
      soilType: data['soil_type'] as String?,
      waterSource: data['water_source'] as String?,
      searchTokens: searchTokens,
      centerLat: centerLat,
      centerLng: centerLng,
    );
  }

  Future<List<ListingCardModel>> fetchListingsInBounds({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    int limit = 50,
  }) async {
    final Position? position = _locationService.currentPosition;

    // Filter latitude bounds on Firestore, and longitude bounds in-memory
    // to avoid Firestore compound inequality bad-filter crashes.
    final query = _db
        .collection('listings')
        .where('center_lat', isGreaterThanOrEqualTo: minLat)
        .where('center_lat', isLessThanOrEqualTo: maxLat)
        .limit(limit);

    final snapshot = await query.get();
    var list = snapshot.docs.map((doc) => _docToModel(doc, position)).toList();

    // In-memory longitude boundary filtering
    list = list.where((item) {
      if (item.centerLng == null) return false;
      return item.centerLng! >= minLng && item.centerLng! <= maxLng;
    }).toList();

    list.sort((a, b) {
      if (a.distanceMeters == null && b.distanceMeters == null) return 0;
      if (a.distanceMeters == null) return 1;
      if (b.distanceMeters == null) return -1;
      return a.distanceMeters!.compareTo(b.distanceMeters!);
    });

    return list;
  }

  Future<List<ListingCardModel>> fetchNextPage({
    String searchQuery = '',
    ListingFilterModel filter = ListingFilterModel.empty,
  }) async {
    // Reset pagination only when search parameters or filters actually change
    if (searchQuery != _lastSearchQuery || filter != _lastFilter) {
      resetPagination();
      _lastSearchQuery = searchQuery;
      _lastFilter = filter;
    }

    if (!_hasMore) return [];

    final Position? position = _locationService.currentPosition;
    final searchTokens = _getSearchTokens(searchQuery);

    final hasInMemoryFilters = filter.roadAccess != null ||
        filter.soilType != null ||
        filter.waterSource != null ||
        filter.minAreaSqM != null ||
        filter.maxAreaSqM != null ||
        filter.village != null;

    final limit = hasInMemoryFilters ? pageSize * 2 : pageSize;

    Query query = _db
        .collection('listings')
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (searchTokens.isNotEmpty) {
      query = query.where('search_tokens', arrayContainsAny: searchTokens);
    }

    // minAreaSqM and maxAreaSqM range queries are removed from Firestore query parameters 
    // to avoid index and sorting order exceptions, and are instead filtered in-memory via _applyFilters.

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.get();
    _hasMore = snapshot.docs.length >= limit;
    if (snapshot.docs.isEmpty) {
      return [];
    }

    _lastDocument = snapshot.docs.last;

    var list = snapshot.docs.map((doc) => _docToModel(doc, position)).toList();

    list = _applyFilters(list, filter);

    if (searchQuery.isNotEmpty) {
      list.sort((a, b) {
        final scoreA = _searchRankService.calculateScore(item: a, query: searchQuery);
        final scoreB = _searchRankService.calculateScore(item: b, query: searchQuery);
        return scoreB.compareTo(scoreA);
      });
    } else {
      list.sort((a, b) {
        if (a.distanceMeters == null && b.distanceMeters == null) return 0;
        if (a.distanceMeters == null) return 1;
        if (b.distanceMeters == null) return -1;
        return a.distanceMeters!.compareTo(b.distanceMeters!);
      });
    }

    return list;
  }

  void resetPagination() {
    _lastDocument = null;
    _hasMore = true;
    // PERF FIX: Also reset search state so changing queries always re-fetches
    // from the beginning. Previously _lastSearchQuery persisted, causing the
    // comparison in fetchNextPage() to skip resetPagination() on repeated clears.
    _lastSearchQuery = '';
    _lastFilter = ListingFilterModel.empty;
  }
}