import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Production-grade Hive Cache Service for storing land listings, crop listings,
/// and user preferences locally for offline access.
class HiveCacheService {
  static const String landListingsBoxName = 'land_listings_box';
  static const String cropListingsBoxName = 'crop_listings_box';
  static const String userPreferencesBoxName = 'user_preferences_box';

  static Box<String>? _landBox;
  static Box<String>? _cropBox;
  static Box<dynamic>? _userBox;

  /// Recursively converts Cloud Firestore custom instances (Timestamp, GeoPoint)
  /// into standard JSON-encodable primitives (int, Map).
  static Map<String, dynamic> _sanitizeForJson(Map<String, dynamic> raw) {
    final Map<String, dynamic> sanitized = {};
    raw.forEach((key, value) {
      if (value is Timestamp) {
        sanitized[key] = value.millisecondsSinceEpoch;
      } else if (value is GeoPoint) {
        sanitized[key] = {'lat': value.latitude, 'lng': value.longitude};
      } else if (value is DateTime) {
        sanitized[key] = value.millisecondsSinceEpoch;
      } else if (value is List) {
        sanitized[key] = value.map((e) {
          if (e is Timestamp) return e.millisecondsSinceEpoch;
          if (e is GeoPoint) return {'lat': e.latitude, 'lng': e.longitude};
          if (e is Map<String, dynamic>) return _sanitizeForJson(e);
          if (e is Map) return _sanitizeForJson(Map<String, dynamic>.from(e));
          return e;
        }).toList();
      } else if (value is Map<String, dynamic>) {
        sanitized[key] = _sanitizeForJson(value);
      } else if (value is Map) {
        sanitized[key] = _sanitizeForJson(Map<String, dynamic>.from(value));
      } else {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }

  /// Initializes Hive storage and opens default cache boxes.
  static Future<void> init() async {
    try {
      await Hive.initFlutter();

      _landBox = await Hive.openBox<String>(landListingsBoxName);
      _cropBox = await Hive.openBox<String>(cropListingsBoxName);
      _userBox = await Hive.openBox<dynamic>(userPreferencesBoxName);

      debugPrint('HiveCacheService initialized successfully.');
    } catch (e) {
      debugPrint('HiveCacheService init error: $e');
    }
  }

  // ===========================================================================
  // LAND LISTINGS CACHING
  // ===========================================================================

  /// Saves a list of land listing maps into local Hive storage.
  static Future<void> cacheLandListings(List<Map<String, dynamic>> listings) async {
    if (_landBox == null || !Hive.isBoxOpen(landListingsBoxName)) return;

    try {
      for (final item in listings) {
        final id = item['id'] as String?;
        if (id != null && id.isNotEmpty) {
          final sanitized = _sanitizeForJson(item);
          final jsonString = jsonEncode(sanitized);
          await _landBox!.put(id, jsonString);
        }
      }
    } catch (e) {
      debugPrint('Error caching land listings in Hive: $e');
    }
  }

  /// Retrieves all locally cached land listing maps from Hive storage.
  static List<Map<String, dynamic>> getCachedLandListings() {
    if (_landBox == null || !Hive.isBoxOpen(landListingsBoxName)) return [];

    try {
      final List<Map<String, dynamic>> results = [];
      for (final rawJson in _landBox!.values) {
        final map = jsonDecode(rawJson) as Map<String, dynamic>;
        results.add(map);
      }
      return results;
    } catch (e) {
      debugPrint('Error reading cached land listings from Hive: $e');
      return [];
    }
  }

  // ===========================================================================
  // CROP LISTINGS CACHING
  // ===========================================================================

  /// Saves a list of crop listing maps into local Hive storage.
  static Future<void> cacheCropListings(List<Map<String, dynamic>> crops) async {
    if (_cropBox == null || !Hive.isBoxOpen(cropListingsBoxName)) return;

    try {
      for (final item in crops) {
        final id = item['id'] as String?;
        if (id != null && id.isNotEmpty) {
          final sanitized = _sanitizeForJson(item);
          final jsonString = jsonEncode(sanitized);
          await _cropBox!.put(id, jsonString);
        }
      }
    } catch (e) {
      debugPrint('Error caching crop listings in Hive: $e');
    }
  }

  /// Retrieves all locally cached crop listing maps from Hive storage.
  static List<Map<String, dynamic>> getCachedCropListings() {
    if (_cropBox == null || !Hive.isBoxOpen(cropListingsBoxName)) return [];

    try {
      final List<Map<String, dynamic>> results = [];
      for (final rawJson in _cropBox!.values) {
        final map = jsonDecode(rawJson) as Map<String, dynamic>;
        results.add(map);
      }
      return results;
    } catch (e) {
      debugPrint('Error reading cached crop listings from Hive: $e');
      return [];
    }
  }

  // ===========================================================================
  // USER PREFERENCES CACHING
  // ===========================================================================

  /// Caches key-value user preference metadata locally.
  static Future<void> cacheUserData(String key, dynamic value) async {
    if (_userBox == null || !Hive.isBoxOpen(userPreferencesBoxName)) return;
    try {
      await _userBox!.put(key, value);
    } catch (e) {
      debugPrint('Error caching user data in Hive: $e');
    }
  }

  /// Retrieves a cached user preference value by key.
  static dynamic getCachedUserData(String key) {
    if (_userBox == null || !Hive.isBoxOpen(userPreferencesBoxName)) return null;
    return _userBox!.get(key);
  }

  /// Clears all local Hive cache boxes (e.g. on user logout).
  static Future<void> clearAllCache() async {
    try {
      await _landBox?.clear();
      await _cropBox?.clear();
      await _userBox?.clear();
      debugPrint('Hive cache cleared successfully.');
    } catch (e) {
      debugPrint('Error clearing Hive cache: $e');
    }
  }
}
