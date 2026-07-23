import 'dart:convert';
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
          final jsonString = jsonEncode(item);
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
          final jsonString = jsonEncode(item);
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
