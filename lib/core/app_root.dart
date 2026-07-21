import 'package:agrozemex/features/crops/services/crop_query_service.dart';
import 'package:agrozemex/features/crops/services/crop_search_service.dart';
import 'package:agrozemex/features/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/auth/services/auth_service.dart';
import '../shared/services/user_firestore_service.dart';
import '../../shared/services/storage_service.dart';
import '../features/home/services/listing_query_service.dart';
import '../features/auth/screens/login_screen.dart';
import 'init.dart';
import '../shared/services/location_service.dart';
import '../features/home/services/listing_search_service.dart';

import 'theme/theme.dart';

class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider(create: (_) => UserFirestoreService()),
        Provider(create: (_) => ListingQueryService()),
        Provider(create: (_) => ListingSearchService()),
        Provider(create: (_) => StorageService()),
        Provider(create: (_) => CropQueryService()),
        Provider(create: (_) => CropSearchService()),
        Provider<LocationService>(create: (_) => AppInit.locationService),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'AgroZemex',
        theme: AgroZemexTheme.lightTheme,
        home: const RootDecider(),
      ),
    );
  }
}

class RootDecider extends StatefulWidget {
  const RootDecider({super.key});

  @override
  State<RootDecider> createState() => _RootDeciderState();
}

class _RootDeciderState extends State<RootDecider> {
  late Future<String?> _savedPhoneFuture;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthService>();
    _savedPhoneFuture = auth.getSavedPhoneFromPrefs();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    if (auth.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (auth.user != null) {
      return const WelcomeScreen();
    }

    return FutureBuilder<String?>(
      future: _savedPhoneFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final savedPhone = snapshot.data;
        if (savedPhone != null && savedPhone.isNotEmpty) {
          return LoginScreen(initialPhone: savedPhone);
        }

        return const WelcomeScreen();
      },
    );
  }
}