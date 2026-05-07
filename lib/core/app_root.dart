import 'package:agrozemex/features/crops/services/crop_query_service.dart';
import 'package:agrozemex/features/crops/services/crop_search_service.dart';
import 'package:agrozemex/features/welcome/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../features/auth/services/auth_service.dart';
import '../shared/services/user_firestore_service.dart';
import '../../shared/services/storage_service.dart';
import '../features/home/services/listing_query_service.dart';
import 'init.dart';
import '../shared/services/location_service.dart';
import '../features/home/services/listing_search_service.dart';

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
        theme: ThemeData( 
          primaryColor: const Color(0xFF0D47A1),
          fontFamily: GoogleFonts.poppins().fontFamily,
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
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
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return  const WelcomeScreen();
  }
}