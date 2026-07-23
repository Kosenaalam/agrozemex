import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:agrozemex/core/theme/theme.dart';
import '../models/crop_card_model.dart';

import 'package:provider/provider.dart';
import 'package:agrozemex/features/auth/screens/login_screen.dart';
import 'package:agrozemex/features/auth/services/auth_service.dart';
import 'package:agrozemex/shared/services/phone_binding_dialog.dart';
import 'package:agrozemex/shared/services/user_firestore_service.dart';
import 'package:agrozemex/shared/widget/seller_contact_disclaimer_dialog.dart';
import 'package:agrozemex/shared/widget/universal_image_widget.dart';

class CropDetailScreen extends StatefulWidget {
  final CropCardModel item;

  const CropDetailScreen({super.key, required this.item});

  @override
  State<CropDetailScreen> createState() => _CropDetailScreenState();
}

class _CropDetailScreenState extends State<CropDetailScreen> {
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  bool _isSellerPhoneRevealed = false;

  Future<void> _handleRevealSellerPhone(String rawPhone) async {
    if (_isSellerPhoneRevealed) return;
    final auth = context.read<AuthService>();
    final user = auth.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to view seller phone number.')),
      );
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    final userService = context.read<UserFirestoreService>();
    final verified = await userService.isPhoneAndTermsVerified(user);
    if (!verified && mounted) {
      final success = await PhoneBindingDialog.show(context);
      if (!success) return;
    }

    if (!mounted) return;
    final agreed = await SellerContactDisclaimerDialog.show(context);
    if (agreed && mounted) {
      setState(() {
        _isSellerPhoneRevealed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seller contact unmasked. Strictly use for harvest purchase inquiries.')),
      );
    }
  }

