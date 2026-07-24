import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'firebase_dev_options.dart';
import 'firebase_prod_options.dart';

/// Service responsible for initializing Firebase with environment-specific credentials
class FirebaseInitializer {
  /// Evaluates whether the current runtime environment is set to production flavor
  static bool get isProd => appFlavor == 'prod';

  /// Selects the correct set of options based on the active flavor
  static FirebaseOptions get currentPlatformOptions {
    if (isProd) {
      return FirebaseProdOptions.currentPlatform;
    } else {
      return FirebaseDevOptions.currentPlatform;
    }
  }

  /// Initializes the default Firebase application using product flavors
  static Future<void> initialize() async {
    try {
      final options = currentPlatformOptions;
      await Firebase.initializeApp(
        options: options,
      );
      debugPrint('======================================================');
      debugPrint('🔥 Firebase initialized successfully in [${(appFlavor ?? "dev").toUpperCase()}] flavor');
      debugPrint('🔥 Target Project ID: ${options.projectId}');
      debugPrint('======================================================');
    } catch (e) {
      debugPrint('❌ Firebase Initialization Error: $e');
      rethrow;
    }
  }
}
