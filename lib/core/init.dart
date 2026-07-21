import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../shared/services/location_service.dart';

class AppInit {
  static final LocationService locationService = LocationService();

  static Future<void> initializeBackgroundServices() async {
    try {
      MapboxOptions.setAccessToken(
        'pk.eyJ1Ijoia29zZW5hYWxhbSIsImEiOiJjbWpoMHdsNWcxM282M2dxeDR4djNsc3B3In0.V6myQFEzeMcFWn3CUwnrlQ',
      );

      // Initialize location asynchronously in the background so it never blocks app startup or causes ANR
      unawaited(locationService.initialize().catchError((e) {
        debugPrint('Location async init error: $e');
      }));
    } catch (e) {
      debugPrint('Background init error: $e');
    }
  }
}