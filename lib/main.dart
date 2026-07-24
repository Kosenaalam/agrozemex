import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrozemex/firebase/firebase_initializer.dart';
import 'core/app_root.dart';
import 'core/init.dart';

import 'package:agrozemex/shared/services/hive_cache_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive offline disk cache
  await HiveCacheService.init();

  // Allow runtime fetching as fallback; bundled fonts in assets/fonts/ take primary precedence offline
  GoogleFonts.config.allowRuntimeFetching = true;

  // Initialize Firebase [DEFAULT] app BEFORE mounting AppRoot so FirebaseAuth.instance never fails
  try {
    await FirebaseInitializer.initialize();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(const AppRoot());

  // Non-blocking background service initialization (Mapbox, Location)
  AppInit.initializeBackgroundServices();
}