  Future<void> _callPhone(String phone) async {
    if (!_isSellerPhoneRevealed) {
      await _handleRevealSellerPhone(phone);
      if (!_isSellerPhoneRevealed) return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('tel:$cleanPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not dial $phone')),
        );
      }
    }
  }

  Future<void> _openWhatsApp(String phone, String cropTitle) async {
    if (!_isSellerPhoneRevealed) {
      await _handleRevealSellerPhone(phone);
      if (!_isSellerPhoneRevealed) return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final msg = Uri.encodeComponent('Hello, I am interested in your harvest listing "$cropTitle" on AgroZemex.');
    final uri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      final webUri = Uri.parse('https://wa.me/$cleanPhone?text=$msg');
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('WhatsApp is not installed on this device')),
          );
        }
      }
    }
  }

  Future<void> _sendSms(String phone, String cropTitle) async {
    if (!_isSellerPhoneRevealed) {
      await _handleRevealSellerPhone(phone);
      if (!_isSellerPhoneRevealed) return;
    }
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final msg = Uri.encodeComponent('Hello, I am interested in your harvest listing "$cropTitle" on AgroZemex.');
    final uri = Uri.parse('sms:$cleanPhone?body=$msg');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open SMS for $phone')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPhoneVerificationGuard();
    });
  }

  Future<void> _checkPhoneVerificationGuard() async {
    final auth = context.read<AuthService>();
    final user = auth.user;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to view crop details.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final userService = context.read<UserFirestoreService>();
    final verified = await userService.isPhoneAndTermsVerified(user).timeout(
      const Duration(seconds: 3),
      onTimeout: () => true,
    );
    if (!verified && mounted) {
      final success = await PhoneBindingDialog.show(context);
      if (!success && mounted) {
        Navigator.pop(context);
        return;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showShareModal(BuildContext context) {
    final item = widget.item;
    final shareText = '''
🌾 AgroZemex Harvest Listing: ${item.title}
💰 Price: ₹${item.price.toStringAsFixed(0)} per ${item.unit}
📦 Quantity Available: ${item.quantity.toStringAsFixed(0)} ${item.unit}
📍 Location: ${item.village}
🌱 Crop Category: ${item.cropType}

Check out this harvest on AgroZemex App!
''';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Share Harvest Listing',
              style: AgroZemexTokens.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF25D366),
                child: Icon(Icons.chat, color: Colors.white, size: 20),
              ),
              title: const Text('Share on WhatsApp'),
              subtitle: const Text('Send harvest details directly to WhatsApp chats'),
              onTap: () async {
                Navigator.pop(ctx);
                final encoded = Uri.encodeComponent(shareText);
                final whatsappUrl = Uri.parse('whatsapp://send?text=$encoded');
                final webWhatsappUrl = Uri.parse('https://wa.me/?text=$encoded');

                if (await canLaunchUrl(whatsappUrl)) {
                  await launchUrl(whatsappUrl);
                } else if (await canLaunchUrl(webWhatsappUrl)) {
                  await launchUrl(webWhatsappUrl, mode: LaunchMode.externalApplication);
                } else {
                  await Share.share(shareText, subject: item.title);
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AgroZemexTokens.primary,
                child: Icon(Icons.share, color: Colors.white, size: 20),
              ),
              title: const Text('System Share Sheet'),
              subtitle: const Text('Share via Telegram, SMS, Mail, or other apps'),
              onTap: () async {
                Navigator.pop(ctx);
                await Share.share(shareText, subject: item.title);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(Icons.copy, color: Colors.white, size: 20),
              ),
              title: const Text('Copy Share Details'),
              subtitle: const Text('Copy harvest summary to clipboard'),
              onTap: () {
                Navigator.pop(ctx);
                Clipboard.setData(ClipboardData(text: shareText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Harvest details copied to clipboard!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }



  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final List<String> photos = item.photoPaths.isNotEmpty
        ? item.photoPaths
        : [
            'https://lh3.googleusercontent.com/aida-public/AB6AXuC9ysRBNHDkXW-bCVfBgTfulMUKqfAooWctXMC59ZSyvtDGr3UM3KYYsmmbZE3k_Swnibmh1DPIwJyqzrzBJarw5F99o6p_H819l61l_ur_j3ktXJXpGrX46gSgkdXAXOfZTWbnqklJ5j-zExEjh3polPKVFsOBNTcKpNgvfQEXCcxTtj4bWWozSKWDeNcL6yFmcxRhmWMqf_dFJAnQ__dvYeuamP6J6GStfqoTtJayi4VirLH02_TEZA',
          ];

    return Scaffold(
      backgroundColor: AgroZemexTokens.surface,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Hero Photo Carousel Header
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 380,
                  child: Stack(
                    children: [
                      PageView.builder(
                        controller: _pageController,
                        onPageChanged: (idx) {
                          setState(() => _currentImageIndex = idx);
                        },
                        itemCount: photos.length,
                        itemBuilder: (context, index) {
                          return UniversalImageWidget(
                            imagePath: photos[index],
                            fit: BoxFit.cover,
                          );
                        },
                      ),

                      // Gradient Overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.5),
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.4),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Floating Top Bar Buttons with SafeArea Notch Protection
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: SafeArea(
                          top: true,
                          bottom: false,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                CircleAvatar(
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.8),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: AgroZemexTokens.onSurface,
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ),
                                Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.8),
                                      child: IconButton(
                                        icon: const Icon(
                                          Icons.share,
                                          color: AgroZemexTokens.onSurface,
                                        ),
                                        onPressed: () => _showShareModal(context),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    CircleAvatar(
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.8),
                                      child: IconButton(
                                        icon: Icon(
                                          _isFavorite
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          color: _isFavorite
                                              ? Colors.red
                                              : AgroZemexTokens.onSurface,
                                        ),
                                        onPressed: () {
                                          setState(() => _isFavorite = !_isFavorite);
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),



                      // Image Counter Pill
                      Positioned(
                        bottom: 16,
                        right: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${_currentImageIndex + 1} / ${photos.length}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AgroZemexTokens.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Title & Price Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: AgroZemexTokens.displayLarge.copyWith(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.location_on,
                                      size: 16,
                                      color: AgroZemexTokens.secondary,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        item.village,
                                        style: AgroZemexTokens.bodyMedium.copyWith(
                                          color: AgroZemexTokens.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'LISTING PRICE',
                                style: AgroZemexTokens.labelCaps.copyWith(
                                  color: AgroZemexTokens.secondary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '₹ ${item.price.toStringAsFixed(0)}',
                                style: AgroZemexTokens.displayLarge.copyWith(
                                  fontSize: 26,
                                  color: AgroZemexTokens.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '/ ${item.unit}',
                                style: AgroZemexTokens.bodyMedium.copyWith(
                                  color: AgroZemexTokens.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // 4 Bento Stats Cards Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 2.1,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          _buildBentoStatCard(
                            'AVAILABLE',
                            '${item.quantity.toStringAsFixed(0)} ${item.unit}',
                            Icons.inventory_2_outlined,
                          ),
                          _buildBentoStatCard(
                            'VARIETY',
                            item.cropType,
                            Icons.grass_outlined,
                          ),
                          _buildBentoStatCard(
                            'FARMING TYPE',
                            item.isOrganic ? 'Organic Certified' : 'Conventional',
                            Icons.eco_outlined,
                          ),
                          _buildBentoStatCard(
                            'AVAILABILITY',
                            item.harvestStatus,
                            Icons.calendar_month_outlined,
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // Terroir & Harvest Story
                      Text(
                        'Terroir & Harvest Story',
                        style: AgroZemexTokens.headlineMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.description.isNotEmpty
                            ? item.description
                            : 'Cultivated in deep alluvial soil, this crop is nurtured under optimal rain-fed conditions. Harvested following a zero-residue protocol, sun-dried and machine-cleaned for superior quality.',
                        style: AgroZemexTokens.bodyLarge.copyWith(
                          color: AgroZemexTokens.onSurfaceVariant,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 24),

                      const SizedBox(height: 24),

                      // Verified Harvest Seller Card (Land Listing Style)
                      FutureBuilder<Map<String, dynamic>>(
                        future: context
                            .read<UserFirestoreService>()
                            .getUserData(item.sellerId),
                        builder: (context, snapshot) {
                          final sellerData = snapshot.data ?? {};
                          final sellerName = sellerData['name'] ??
                              sellerData['displayName'] ??
                              'AgroZemex Verified Seller';
                          final sellerPhone = sellerData['phone'] ?? '';
                          final displayedPhone = sellerPhone.isNotEmpty
                              ? (_isSellerPhoneRevealed
                                  ? sellerPhone
                                  : (sellerPhone.length > 5
                                      ? '${sellerPhone.substring(0, 5)} •••••'
                                      : '••••••••••'))
                              : '';

                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: AgroZemexTokens.radiusLargeCard,
                              boxShadow: AgroZemexTokens.softShadows,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AgroZemexTokens.primary,
                                      child: Icon(
                                        Icons.person,
                                        color: Colors.white,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'VERIFIED HARVEST SELLER',
                                            style: AgroZemexTokens.labelCaps.copyWith(
                                              color: AgroZemexTokens.primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            sellerName,
                                            style: AgroZemexTokens.bodyLarge.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          if (displayedPhone.isNotEmpty)
                                            Row(
                                              children: [
                                                Text(
                                                  displayedPhone,
                                                  style: AgroZemexTokens.bodyMedium.copyWith(
                                                    color: AgroZemexTokens.onSurfaceVariant,
                                                    fontSize: 13,
                                                    fontWeight: _isSellerPhoneRevealed
                                                        ? FontWeight.bold
                                                        : FontWeight.normal,
                                                  ),
                                                ),
                                                if (_isSellerPhoneRevealed) ...[
                                                  const SizedBox(width: 6),
                                                  InkWell(
                                                    onTap: () {
                                                      Clipboard.setData(
                                                          ClipboardData(text: sellerPhone));
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        const SnackBar(
                                                          content: Text(
                                                              'Seller phone number copied to clipboard!'),
                                                        ),
                                                      );
                                                    },
                                                    borderRadius: BorderRadius.circular(12),
                                                    child: const Padding(
                                                      padding: EdgeInsets.all(4),
                                                      child: Icon(
                                                        Icons.content_copy,
                                                        size: 14,
                                                        color: AgroZemexTokens.primary,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AgroZemexTokens.primary
                                            .withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.verified,
                                              size: 14,
                                              color: AgroZemexTokens.primary),
                                          SizedBox(width: 4),
                                          Text(
                                            'Verified',
                                            style: TextStyle(
                                              color: AgroZemexTokens.primary,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (sellerPhone.isNotEmpty &&
                                    !_isSellerPhoneRevealed) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 38,
                                    child: OutlinedButton.icon(
                                      onPressed: () =>
                                          _handleRevealSellerPhone(sellerPhone),
                                      icon: const Icon(Icons.lock_outline,
                                          size: 16, color: AgroZemexTokens.primary),
                                      label: Text(
                                        'Show Phone Number',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: AgroZemexTokens.primary,
                                        ),
                                      ),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(
                                            color: AgroZemexTokens.primary),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                                if (_isSellerPhoneRevealed) ...[
                                  const SizedBox(height: 16),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AgroZemexTokens.primary,
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () => _callPhone(sellerPhone.isNotEmpty ? sellerPhone : '9876543210'),
                                          icon: const Icon(Icons.phone, size: 16, color: Colors.white),
                                          label: const Text(
                                            'Call Seller',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF25D366),
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () => _openWhatsApp(sellerPhone.isNotEmpty ? sellerPhone : '9876543210', item.title),
                                          icon: const Icon(Icons.chat, size: 16, color: Colors.white),
                                          label: const Text(
                                            'WhatsApp',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                          side: const BorderSide(color: AgroZemexTokens.primary),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                        onPressed: () => _sendSms(sellerPhone.isNotEmpty ? sellerPhone : '9876543210', item.title),
                                        child: const Icon(Icons.message, size: 18, color: AgroZemexTokens.primary),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          );
                        },
                      ),

                      SizedBox(
                        height: MediaQuery.of(context).padding.bottom + 40,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBentoStatCard(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AgroZemexTokens.surfaceContainerLow,
        borderRadius: AgroZemexTokens.radiusEight,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: AgroZemexTokens.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: AgroZemexTokens.labelCaps.copyWith(fontSize: 9),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AgroZemexTokens.primary,
            ),
          ),
        ],
      ),
    );
  }
}

