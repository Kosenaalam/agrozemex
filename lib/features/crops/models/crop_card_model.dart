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
  });

  factory CropCardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CropCardModel(
      id: doc.id,
      title: data['title'] ?? 'N/A',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      photoPaths: List<String>.from(data['photo_paths'] ?? []),
      cropType: data['crop_type'] ?? 'Unknown',
      unit: data['unit'] ?? 'kg',
      village: data['village'] ?? 'Unknown',
      location: data['location'] as GeoPoint? ?? const GeoPoint(0, 0),
      createdAt: data['created_at'] as Timestamp? ?? Timestamp.now(),
      isActive: data['is_active'] as bool? ?? true,
      searchTokens: List<String>.from(data['search_tokens'] ?? []),
    );
  }
}