import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/crop_card_model.dart';

class CropQueryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  DocumentSnapshot? _lastDoc;
  static const _pageSize = 10; 

  Future<List<CropCardModel>> fetchNextPage({
    String? searchQuery,
    String? cropType, 
    double? minPrice, 
    double? maxPrice,
    String? village, 
  }) async {
    var query = _db.collection('crops')
        .where('is_active', isEqualTo: true)
        .orderBy('created_at', descending: true)
        .limit(_pageSize);

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.where('search_tokens', arrayContains: searchQuery.toLowerCase());
    }

    if (cropType != null && cropType.isNotEmpty) {
      query = query.where('crop_type', isEqualTo: cropType);
    }

    if (minPrice != null) {
      query = query.where('price', isGreaterThanOrEqualTo: minPrice);
    }

    if (maxPrice != null) {
      query = query.where('price', isLessThanOrEqualTo: maxPrice);
    }
    if (village != null && village.isNotEmpty) {
      query = query.where('village', isEqualTo: village); 
    }

    if (_lastDoc != null) {
      query = query.startAfterDocument(_lastDoc!);
    }

    final snap = await query.get();
    if (snap.docs.isEmpty) return [];

    _lastDoc = snap.docs.last;
    return snap.docs.map((doc) => CropCardModel.fromFirestore(doc)).toList();
  }

  void resetPagination() {
    _lastDoc = null;
  }
}