import 'package:firebase_core/firebase_core.dart';
import '../firebase_options.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../shared/services/location_service.dart';

class AppInit {
  static late LocationService locationService;

  static Future<void> initialize() async {
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
      rethrow;
    }
  }
}