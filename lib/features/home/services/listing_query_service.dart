// F:\agrozemex\lib\features\home\services\listing_query_service.dart
// CHANGED: Made _normalize and _expandWithSynonyms public (removed _) so they can be reused in save logic
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

  static const int pageSize = 50; // Larger page for efficiency, but tune based on perf
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;

  // Synonym mapping for common terms (expandable for industrial-grade handling)
  // Key: base term, Value: list of synonyms including the base
  // Example: 'road' maps to ['road', 'highway', 'street', 'pathway']
  // Add domain-specific synonyms for agriculture/land (e.g., 'tehsil' variations, 'village' in local languages)
  final Map<String, List<String>> _synonyms = {
    'road': ['road', 'highway', 'street', 'pathway', 'lane'],
    'village': ['village', 'gaon', 'gram', 'pind'], // Common variations in Hindi/Punjabi
    'tehsil': ['tehsil', 'taluka', 'mandal', 'block'], // Regional equivalents
    'farm': ['farm', 'khet', 'land', 'plot', 'acreage'],
    'water': ['water', 'paani', 'irrigation', 'borewell'],
    // Add more as needed for industrial expansion (e.g., from a configurable file or DB)
  };

  // Normalization function: Industrial-grade handling
  // - Lowercase
  // - Trim whitespace
  // - Remove non-alphanumeric (keep spaces for multi-word)
  // - Handle common abbreviations/misspellings (expandable rules)
  // - Remove diacritics if needed (for international names, but simple here)
  // CHANGED: Made public for reuse in save logic
  String normalize(String input) {
    String normalized = input.toLowerCase().trim();
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9 ]'), ''); // Remove special chars
    // Custom rules for village/tehsil normalization (e.g., handle common prefixes/suffixes)
    normalized = normalized.replaceAll('st.', 'street').replaceAll('hwy', 'highway');
    // Add more rules for Indian place names (e.g., 'pur' suffix for villages)
    if (normalized.endsWith('pur') || normalized.endsWith('nagar')) {
      normalized = normalized.replaceAll('pur', 'pur').replaceAll('nagar', 'nagar'); // Placeholder for advanced stemming
    }
    return normalized;
  }

  // Expand token with synonyms
  // CHANGED: Made public for reuse in save logic
  List<String> expandWithSynonyms(String token) {
    for (final entry in _synonyms.entries) {
      if (entry.value.contains(token)) {
        return entry.value; // Return all synonyms if token matches any
      }
    }
    return [token]; // No synonyms, return original
  }

  // Extract and process search tokens from query
  // - Normalize entire query
  // - Split into tokens (>2 chars)
  // - Expand each with synonyms
  // - Flatten and unique
  // - Limit to 10 for Firestore arrayContainsAny constraint
  List<String> _getSearchTokens(String query) {
    if (query.isEmpty) return [];
    final normalizedQuery = normalize(query);
    final tokens = normalizedQuery.split(' ').where((e) => e.length > 2).toList();
    final expanded = <String>{};
    for (final token in tokens) {
      expanded.addAll(expandWithSynonyms(token));
    }
    final uniqueList = expanded.toList();
    // Sort by relevance if needed (e.g., original tokens first), but simple here
    return uniqueList.length > 10 ? uniqueList.sublist(0, 10) : uniqueList;
  }

  // Token schema (frozen): search_tokens array in Firestore should contain:
  // - Normalized village name and its synonyms
  // - Normalized tehsil name and its synonyms
  // - Normalized highway/road names and synonyms
  // - Keywords from title/description (normalized)
  // - Soil type, water source (as tags if searchable)
  // Assumption: When creating/updating listing in Firestore, use similar normalize and expandWithSynonyms
  // to populate search_tokens. This ensures consistency between query and storage.
  // Example: For a listing with village: 'Agra Gaon', tehsil: 'Agra Taluka', road: 'NH2 Highway'
  // Tokens: ['agra gaon', 'agra', 'gaon', 'village', 'gram', 'agra taluka', 'agra', 'taluka', 'tehsil', 'mandal', 'block', 'nh2 highway', 'nh2', 'highway', 'road', 'street']

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

    return ListingCardModel(
      id: doc.id,
      title: data['title'],
      price: (data['price'] as num).toDouble(),
      description: data['description'],
      // it remove previous listing
      //  village: data['village'],
      areaInSqMeters: (data['area_sq_m'] as num).toDouble(),
      boundaryPoints: boundaryPoints,
      photoPaths: List<String>.from(data['photo_paths'] ?? []),
      distanceMeters: distanceMeters,
      roadAccess: data['road_access'] as bool?,
      soilType: data['soil_type'] as String?,
      waterSource: data['water_source'] as String?,
      searchTokens: searchTokens,
    
    );
  }

  // For map: Fetch within bounds (assume listings have 'center_lat' and 'center_lng' fields precomputed)
  Future<List<ListingCardModel>> fetchListingsInBounds({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    int limit = 100, // Limit for map to prevent overload
  }) async {
    Position? position = LocationService().currentPosition;

    final query = _db
        .collection('listings')
        .where('center_lat', isGreaterThanOrEqualTo: minLat)
        .where('center_lat', isLessThanOrEqualTo: maxLat)
        .where('center_lng', isGreaterThanOrEqualTo: minLng)
        .where('center_lng', isLessThanOrEqualTo: maxLng)
        .orderBy('created_at', descending: true)
        .limit(limit);

    final snapshot = await query.get();
    final list = snapshot.docs.map((doc) => _docToModel(doc, position)).toList();

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
    // CHANGED: Moved safety reset before the early return check for _hasMore
    if (searchQuery.isEmpty && _lastDocument != null) {
      resetPagination();
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

    // Add more server-side filters if possible (e.g., for area, if indexed)
    if (filter.minAreaSqM != null) {
      query = query.where('area_sq_m', isGreaterThanOrEqualTo: filter.minAreaSqM);
    }
    if (filter.maxAreaSqM != null) {
      query = query.where('area_sq_m', isLessThanOrEqualTo: filter.maxAreaSqM);
    }
    // Similar for other fields if they support querying

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
      return scoreB.compareTo(scoreA); // Higher score first
    });

    // Secondary sort by distance
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