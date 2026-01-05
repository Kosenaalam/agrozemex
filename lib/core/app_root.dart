import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/auth/services/auth_service.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/profile/screens/profile_screen.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthService(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AgroZemeX',
        home: const RootDecider(),
      ),
    );
  }
}

class RootDecider extends StatelessWidget {
  const RootDecider({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return auth.user == null
        ? const LoginScreen()
        : const ProfileScreen();
  }
}
