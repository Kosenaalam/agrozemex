import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/auth/screens/login_screen.dart';
import 'package:agrozemex/features/auth/screens/seller_dashboard.dart';
import 'package:agrozemex/features/wishlist/screens/wishlist_screen.dart';
import 'package:agrozemex/shared/services/phone_binding_dialog.dart';
import 'package:agrozemex/shared/services/user_firestore_service.dart';
import 'package:agrozemex/shared/services/storage_service.dart';
import '../services/auth_service.dart';
import 'package:agrozemex/features/navigation/main_navigation_shell.dart';
import 'package:agrozemex/shared/services/wishlist_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProfileScreenDash extends StatefulWidget {
  const ProfileScreenDash({super.key});

  @override
  State<ProfileScreenDash> createState() => _ProfileScreenDashState();
}

class _ProfileScreenDashState extends State<ProfileScreenDash> {
  Future<Map<String, dynamic>>? _profileFuture;
  String? _cachedUid;
  bool _isUploadingPhoto = false;

  void _showPhotoPickerSheet(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Update Profile Photo',
              style: AgroZemexTokens.headlineMedium.copyWith(
                color: AgroZemexTokens.primary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AgroZemexTokens.primary),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(uid, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AgroZemexTokens.primary),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(uid, ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(String uid, ImageSource source) async {
    final storageService = context.read<StorageService>();
    final userService = context.read<UserFirestoreService>();
    final auth = context.read<AuthService>();
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 80,
      );
      if (picked == null) return;

      if (!mounted) return;
      setState(() => _isUploadingPhoto = true);

      final photoUrl = await storageService.uploadProfileImage(
        File(picked.path),
        uid,
      );

      if (!mounted) return;
      await userService.updateUserProfilePhoto(uid, photoUrl);

      if (!mounted) return;
      await auth.updatePhotoUrl(photoUrl);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated successfully!')),
        );
        setState(() {
          _profileFuture = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update photo: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingPhoto = false);
      }
    }
  }

  void _showEditNameDialog(BuildContext context, String currentName, String uid) {
    final nameCtrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            'Edit Name',
            style: AgroZemexTokens.headlineMedium.copyWith(
              color: AgroZemexTokens.primary,
              fontSize: 20,
            ),
          ),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Full Name',
              hintText: 'Enter your name',
              border: OutlineInputBorder(
                borderRadius: AgroZemexTokens.radiusEight,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AgroZemexTokens.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final newName = nameCtrl.text.trim();
                if (newName.isNotEmpty) {
                  final userService = context.read<UserFirestoreService>();
                  await userService.updateUserName(uid, newName);
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Name updated successfully.')),
                    );
                    setState(() {
                      _profileFuture = null;
                    });
                  }
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

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
      _profileFuture = context.read<UserFirestoreService>().getUserData(
        auth.user!.uid,
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _profileFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(
            body: Center(child: Text('Error loading profile')),
          );
        }

        final userData = snapshot.data!;
        final name = userData['name'] ?? userData['displayName'] ?? 'User Name';
        final rawPhone = (userData['phone'] as String?) ??
            (userData['phoneNumber'] as String?) ??
            (auth.user?.phoneNumber ?? '');
        final phone = rawPhone.trim();
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
                  backgroundColor: AgroZemexTokens.surface.withValues(
                    alpha: 0.8,
                  ),
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
                      icon: const Icon(
                        Icons.logout,
                        color: AgroZemexTokens.onSurfaceVariant,
                      ),
                      onPressed: () async {
                        // Logout via AuthService. The authStateChanges() stream will emit
                        // null → AuthService.user becomes null → notifyListeners() →
                        // the shell's auth guard (index 4) redirects to LoginScreen automatically.
                        // No manual Navigator push needed.
                        await auth.logout();
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
                              GestureDetector(
                                onTap: () => _showPhotoPickerSheet(context, auth.user!.uid),
                                child: Container(
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
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 12,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                    image: DecorationImage(
                                      image: (userData['photoUrl'] != null && (userData['photoUrl'] as String).isNotEmpty)
                                          ? ResizeImage(
                                                NetworkImage(userData['photoUrl']),
                                                width: 200,
                                                height: 200,
                                              ) as ImageProvider
                                          : auth.user?.photoURL != null
                                              ? ResizeImage(
                                                    NetworkImage(
                                                      auth.user!.photoURL!,
                                                    ),
                                                    width: 200,
                                                    height: 200,
                                                  ) as ImageProvider
                                              : const AssetImage(
                                                  AppAssets.defaultAvatar,
                                                ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              if (_isUploadingPhoto)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.black.withValues(alpha: 0.4),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => _showPhotoPickerSheet(context, auth.user!.uid),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AgroZemexTokens.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                name,
                                style: AgroZemexTokens.headlineMedium.copyWith(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AgroZemexTokens.primary,
                                ),
                                tooltip: 'Edit Name',
                                onPressed: () => _showEditNameDialog(
                                  context,
                                  name == 'User Name' ? '' : name,
                                  auth.user!.uid,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AgroZemexTokens.primary.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              role == 'seller'
                                  ? 'Verified Seller'
                                  : 'Verified Buyer',
                              style: AgroZemexTokens.labelCaps.copyWith(
                                color: AgroZemexTokens.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Divider(
                            color: AgroZemexTokens.surfaceContainerLow,
                          ),
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
                                  phone.isNotEmpty ? phone : 'Add / Verify Phone Number',
                                  style: AgroZemexTokens.bodyLarge.copyWith(
                                    fontSize: 14,
                                    color: phone.isNotEmpty
                                        ? AgroZemexTokens.onSurfaceVariant
                                        : AgroZemexTokens.secondary,
                                    fontStyle: phone.isNotEmpty
                                        ? FontStyle.normal
                                        : FontStyle.italic,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.edit_outlined,
                                  size: 18,
                                  color: AgroZemexTokens.primary,
                                ),
                                tooltip: phone.isNotEmpty ? 'Update Phone' : 'Add Phone Number',
                                onPressed: () async {
                                  final success = await PhoneBindingDialog.show(context);
                                  if (success && mounted) {
                                    setState(() {
                                      _profileFuture = null;
                                    });
                                  }
                                },
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
                                StreamBuilder<QuerySnapshot>(
                                  stream: FirebaseFirestore.instance
                                      .collection('listings')
                                      .where(
                                        'created_by',
                                        isEqualTo: auth.user?.uid,
                                      )
                                      .snapshots(),
                                  builder: (context, snapshot) {
                                    final count =
                                        snapshot.data?.docs.length ?? 0;
                                    return Text(
                                      '$count',
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AgroZemexTokens.primary,
                                      ),
                                    );
                                  },
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
                                StreamBuilder<List<String>>(
                                  stream: WishlistService().getWishlistIds(
                                    uid: auth.user?.uid ?? '',
                                  ),
                                  builder: (context, snapshot) {
                                    final count = snapshot.data?.length ?? 0;
                                    return Text(
                                      '$count',
                                      style: GoogleFonts.inter(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AgroZemexTokens.primary,
                                      ),
                                    );
                                  },
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
                                  color: AgroZemexTokens.primary.withValues(
                                    alpha: 0.1,
                                  ),
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
                            final shell = MainNavigationShell.of(context);
                            if (shell != null) {
                              shell.switchTab(2); // Sell Land tab
                            }
                            Navigator.popUntil(
                              context,
                              (route) => route.isFirst,
                            );
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
