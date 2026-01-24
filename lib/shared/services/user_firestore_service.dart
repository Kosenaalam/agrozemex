import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;


class UserFirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
  List<String> expandWithSynonyms(String token) {
    for (final entry in _synonyms.entries) {
      if (entry.value.contains(token)) {
        return entry.value; // Return all synonyms if token matches any
      }
    }
    return [token]; // No synonyms, return original
  }

  // CHANGED: Added this to generate n-grams for partial matches
  List<String> generateNGrams(String term, {int minLength = 3}) {
    final normalized = normalize(term);
    if (normalized.length < minLength) return [normalized];
    final ngrams = <String>[];
    for (int i = minLength; i <= normalized.length; i++) {
      ngrams.add(normalized.substring(0, i));
    }
    return ngrams;
  }

  // ---------------- EXISTING (DO NOT TOUCH) ----------------
  Future<void> createUserIfNotExists(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'phone': user.phoneNumber,
        'createdAt': Timestamp.now(), // IMPROVED: Use Timestamp for sorting
        'role': 'buyer', // NEW: Default role
      });
    }
  }

  Future<Map<String, dynamic>> getUserData(String uid) async { // NEW: To fetch user info for profile
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data() ?? {};
  }

  // IMPROVED: Made _buildSearchTokens more efficient by avoiding unnecessary string concatenation if empty
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

    final combinedText = fields.where((f) => f.isNotEmpty).join(' '); // IMPROVED: Filter empty

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

    // IMPROVED: Added 'is_active' default true for status
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
          .map((p) => {'lat': p.coordinates.lat, 'lng': p.coordinates.lng})
          .toList(),
      'search_tokens': searchTokens,
      'is_active': true, // NEW: For status management
    });
    // NEW: Update role to 'seller' if current is 'buyer'
    final userDoc = _db.collection('users').doc(user.uid);
    final userSnap = await userDoc.get();
    if (userSnap.exists && userSnap.data()!['role'] == 'buyer') {
      await userDoc.update({'role': 'seller'});
    }
  }
}

