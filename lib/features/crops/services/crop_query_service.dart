import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crop_card_model.dart';

class CropQueryService {
  final FirebaseFirestore _db;
  DocumentSnapshot? _lastDoc;
  static const _pageSize = 10; 
  bool _hasMore = true;

  bool get hasMore => _hasMore;

  CropQueryService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<List<CropCardModel>> fetchNextPage({
    String? searchQuery,
    String? cropType, 
    double? minPrice, 
    double? maxPrice,
    String? village, 
  }) async {
    if (!_hasMore) return [];

    final hasInMemoryFilters = minPrice != null || maxPrice != null;
    final limit = hasInMemoryFilters ? _pageSize * 2 : _pageSize;

    var query = _db.collection('crops')
        .where('is_active', isEqualTo: true)
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      final tokens = searchQuery.toLowerCase().split(' ').where((t) => t.length > 2).toList();
      if (tokens.isNotEmpty) {
        query = query.where('search_tokens', arrayContainsAny: tokens.take(10).toList());
      }
    }

    if (cropType != null && cropType.isNotEmpty) {
      query = query.where('crop_type', isEqualTo: cropType);
    }

    if (village != null && village.isNotEmpty) {
      query = query.where('village', isEqualTo: village); 
    }

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snap = await query.get();
    _hasMore = snap.docs.length >= limit;
    if (snap.docs.isEmpty) return [];

    _lastDoc = snap.docs.last;
    var list = snap.docs.map((doc) => CropCardModel.fromFirestore(doc)).toList();

    // In-memory price range filtering to prevent range query sorting crashes on Firestore
    if (minPrice != null) {
      list = list.where((item) => item.price >= minPrice).toList();
    }
    if (maxPrice != null) {
      list = list.where((item) => item.price <= maxPrice).toList();
    }
    return list;
  }

  void resetPagination() {
    _lastDoc = null;
    _hasMore = true;
  }
}