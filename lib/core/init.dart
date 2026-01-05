import 'package:firebase_core/firebase_core.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../firebase_options.dart';

class AppInit {
  static Future<void> initialize() async {
    // Firebase
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Mapbox (ONLY PLACE WHERE TOKEN IS SET)
    MapboxOptions.setAccessToken(
      'pk.eyJ1Ijoia29zZW5hYWxhbSIsImEiOiJjbWpoMHdsNWcxM282M2dxeDR4djNsc3B3In0.V6myQFEzeMcFWn3CUwnrlQ',
    );
  }
}
