import 'package:agrozemex/features/crops/services/crop_search_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'search_token_service.dart';

class UserFirestoreService {
  final FirebaseFirestore _db;
  UserFirestoreService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<void> createUserIfNotExists(User user, {bool agreedToTerms = true}) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'email': user.email ?? '',
        'phone': user.phoneNumber ?? '',
        'name': user.displayName ?? '',
        'displayName': user.displayName ?? '',
        'createdAt': Timestamp.now(),
        'role': 'buyer',
        'agreedToTerms': agreedToTerms,
        'termsAgreedAt': agreedToTerms ? Timestamp.now() : null,
      });
    } else {
      final data = snap.data();
      final updates = <String, dynamic>{};
      if (user.displayName != null && user.displayName!.isNotEmpty && (data == null || data['name'] == null || data['name'] == '')) {
        updates['name'] = user.displayName;
        updates['displayName'] = user.displayName;
      }
      if (user.email != null && (data == null || data['email'] == null || data['email'] == '')) {
        updates['email'] = user.email;
      }
      if (user.phoneNumber != null && (data == null || data['phone'] == null || data['phone'] == '')) {
        updates['phone'] = user.phoneNumber;
      }
      if (agreedToTerms && (data == null || data['agreedToTerms'] != true)) {
        updates['agreedToTerms'] = true;
        updates['termsAgreedAt'] = Timestamp.now();
      }
      if (updates.isNotEmpty) {
        await ref.update(updates);
      }
    }
  }

  Future<void> updateUserName(String uid, String name) async {
    final ref = _db.collection('users').doc(uid);
    await ref.set({
      'name': name.trim(),
      'displayName': name.trim(),
    }, SetOptions(merge: true));
  }

  Future<void> updateUserProfilePhoto(String uid, String photoUrl) async {
    final ref = _db.collection('users').doc(uid);
    await ref.set({
      'photoUrl': photoUrl,
      'photoURL': photoUrl,
    }, SetOptions(merge: true));
  }

  Future<void> updateUserPhoneAndTerms(String uid, {required String phone, required bool agreedToTerms}) async {
    final ref = _db.collection('users').doc(uid);
    await ref.set({
      'phone': phone,
      'agreedToTerms': agreedToTerms,
      if (agreedToTerms) 'termsAgreedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<bool> isPhoneAndTermsVerified(User user) async {
    // If Firebase Auth already has phone number
    if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty) {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data();
        return data?['agreedToTerms'] == true;
      }
      return true;
    }

    // Otherwise check Firestore
    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return false;
    final data = doc.data();
    final phone = data?['phone'] as String?;
    final agreed = data?['agreedToTerms'] as bool?;
    return phone != null && phone.isNotEmpty && agreed == true;
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
    final List<String> fields = [
      title,
      description,
      soilType,
      waterSource,
      village,
    ];
    if (roadAccess) fields.add('road access highway');

    final combinedText = fields.where((f) => f.isNotEmpty).join(' ');

    final String normalized = SearchTokenService.normalize(combinedText);

    final List<String> tokens = normalized
        .split(' ')
        .where((word) => word.length > 2)
        .toSet()
        .toList();

    final expandedTokens = <String>{};
    for (final token in tokens) {
      expandedTokens.add(token);
      expandedTokens.addAll(SearchTokenService.expandWithSynonyms(token));
      expandedTokens.addAll(SearchTokenService.generateNGrams(token));
    }

    return expandedTokens.toList();
  }

  Future<void> saveLandListing({
    required String uid,
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
    String? listerType,
    String? landCategory,
    String? ownershipStatus,
    bool? electricityAvailable,
    bool? isFenced,
  }) async {
    final searchTokens = _buildSearchTokens(
      title: title,
      description: description,
      soilType: soilType,
      waterSource: waterSource,
      roadAccess: roadAccess,
      village: village,
    );
    double? centerLat;
    double? centerLng;
    if (boundaryPoints.isNotEmpty) {
      double sumLat = 0;
      double sumLng = 0;
      for (final p in boundaryPoints) {
        sumLat += p.coordinates.lat;
        sumLng += p.coordinates.lng;
      }
      centerLat = sumLat / boundaryPoints.length;
      centerLng = sumLng / boundaryPoints.length;
    }

    await _db.collection('listings').add({
      'title': title,
      'price': price,
      'description': description,
      'area_sq_m': areaInSqMeters,
      'soil_type': soilType,
      'water_source': waterSource,
      'road_access': roadAccess,
      'lister_type': listerType ?? 'owner',
      'land_category': landCategory ?? 'Agricultural',
      'ownership_status': ownershipStatus ?? 'Single Owner (Clear Title)',
      'electricity_available': electricityAvailable ?? false,
      'is_fenced': isFenced ?? false,
      'photo_paths': photoPaths,
      'village': village,
      'created_by': uid,
      'created_at': FieldValue.serverTimestamp(),
      'boundary_points': boundaryPoints
          .map((p) => {'lat': p.coordinates.lat, 'lng': p.coordinates.lng})
          .toList(),
      'search_tokens': searchTokens,
      'is_active': true,
      'center_lat': centerLat,
      'center_lng': centerLng,
    });
    final userDoc = _db.collection('users').doc(uid);
    final userSnap = await userDoc.get();
    if (userSnap.exists && userSnap.data()!['role'] == 'buyer') {
      await userDoc.update({'role': 'seller'});
    }
  }

  Future<void> saveCropListing({
    required String uid,
    required String title,
    required double price,
    required String description,
    required double quantity,
    required List<String> photoPaths,
    required String cropType,
    required String unit,
    required String village,
    required GeoPoint location,
    String harvestStatus = 'Ready for Pickup',
    bool isOrganic = false,
  }) async {
    final searchTokens = CropSearchService.buildSearchTokens(
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
      'crop_type': cropType.trim(),
      'unit': unit,
      'village': village,
      'location': location,
      'created_by': uid,
      'created_at': FieldValue.serverTimestamp(),
      'search_tokens': searchTokens,
      'is_active': true,
      'harvest_status': harvestStatus,
      'is_organic': isOrganic,
    });

    final userDoc = _db.collection('users').doc(uid);
    final userSnap = await userDoc.get();
    if (userSnap.exists && userSnap.data()!['role'] == 'buyer') {
      await userDoc.update({'role': 'seller'});
    }
  }

  Future<void> deleteLandListing(String listingId) async {
    await _db.collection('listings').doc(listingId).delete();
  }

  Future<void> deleteCropListing(String listingId) async {
    await _db.collection('crops').doc(listingId).delete();
  }
}
