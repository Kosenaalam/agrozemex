import 'package:flutter/material.dart';
import 'core/app_root.dart';
import 'core/init.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppInit.initialize();
  runApp(const AppRoot());
}
