import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../models/listing_filter_model.dart';
import '../models/listing_card_model.dart';
import '../../../shared/services/distance_service.dart';
import '../../../shared/services/location_service.dart';
import 'search_rank_service.dart';

class ListingQueryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final DistanceService _distanceService = DistanceService();
  final SearchRankService _searchRankService = SearchRankService();

  static const int pageSize = 50; 
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  String _lastSearchQuery = '';
  ListingFilterModel _lastFilter = ListingFilterModel.empty;

  
  final Map<String, List<String>> _synonyms = {
    'road': ['road', 'highway', 'street', 'pathway', 'lane'],
    'village': ['village', 'gaon', 'gram', 'pind'], 
    'tehsil': ['tehsil', 'taluka', 'mandal', 'block'], 
    'farm': ['farm', 'khet', 'land', 'plot', 'acreage'],
    'water': ['water', 'paani', 'irrigation', 'borewell'],
  };

  String normalize(String input) {
    String normalized = input.toLowerCase().trim();
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9 ]'), ''); 
    normalized = normalized.replaceAll('st.', 'street').replaceAll('hwy', 'highway');
    if (normalized.endsWith('pur') || normalized.endsWith('nagar')) {
      normalized = normalized.replaceAll('pur', 'pur').replaceAll('nagar', 'nagar'); 
    }
    return normalized;
  }

 
  List<String> expandWithSynonyms(String token) {
    for (final entry in _synonyms.entries) {
      if (entry.value.contains(token)) {
        return entry.value; 
      }
    }
    return [token]; 
  }

  List<String> _getSearchTokens(String query) {
    if (query.isEmpty) return [];
    final normalizedQuery = normalize(query);
    final tokens = normalizedQuery.split(' ').where((e) => e.length > 2).toList();
    final expanded = <String>{};
    for (final token in tokens) {
      expanded.addAll(expandWithSynonyms(token));
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
    int limit = 100, 
  }) async {
    Position? position = LocationService().currentPosition;

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
        
    Position? position = LocationService().currentPosition;
    final searchTokens = _getSearchTokens(searchQuery);

    Query query = _db
        .collection('listings')
        .orderBy('created_at', descending: true)
        .limit(pageSize);

    if (searchTokens.isNotEmpty) {
      query = query.where('search_tokens', arrayContainsAny: searchTokens);
    }

    // minAreaSqM and maxAreaSqM range queries are removed from Firestore query parameters 
    // to avoid index and sorting order exceptions, and are instead filtered in-memory via _applyFilters.

    if (_lastDocument != null) {
      query = query.startAfterDocument(_lastDocument!);
    }

    final snapshot = await query.get();
    if (snapshot.docs.isEmpty) {
      _hasMore = false;
      return [];
    }

    _lastDocument = snapshot.docs.last;

    var list = snapshot.docs.map((doc) => _docToModel(doc, position)).toList();

    list = _applyFilters(list, filter);

    list.sort((a, b) {
      final scoreA = _searchRankService.calculateScore(item: a, query: searchQuery);
      final scoreB = _searchRankService.calculateScore(item: b, query: searchQuery);
      return scoreB.compareTo(scoreA);
    });

    list.sort((a, b) {
      if (a.distanceMeters == null && b.distanceMeters == null) return 0;
      if (a.distanceMeters == null) return 1;
      if (b.distanceMeters == null) return -1;
      return a.distanceMeters!.compareTo(b.distanceMeters!);
    });

    return list;
  }

  void resetPagination() {
    _lastDocument = null;
    _hasMore = true;
  }
}