import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class UserFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------------- EXISTING (DO NOT TOUCH) ----------------
  Future<void> createUserIfNotExists(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'phone': user.phoneNumber,
        'createdAt': DateTime.now(),
      });
    }
  }

  // ---------------- NEW: SAVE LAND LISTING ----------------
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
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');

    await _db.collection('listings').add({
      'title': title,
      'price': price,
      'description': description,
      'area_sq_m': areaInSqMeters,
      'soil_type': soilType,
      'water_source': waterSource,
      'road_access': roadAccess,
      'photo_paths': photoPaths,
      'created_by': user.uid,
      'created_at': FieldValue.serverTimestamp(),
      'boundary_points': boundaryPoints
          .map((p) => {
                'lat': p.coordinates.lat,
                'lng': p.coordinates.lng,
              })
          .toList(),
    });
  }   
  // ---------------- NEW: FETCH ALL LISTINGS ----------------

      Future<List<Map<String, dynamic>>> fetchAllListings() async {
  final snapshot = await _db
      .collection('listings')
      .orderBy('created_at', descending: true)
      .get();

  return snapshot.docs.map((doc) {
    final data = doc.data();

    return {
      'id': doc.id,
      'title': data['title'],
      'price': data['price'],
      'description': data['description'],
      'areaInSqMeters': data['area_sq_m'],
      'photoPaths': List<String>.from(data['photo_paths'] ?? []),
      'boundaryPoints': (data['boundary_points'] as List)
          .map((p) => mapbox.Point(
                coordinates: mapbox.Position(
                  p['lng'],
                  p['lat'],
                ),
              ))
          .toList(),
    };
  }).toList();
}

}
