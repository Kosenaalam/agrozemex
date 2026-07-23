import 'package:cloud_firestore/cloud_firestore.dart';

class CropCardModel {
  final String id;
  final String title;
  final double price; 
  final String description;
  final double quantity; 
  final List<String> photoPaths;
  final String cropType; 
  final String unit; 
  final String village;
  final GeoPoint location;
  final Timestamp createdAt;
  final bool isActive;
  final List<String> searchTokens;
  final String createdBy;

  String get sellerId => createdBy;

  CropCardModel({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.quantity,
    required this.photoPaths,
    required this.cropType,
    required this.unit,
    required this.village,
    required this.location,
    required this.createdAt,
    required this.isActive,
    required this.searchTokens,
    this.createdBy = '',
  });

  factory CropCardModel.fromMap(Map<String, dynamic> data, String id) {
    return CropCardModel(
      id: id,
      title: data['title'] ?? 'N/A',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      photoPaths: List<String>.from(data['photo_paths'] ?? []),
      cropType: data['crop_type'] ?? 'Unknown',
      unit: data['unit'] ?? 'kg',
      village: data['village'] ?? 'Unknown',
      location: data['location'] is GeoPoint
          ? data['location'] as GeoPoint
          : (data['location'] is Map
              ? GeoPoint(
                  ((data['location'] as Map)['lat'] as num?)?.toDouble() ?? 0.0,
                  ((data['location'] as Map)['lng'] as num?)?.toDouble() ?? 0.0,
                )
              : const GeoPoint(0, 0)),
      createdAt: data['created_at'] is Timestamp
          ? data['created_at'] as Timestamp
          : (data['created_at'] is int
              ? Timestamp.fromMillisecondsSinceEpoch(data['created_at'] as int)
              : Timestamp.now()),
      isActive: data['is_active'] as bool? ?? true,
      searchTokens: List<String>.from(data['search_tokens'] ?? []),
      createdBy: data['created_by'] ?? '',
    );
  }

  factory CropCardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CropCardModel.fromMap(data, doc.id);
  }
}