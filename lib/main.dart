import 'package:flutter/material.dart';
import 'core/app_root.dart';
import 'core/init.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await AppInit.initialize().timeout(const Duration(seconds: 10));
  } catch (e) {
    // Log or show error app-wide (e.g., runApp(ErrorApp(e)))
    debugPrint('Init error: $e');
  }
  runApp(const AppRoot());
}
