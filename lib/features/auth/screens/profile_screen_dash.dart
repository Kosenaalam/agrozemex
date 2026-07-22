import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/auth/screens/login_screen.dart'; 
import 'package:agrozemex/features/auth/screens/seller_dashboard.dart';
import 'package:agrozemex/features/wishlist/screens/wishlist_screen.dart';
import 'package:agrozemex/shared/services/user_firestore_service.dart';
import '../services/auth_service.dart';

class ProfileScreenDash extends StatefulWidget {
  const ProfileScreenDash({super.key});

  @override
  State<ProfileScreenDash> createState() => _ProfileScreenDashState();
}

class _ProfileScreenDashState extends State<ProfileScreenDash> {
  Future<Map<String, dynamic>>? _profileFuture;
  String? _cachedUid;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.user == null) {
      return const LoginScreen();
    }

    if (_profileFuture == null || _cachedUid != auth.user!.uid) {
      _cachedUid = auth.user!.uid;
      // PERF FIX: Use the Provider-registered singleton instead of creating a new
      // UserFirestoreService() instance on every rebuild. New instances create
      // separate Firestore connection state that is never properly disposed.
      _profileFuture = context.read<UserFirestoreService>().getUserData(auth.user!.uid);
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(body: Center(child: Text('Error loading profile')));
        }

        final userData = snapshot.data!;
        final name = userData['name'] ?? userData['displayName'] ?? 'Alexander Sterling';
        final phone = userData['phone'] ?? '';
        final email = userData['email'] ?? auth.user?.email ?? 'N/A';
        final role = userData['role'] ?? 'buyer';

        return Scaffold(
          backgroundColor: AgroZemexTokens.surface,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(64),
            child: ClipRRect(
              child: BackdropFilter(
                filter: AgroZemexTokens.glassBlurFilter,
                child: AppBar(
                  backgroundColor: AgroZemexTokens.surface.withValues(alpha: 0.8),
                  elevation: 0,
                  automaticallyImplyLeading: false,
                  title: Text(
                    'My Profile',
                    style: AgroZemexTokens.headlineMedium.copyWith(
                      color: AgroZemexTokens.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  actions: [
                    IconButton( 
                      icon: const Icon(Icons.logout, color: AgroZemexTokens.onSurfaceVariant),
                      onPressed: () async {
                        await auth.logout();
                        if (context.mounted) {
                          Navigator.pushReplacement( 
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
          ),
          body: RefreshIndicator(
            color: AgroZemexTokens.primary,
            onRefresh: () async {
              setState(() {
                _profileFuture = null;
              });
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AgroZemexTokens.marginMobile,
                  vertical: 16,
                ),
                child: Column(
                  children: [
                    // User Overview Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AgroZemexTokens.surfaceContainerLowest,
                        borderRadius: AgroZemexTokens.radiusEight,
                        boxShadow: AgroZemexTokens.softShadows,
                        border: Border.all(
                          color: AgroZemexTokens.surfaceContainerLow,
                        ),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          // Avatar with Verified Badge
                          Stack(
                            children: [
                              Container(
                                width: 96,
                                height: 96,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AgroZemexTokens.surfaceContainerLow,
                                    width: 4,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.08),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                  image: DecorationImage(
                                    image: auth.user?.photoURL != null
                                        ? ResizeImage(
                                            NetworkImage(auth.user!.photoURL!),
                                            width: 200,
                                            height: 200,
                                          ) as ImageProvider
                                        : const AssetImage(AppAssets.defaultAvatar),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: AgroZemexTokens.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.verified,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            name,
                            style: AgroZemexTokens.headlineMedium.copyWith(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AgroZemexTokens.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              role == 'seller' ? 'Verified Seller' : 'Verified Buyer',
                              style: AgroZemexTokens.labelCaps.copyWith(
                                color: AgroZemexTokens.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Divider(color: AgroZemexTokens.surfaceContainerLow),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.mail_outline,
                                size: 20,
                                color: AgroZemexTokens.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  email,
                                  style: AgroZemexTokens.bodyLarge.copyWith(
                                    fontSize: 14,
                                    color: AgroZemexTokens.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.call_outlined,
                                size: 20,
                                color: AgroZemexTokens.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  phone.isNotEmpty ? phone : '+44 (0) 20 7946 0123',
                                  style: AgroZemexTokens.bodyLarge.copyWith(
                                    fontSize: 14,
                                    color: AgroZemexTokens.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AgroZemexTokens.gapSmall),

                    // Stats Row (Properties Listed & Wishlist Items)
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AgroZemexTokens.surfaceContainerLow,
                              borderRadius: AgroZemexTokens.radiusEight,
                              border: Border.all(
                                color: AgroZemexTokens.surfaceContainerLow,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'PROPERTIES LISTED',
                                  style: AgroZemexTokens.labelCaps.copyWith(
                                    fontSize: 10,
                                    color: AgroZemexTokens.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '4',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AgroZemexTokens.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AgroZemexTokens.surfaceContainerLow,
                              borderRadius: AgroZemexTokens.radiusEight,
                              border: Border.all(
                                color: AgroZemexTokens.surfaceContainerLow,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'WISHLIST ITEMS',
                                  style: AgroZemexTokens.labelCaps.copyWith(
                                    fontSize: 10,
                                    color: AgroZemexTokens.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '12',
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: AgroZemexTokens.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AgroZemexTokens.gapSmall),

                    // Action Tile: My Wishlist
                    Material(
                      color: AgroZemexTokens.surfaceContainerLowest,
                      borderRadius: AgroZemexTokens.radiusEight,
                      elevation: 1,
                      child: InkWell(
                        borderRadius: AgroZemexTokens.radiusEight,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const WishlistScreen(),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AgroZemexTokens.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.favorite,
                                  color: AgroZemexTokens.primary,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'My Wishlist',
                                style: AgroZemexTokens.bodyLarge.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Spacer(),
                              const Icon(
                                Icons.chevron_right,
                                color: AgroZemexTokens.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AgroZemexTokens.gapMedium),

                    // My Listings Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'My Listings',
                          style: AgroZemexTokens.headlineMedium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            // Add New Action
                          },
                          child: Text(
                            'ADD NEW',
                            style: AgroZemexTokens.labelCaps.copyWith(
                              color: AgroZemexTokens.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (role == 'seller' || role == 'buyer') ...[
                      SizedBox(
                        height: 340,
                        child: SellerDashboard(userId: auth.user!.uid),
                      ),
                    ],

                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/*
================================================================================
PREVIOUS PROFILE SCREEN DASH CODE (PRESERVED IN COMMENTED FORM AS REQUESTED)
================================================================================

import 'package:agrozemex/features/auth/screens/login_screen.dart'; 
import 'package:agrozemex/features/auth/screens/seller_dashboard.dart';
import 'package:agrozemex/shared/services/user_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:agrozemex/features/wishlist/screens/wishlist_screen.dart';


class _OldProfileScreenDashState extends State<ProfileScreenDash> {
  Future<Map<String, dynamic>>? _profileFuture;
  String? _cachedUid;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.user == null) {
      return const LoginScreen();
    }

    if (_profileFuture == null || _cachedUid != auth.user!.uid) {
      _cachedUid = auth.user!.uid;
      _profileFuture = UserFirestoreService().getUserData(auth.user!.uid);
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(body: Center(child: Text('Error loading profile')));
        }

        final userData = snapshot.data!;
        final phone = userData['phone'] ?? '';
        final email = userData['email'] ?? auth.user?.email ?? 'N/A';
        final createdAt = (userData['createdAt'] as Timestamp?)?.toDate().toString() ?? 'N/A';
        final role = userData['role'] ?? 'buyer';

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Colors.white,
            actions: [
              IconButton( 
                icon: const Icon(Icons.logout),
                color: Colors.white,
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushReplacement( 
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  }
                },
              ),
            ],
          ),
          body: 
              RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _profileFuture = null;
                  });
                },
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.email, color: Color(0xFF0D47A1)),
                              title: Text('Email Address', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                              subtitle: Text(email),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.phone, color: Color(0xFF0D47A1)),
                              title: Text('Phone Number', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                              subtitle: Text(phone.isNotEmpty ? phone : 'Not Linked'),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.calendar_today, color: Color(0xFF0D47A1)),
                              title: Text('Account Created', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                              subtitle: Text(createdAt),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.person_outline, color: Color(0xFF0D47A1)),
                              title: Text('Role', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                             subtitle: Text(
                             role.isNotEmpty 
                              ? role[0].toUpperCase() + role.substring(1).toLowerCase() 
                            : role
                             ),
                            ),
                          ],
                        ),
                      ),
                    ),
              
                       Card(
                       elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     child: Column(
                      children: [
                      ListTile(
                     leading: const Icon(Icons.favorite, color: Colors.red),
                     title: Text(
                     'My Wishlist',
                     style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                   ),
                     trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                  builder: (_) => const WishlistScreen(),
                ),
              );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
                    const SizedBox(height: 20),
                    if (role == 'seller') 
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Listings', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 300,
                            child: SellerDashboard(userId: auth.user!.uid),
                          ),
                        ],
                      ),
                    if (role == 'buyer') 
                      const Center(
                        child: Text('You are a buyer. Create a listing to become a seller!'),
                      ),
                  ],
                ),
              ),
        );
      },
    );
  }
}
================================================================================
*/
