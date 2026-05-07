import 'package:agrozemex/features/crops/services/crop_search_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;


class UserFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  List<String> generateNGrams(String term, {int minLength = 3}) {
    final normalized = normalize(term);
    if (normalized.length < minLength) return [normalized];
    final ngrams = <String>[];
    for (int i = minLength; i <= normalized.length; i++) {
      ngrams.add(normalized.substring(0, i));
    }
    return ngrams;
  }

  Future<void> createUserIfNotExists(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'phone': user.phoneNumber,
        'createdAt': Timestamp.now(), 
        'role': 'buyer', 
      });
    }
  }

  Future<Map<String, dynamic>> getUserData(String uid) async { 
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  List<String> _buildSearchTokens({
    required String title,
    required String description,
    required String soilType,
    required String waterSource,
    required bool roadAccess,
    required String village,
  }) {
    final List<String> fields = [title, description, soilType, waterSource, village];
    if (roadAccess) fields.add('road access highway');

    final combinedText = fields.where((f) => f.isNotEmpty).join(' '); 

    final String normalized = normalize(combinedText);

    final List<String> tokens = normalized
        .split(' ')
        .where((word) => word.length > 2)
        .toSet()
        .toList();

    final expandedTokens = <String>{};
    for (final token in tokens) {
      expandedTokens.add(token);
      expandedTokens.addAll(expandWithSynonyms(token));
      expandedTokens.addAll(generateNGrams(token));
    }

    return expandedTokens.toList();
  }

  Future<void> saveLandListing({
    required String title,
    required double price,
    required String description,
    required double areaInSqMeters,
    required List<mapbox.Point> boundaryPoints,
    required List<String> photoPaths,
    required String soilType,
    required String waterSource,
    required bool roadAccess,
    required String village,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    final searchTokens = _buildSearchTokens(
      title: title,
      description: description,
      soilType: soilType,
      waterSource: waterSource,
      roadAccess: roadAccess,
      village: village,
    );
  print("DEBUG: Attempting to save listing with ${photoPaths.length} photos for user ${user.uid}");
    await _db.collection('listings').add({
      'title': title,
      'price': price,
      'description': description,
      'area_sq_m': areaInSqMeters,
      'soil_type': soilType,
      'water_source': waterSource,
      'road_access': roadAccess,
      'photo_paths': photoPaths,
      'village': village,
      'created_by': user.uid,
      'created_at': FieldValue.serverTimestamp(),
      'boundary_points': boundaryPoints
          .map((p) => {'lat': p.coordinates.lat, 'lng': p.coordinates.lng})
          .toList(),
      'search_tokens': searchTokens,
      'is_active': true, 
    });
    final userDoc = _db.collection('users').doc(user.uid);
    final userSnap = await userDoc.get();
    if (userSnap.exists && userSnap.data()!['role'] == 'buyer') {
      await userDoc.update({'role': 'seller'});
    }
  }

Future<void> saveCropListing({
  required String title,
  required double price,
  required String description,
  required double quantity,
  required List<String> photoPaths,
  required String cropType,
  required String unit,
  required String village,
  required GeoPoint location,
}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User not logged in');
     
     final searchTokens = CropSearchService().buildSearchTokens(
    title: title,
    description: description,
    cropType: cropType,
    village: village,
  ); 


  await _db.collection('crops').add({

    'title': title,
    'price': price,
    'description': description,
    'quantity': quantity,
    'photo_paths': photoPaths,
    'crop_type': cropType,
    'unit': unit,
    'village': village,
    'location': location, 
    'created_by': user.uid,
    'created_at': FieldValue.serverTimestamp(),
    'search_tokens': searchTokens,
    'is_active': true,
  });

  final userDoc = _db.collection('users').doc(user.uid);
  final userSnap = await userDoc.get();
  if (userSnap.exists && userSnap.data()!['role'] == 'buyer') {
    await userDoc.update({'role': 'seller'});
  }
}
}