import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'core/app_root.dart';
import 'core/init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Disable dynamic runtime font downloading to prevent HTTP locks during text paint
  GoogleFonts.config.allowRuntimeFetching = false;

  // Initialize Firebase [DEFAULT] app BEFORE mounting AppRoot so FirebaseAuth.instance never fails
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  runApp(const AppRoot());

  // Non-blocking background service initialization (Mapbox, Location)
  AppInit.initializeBackgroundServices();
}
