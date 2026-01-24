// F:\agrozemex\lib\core\init.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../shared/services/location_service.dart';
import 'package:flutter/foundation.dart';

class AppInit {
  static late LocationService locationService;

  static Future<void> initialize() async {
    // IMPROVED: Wrapped in try-catch for error handling
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      MapboxOptions.setAccessToken(
        'pk.eyJ1Ijoia29zZW5hYWxhbSIsImEiOiJjbWpoMHdsNWcxM282M2dxeDR4djNsc3B3In0.V6myQFEzeMcFWn3CUwnrlQ',
      );

      locationService = LocationService();
      await locationService.initialize();
    } catch (e) {
      // IMPROVED: Handle init errors (e.g., log or throw)
      debugPrint('AppInit error: $e');
      rethrow;
    }
  }
}