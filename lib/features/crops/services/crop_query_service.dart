import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crop_card_model.dart';
import '../../../shared/services/hive_cache_service.dart';

class CropQueryService {
  final FirebaseFirestore _db;
  DocumentSnapshot? _lastDoc;
  static const _pageSize = 10; 
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  CropQueryService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  List<CropCardModel> _applyFilters(
    List<CropCardModel> list, {
    String? searchQuery,
    String? cropType,
    double? minPrice,
    double? maxPrice,
    String? village,
  }) {
    return list.where((item) {
      if (item.isActive == false) return false;
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final title = item.title.toLowerCase();
        final desc = item.description.toLowerCase();
        final type = item.cropType.toLowerCase();
        final vil = item.village.toLowerCase();
        if (!title.contains(q) && !desc.contains(q) && !type.contains(q) && !vil.contains(q)) {
          return false;
        }
      }
      if (cropType != null && cropType.isNotEmpty && cropType != 'All') {
        final target = cropType.toLowerCase().trim();
        final actual = item.cropType.toLowerCase().trim();
        if (!actual.contains(target) && !target.contains(actual)) {
          return false;
        }
      }
      if (village != null && village.isNotEmpty) {
        final targetVillage = village.toLowerCase().trim();
        final actualVillage = item.village.toLowerCase().trim();
        if (!actualVillage.contains(targetVillage)) return false;
      }
      if (minPrice != null && item.price < minPrice) return false;
      if (maxPrice != null && item.price > maxPrice) return false;
      return true;
    }).toList();
  }

  Future<List<CropCardModel>> fetchNextPage({
    String? searchQuery,
    String? cropType, 
    double? minPrice, 
    double? maxPrice,
    String? village, 
  }) async {
    if (!_hasMore) return [];

    final hasInMemoryFilters = (searchQuery != null && searchQuery.isNotEmpty) ||
        (cropType != null && cropType != 'All') ||
        village != null ||
        minPrice != null ||
        maxPrice != null;
    final limit = hasInMemoryFilters ? _pageSize * 4 : _pageSize;

    // Index-free simple query to guarantee zero Firestore precondition / compound index crashes
    Query query = _db.collection('crops').limit(limit);

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    try {
      final snap = await query.get();
      _hasMore = snap.docs.length >= limit;
      if (snap.docs.isEmpty) return [];

      _lastDoc = snap.docs.last;

      final rawMaps = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final m = Map<String, dynamic>.from(doc.data() as Map);
        m['id'] = doc.id;
        rawMaps.add(m);
      }
      // Cache fetched crop listings into Hive
      HiveCacheService.cacheCropListings(rawMaps);

      var list = snap.docs.map((doc) => CropCardModel.fromFirestore(doc)).toList();

      return _applyFilters(
        list,
        searchQuery: searchQuery,
        cropType: cropType,
        minPrice: minPrice,
        maxPrice: maxPrice,
        village: village,
      );
    } catch (e) {
      // Offline fallback: Read cached crop listings from Hive
      final cachedMaps = HiveCacheService.getCachedCropListings();
      if (cachedMaps.isEmpty) return [];

      var list = cachedMaps
          .map((m) => CropCardModel.fromMap(m, m['id'] as String? ?? ''))
          .toList();

      _hasMore = false;
      return _applyFilters(
        list,
        searchQuery: searchQuery,
        cropType: cropType,
        minPrice: minPrice,
        maxPrice: maxPrice,
        village: village,
      );
    }
  }

  void resetPagination() {
    _lastDoc = null;
    _hasMore = true;
  }
}