import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/maps/screens/view_listing_map_screen.dart';
import 'package:agrozemex/shared/services/wishlist_service.dart';
import 'package:provider/provider.dart';
import '../../auth/services/auth_service.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agrozemex/features/auth/screens/login_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:agrozemex/shared/services/phone_binding_dialog.dart';
import 'package:agrozemex/shared/services/user_firestore_service.dart';
import 'package:agrozemex/shared/services/visit_booking_service.dart';
import 'package:agrozemex/shared/widget/book_visit_sheet.dart';
import 'package:agrozemex/shared/widget/seller_contact_disclaimer_dialog.dart';

class ListingDetailScreen extends StatefulWidget {
  final String listingId;
  final String title;
  final double price;
  final String description;
  final double areaInSqMeters;
  final List<mapbox.Point> boundaryPoints;
  final List<String> photoPaths;
  final String? sellerId;

  const ListingDetailScreen({
    super.key,
    required this.listingId,
    required this.title,
    required this.price,
    required this.description,
    required this.areaInSqMeters,
    required this.boundaryPoints,
    required this.photoPaths,
    this.sellerId,
  });

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  mapbox.MapboxMap? _mapController;
  mapbox.PointAnnotationManager? _pointManager;
  mapbox.PolygonAnnotationManager? _polygonManager;
  mapbox.PolylineAnnotationManager? _outlineManager;

  Uint8List? _blueCircleIcon;
  bool _isSellerPhoneRevealed = false;
  final PageController _photoPageController = PageController();
  int _currentPhotoIndex = 0;

  Future<void> _handleRevealSellerPhone(String rawPhone) async {
    if (_isSellerPhoneRevealed) return;

    final auth = context.read<AuthService>();
    final user = auth.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to view seller contact details.')),
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
        const SnackBar(content: Text('Seller contact unmasked. Strictly use for land purchase inquiries.')),
      );
    }
  }

  Future<Map<String, dynamic>> _fetchListingData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.listingId)
          .get();
      if (doc.exists) {
        return doc.data() ?? {};
      }
    } catch (_) {}
    return {};
  }

  Future<Map<String, dynamic>> _fetchSellerData() async {
    String targetSellerId = widget.sellerId ?? '';
    if (targetSellerId.isEmpty) {
      try {
        final listingDoc = await FirebaseFirestore.instance
            .collection('listings')
            .doc(widget.listingId)
            .get();
        if (listingDoc.exists) {
          targetSellerId = listingDoc.data()?['created_by'] as String? ?? '';
        }
      } catch (_) {}
    }
    if (targetSellerId.isNotEmpty && mounted) {
      final data = await context.read<UserFirestoreService>().getUserData(targetSellerId);
      final resultMap = Map<String, dynamic>.from(data);
      resultMap['seller_uid'] = targetSellerId;
      return resultMap;
    }
    return {};
  }

  @override
  void initState() {
    super.initState();
    _loadBlueCircleIcon();
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
        const SnackBar(content: Text('Please log in to view listing details.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final userService = context.read<UserFirestoreService>();
    final verified = await userService.isPhoneAndTermsVerified(user);
    if (!verified && mounted) {
      final success = await PhoneBindingDialog.show(context);
      if (!success && mounted) {
        Navigator.pop(context);
        return;
      }
    }
    if (mounted) {
      // Verified phone & terms consent successfully
    }
  }

  Future<void> _loadBlueCircleIcon() async {
    try {
      final data = await rootBundle.load('assets/icons/blue_circle.png');
      _blueCircleIcon = data.buffer.asUint8List();
    } catch (_) {}
  }

  void _onMapCreated(mapbox.MapboxMap controller) async {
    _mapController = controller;
    _pointManager =
        await controller.annotations.createPointAnnotationManager();
    _polygonManager =
        await controller.annotations.createPolygonAnnotationManager();
    _outlineManager =
        await controller.annotations.createPolylineAnnotationManager();

    await _drawBoundary();
  }

  Future<void> _drawBoundary() async {
    await _pointManager?.deleteAll();
    await _polygonManager?.deleteAll();
    await _outlineManager?.deleteAll();

    if (widget.boundaryPoints.length < 3) return;

    for (final point in widget.boundaryPoints) {
      await _pointManager?.create(
        mapbox.PointAnnotationOptions(
          geometry: point,
          image: _blueCircleIcon,
          iconSize: 0.5,
        ),
      );
    }

    final List<mapbox.Position> ring = [
      ...widget.boundaryPoints.map((p) => p.coordinates),
      widget.boundaryPoints.first.coordinates,
    ];

    await _polygonManager?.create(
      mapbox.PolygonAnnotationOptions(
        geometry: mapbox.Polygon(coordinates: [ring]),
        fillColor: AgroZemexTokens.primary.withValues(alpha: 0.28).toARGB32(),
      ),
    );

    await _outlineManager?.create(
      mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(coordinates: ring),
        lineColor: AgroZemexTokens.primary.toARGB32(),
        lineWidth: 3.5,
      ),
    );

    final lngs = widget.boundaryPoints.map((p) => p.coordinates.lng).toList();
    final lats = widget.boundaryPoints.map((p) => p.coordinates.lat).toList();

    final minLng = lngs.reduce(math.min);
    final maxLng = lngs.reduce(math.max);
    final minLat = lats.reduce(math.min);
    final maxLat = lats.reduce(math.max);

    final double centerLng = (minLng + maxLng) / 2;
    final double centerLat = (minLat + maxLat) / 2;

    final double maxDiff = math.max(
      (maxLng - minLng).abs().toDouble(),
      (maxLat - minLat).abs().toDouble(),
    );

    double zoom = 14;
    if (maxDiff < 0.001) {
      zoom = 18;
    } else if (maxDiff < 0.005) {
      zoom = 16;
    } else if (maxDiff < 0.02) {
      zoom = 14;
    } else {
      zoom = 12;
    }

    _mapController?.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(centerLng, centerLat),
        ),
        zoom: zoom,
      ),
      mapbox.MapAnimationOptions(duration: 1200),
    );
  }

  Future<void> _zoomIn() async {
    if (_mapController == null) return;
    final state = await _mapController!.getCameraState();
    _mapController!.flyTo(
      mapbox.CameraOptions(zoom: state.zoom + 1.5),
      mapbox.MapAnimationOptions(duration: 300),
    );
  }

  Future<void> _zoomOut() async {
    if (_mapController == null) return;
    final state = await _mapController!.getCameraState();
    _mapController!.flyTo(
      mapbox.CameraOptions(zoom: state.zoom - 1.5),
      mapbox.MapAnimationOptions(duration: 300),
    );
  }

  @override
  void dispose() {
    _photoPageController.dispose();
    _pointManager?.deleteAll();
    _polygonManager?.deleteAll();
    _outlineManager?.deleteAll();
    _pointManager = null;
    _polygonManager = null;
    _outlineManager = null;
    _mapController = null;
    super.dispose();
  }

  Widget _buildMapControlButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            color: AgroZemexTokens.primary,
            size: 20,
          ),
        ),
      ),
    );
  }

  void _openFullscreenGallery(List<String> photoList, int initialIndex) {
    showDialog(
      context: context,
      builder: (ctx) {
        final modalController = PageController(initialPage: initialIndex);
        return Dialog.fullscreen(
          backgroundColor: Colors.black,
          child: Stack(
            children: [
              PageView.builder(
                controller: modalController,
                itemCount: photoList.length,
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    panEnabled: true,
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: _buildPhoto(photoList[index], height: double.infinity),
                    ),
                  );
                },
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPhoto(String path, {double height = 180, double width = double.infinity}) {
    final bool isNetwork = path.startsWith('http');

    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: AgroZemexTokens.radiusEight,
        boxShadow: AgroZemexTokens.softShadows,
      ),
      child: ClipRRect(
        borderRadius: AgroZemexTokens.radiusEight,
        child: isNetwork
            ? Image.network(
                path,
                fit: BoxFit.cover,
                cacheWidth: (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).toInt(),
                loadingBuilder: (c, w, p) => p == null
                    ? w
                    : const Center(child: CircularProgressIndicator()),
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AgroZemexTokens.surfaceContainerLow,
                  child: const Icon(
                    Icons.landscape,
                    color: AgroZemexTokens.onSurfaceVariant,
                    size: 40,
                  ),
                ),
              )
            : Image.file(
                File(path),
                fit: BoxFit.cover,
              ),
      ),
    );
  }

  Future<void> _handleBookVisit() async {
    final auth = context.read<AuthService>();
    final user = auth.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to book a site visit.')),
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
    final userData = await userService.getUserData(user.uid);
    final buyerName = userData['name'] ?? userData['displayName'] ?? user.displayName ?? 'Buyer';
    final buyerPhone = userData['phone'] ?? user.phoneNumber ?? '';

    final sellerData = await _fetchSellerData();
    final sellerId = (widget.sellerId != null && widget.sellerId!.isNotEmpty)
        ? widget.sellerId!
        : (sellerData['seller_uid'] as String? ?? sellerData['uid'] as String? ?? sellerData['created_by'] as String? ?? '');

    if (!mounted) return;
    final booked = await BookVisitSheet.show(
      context: context,
      listingId: widget.listingId,
      listingTitle: widget.title,
      sellerId: sellerId,
      buyerId: user.uid,
      buyerName: buyerName,
      buyerPhone: buyerPhone,
    );

    if (booked && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.check_circle, color: AgroZemexTokens.primary, size: 28),
              SizedBox(width: 8),
              Text('Booking Confirmed!'),
            ],
          ),
          content: const Text(
            'Your site visit request has been sent to the land seller. The seller will contact you shortly to confirm.',
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AgroZemexTokens.primary),
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  void _showShareModal() {
    final acres = widget.areaInSqMeters / 4046.86;
    final bigha = widget.areaInSqMeters / 2529.3;

    final shareText = '''
🌱 *AgroZemex Farmland Listing* 🌱

📍 *Title*: ${widget.title}
💰 *Asking Price*: ₹ ${widget.price.toStringAsFixed(0)}
📐 *Land Area*: ${acres.toStringAsFixed(2)} Acres (${bigha.toStringAsFixed(1)} Bigha)
📍 *Location*: Verified Farmland

View complete boundary, soil & water details on AgroZemex Land Marketplace!
'''.trim();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share Land Listing',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AgroZemexTokens.primary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // WhatsApp Direct Share
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFF25D366),
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
              title: Text(
                'Share on WhatsApp',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Send formatted land details directly to contacts'),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final whatsappUrl = Uri.parse(
                    'https://wa.me/?text=${Uri.encodeComponent(shareText)}',
                  );
                  if (await canLaunchUrl(whatsappUrl)) {
                    await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
                  } else {
                    await Share.share(shareText, subject: widget.title);
                  }
                } catch (_) {
                  await Share.share(shareText, subject: widget.title);
                }
              },
            ),
            const Divider(height: 16),

            // Native System Share Sheet
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AgroZemexTokens.primary,
                child: Icon(Icons.share, color: Colors.white, size: 20),
              ),
              title: Text(
                'Share via Other Apps',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Telegram, SMS, Email, or social apps'),
              onTap: () {
                Navigator.pop(context);
                Share.share(shareText, subject: widget.title);
              },
            ),
            const Divider(height: 16),

            // Copy to Clipboard
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AgroZemexTokens.secondary,
                child: Icon(Icons.copy, color: Colors.white, size: 20),
              ),
              title: Text(
                'Copy Share Details',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Copy formatted land summary to clipboard'),
              onTap: () {
                Navigator.pop(context);
                Clipboard.setData(ClipboardData(text: shareText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Land listing details copied to clipboard!'),
                    backgroundColor: AgroZemexTokens.success,
                  ),
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
    final wishlistService = context.read<WishlistService>();
    final auth = context.read<AuthService>();
    final uid = auth.user?.uid ?? '';

    final String mainPhoto = widget.photoPaths.isNotEmpty
        ? widget.photoPaths.first
        : 'https://lh3.googleusercontent.com/aida-public/AB6AXuCtVGx0uzY3AWzBzlOke9itxD8Ek-CoIJw-GHHXASGWCmWM_kTFjV4yzOq0VAUZ7qqsGwv1SUmLPRbzoCY_hbSwZzWiSYKY10NLiBUW40Cz-dUbv4_wy1LjEDj4JCVLKTOKhNEablbWMlGJoKDJMKoS8yVUyrRe808wRkOArMSh9Aw6xXzd7qraZe7FYJEq3eeE3XmfJuKrnfl_3TSa7-JEj_7oo_NlxZGeMS0MlWy7r1mWUfHWDvsnRQ';

    return Scaffold(
      backgroundColor: AgroZemexTokens.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: BackdropFilter(
            filter: AgroZemexTokens.glassBlurFilter,
            child: AppBar(
              backgroundColor: AgroZemexTokens.surface.withValues(alpha: 0.85),
              elevation: 0,
              leading: IconButton(
                icon: const Icon(
                  Icons.arrow_back,
                  color: AgroZemexTokens.primary,
                ),
                onPressed: () => Navigator.pop(context),
              ),
              title: Text(
                'AgroZemex',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AgroZemexTokens.primary,
                  letterSpacing: -0.5,
                ),
              ),
              centerTitle: true,
              actions: [
                StreamBuilder<bool>(
                  stream: wishlistService.isWishlisted(widget.listingId, uid: uid),
                  builder: (context, snapshot) {
                    final isFav = snapshot.data ?? false;
                    return IconButton(
                      icon: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : AgroZemexTokens.primary,
                      ),
                      onPressed: () =>
                          wishlistService.toggleWishlist(widget.listingId, uid: uid),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(
                    Icons.share_outlined,
                    color: AgroZemexTokens.primary,
                  ),
                  onPressed: _showShareModal,
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Gallery PageView Carousel
              Padding(
                padding: const EdgeInsets.all(AgroZemexTokens.marginMobile),
                child: SizedBox(
                  height: 280,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: AgroZemexTokens.radiusLargeCard,
                        child: PageView.builder(
                          controller: _photoPageController,
                          itemCount: math.max(1, widget.photoPaths.length),
                          onPageChanged: (index) {
                            setState(() {
                              _currentPhotoIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            final String currentPath = widget.photoPaths.isNotEmpty
                                ? widget.photoPaths[index]
                                : mainPhoto;
                            return GestureDetector(
                              onTap: () => _openFullscreenGallery(
                                widget.photoPaths.isNotEmpty
                                    ? widget.photoPaths
                                    : [mainPhoto],
                                index,
                              ),
                              child: _buildPhoto(currentPath, height: 280),
                            );
                          },
                        ),
                      ),

                      // Photo Counter Badge
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AgroZemexTokens.softShadows,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.photo_library,
                                size: 14,
                                color: AgroZemexTokens.onSurface,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${_currentPhotoIndex + 1} / ${math.max(1, widget.photoPaths.length)}',
                                style: AgroZemexTokens.labelCaps.copyWith(
                                  color: AgroZemexTokens.onSurface,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Animated Dot Indicators
                      if (widget.photoPaths.length > 1)
                        Positioned(
                          bottom: 14,
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.photoPaths.length,
                              (idx) => AnimatedContainer(
                                duration: const Duration(milliseconds: 250),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: _currentPhotoIndex == idx ? 16 : 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _currentPhotoIndex == idx
                                      ? AgroZemexTokens.primary
                                      : Colors.white.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Title, Overview & Technical Specifications Section
              FutureBuilder<Map<String, dynamic>>(
                future: _fetchListingData(),
                builder: (context, snapshot) {
                  final listingData = snapshot.data ?? {};
                  final listerType = listingData['lister_type'] ?? 'Direct Owner';
                  final landCategory = listingData['land_category'] ?? 'Agricultural';
                  final ownershipStatus = listingData['ownership_status'] ?? 'Single Owner (Clear Title)';
                  final soilType = listingData['soil_type'] ?? 'Alluvial';
                  final waterSource = listingData['water_source'] ?? 'Tube Well';
                  final roadAccess = listingData['road_access'] as bool? ?? true;
                  final electricityAvailable = listingData['electricity_available'] as bool? ?? false;
                  final isFenced = listingData['is_fenced'] as bool? ?? false;

                  final acres = widget.areaInSqMeters / 4046.86;
                  final bigha = widget.areaInSqMeters / 2529.3;

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AgroZemexTokens.marginMobile,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AgroZemexTokens.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.person_pin, size: 14, color: AgroZemexTokens.primary),
                                  const SizedBox(width: 4),
                                  Text(
                                    listerType.toUpperCase(),
                                    style: AgroZemexTokens.labelCaps.copyWith(
                                      color: AgroZemexTokens.primary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AgroZemexTokens.secondary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                landCategory.toUpperCase(),
                                style: AgroZemexTokens.labelCaps.copyWith(
                                  color: AgroZemexTokens.secondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AgroZemexTokens.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'VERIFIED LISTING',
                                style: AgroZemexTokens.labelCaps.copyWith(
                                  color: AgroZemexTokens.onSurfaceVariant,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.title,
                          style: AgroZemexTokens.headlineMedium.copyWith(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.description.isNotEmpty
                              ? widget.description
                              : 'Located in the fertile crescent of the central valley, this exceptional parcel offers immediate operational readiness with advanced water management infrastructure and fertile soil profiles.',
                          style: AgroZemexTokens.bodyLarge.copyWith(
                            color: AgroZemexTokens.onSurfaceVariant,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Key Specs Bar
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: AgroZemexTokens.radiusLargeCard,
                            boxShadow: AgroZemexTokens.softShadows,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _buildSpecItem(
                                icon: Icons.straighten,
                                label: 'ACRES',
                                value: '${acres.toStringAsFixed(2)} Ac',
                              ),
                              Container(
                                width: 1,
                                height: 36,
                                color: AgroZemexTokens.surfaceContainerLow,
                              ),
                              _buildSpecItem(
                                icon: Icons.landscape,
                                label: 'BIGHA',
                                value: '${bigha.toStringAsFixed(1)} Bigha',
                              ),
                              Container(
                                width: 1,
                                height: 36,
                                color: AgroZemexTokens.surfaceContainerLow,
                              ),
                              _buildSpecItem(
                                icon: Icons.square_foot,
                                label: 'SQ METERS',
                                value: '${widget.areaInSqMeters.toStringAsFixed(0)} m²',
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Technical Specifications Bento Grid Header
                        Text(
                          'Technical Specifications',
                          style: AgroZemexTokens.headlineMedium.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Soil & Ownership Title Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: AgroZemexTokens.radiusLargeCard,
                                  boxShadow: AgroZemexTokens.softShadows,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.eco,
                                          color: AgroZemexTokens.primary,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Soil & Title',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    _buildSpecRow('Soil Type', soilType),
                                    _buildSpecRow('Category', landCategory),
                                    _buildSpecRow('Ownership', ownershipStatus),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Infrastructure Card
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: AgroZemexTokens.radiusLargeCard,
                                  boxShadow: AgroZemexTokens.softShadows,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.water,
                                          color: AgroZemexTokens.primary,
                                          size: 20,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          'Infrastructure',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 20),
                                    _buildSpecRow('Water', waterSource),
                                    _buildSpecRow('3-Phase Power', electricityAvailable ? 'Available' : 'No'),
                                    _buildSpecRow('Road Access', roadAccess ? 'Direct Road' : 'No Access'),
                                    _buildSpecRow('Fencing', isFenced ? 'Fenced Wall' : 'Open'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Verified Seller Information Card
                        FutureBuilder<Map<String, dynamic>>(
                          future: _fetchSellerData(),
                          builder: (context, snapshot) {
                            final sellerData = snapshot.data ?? {};
                            final sellerName = sellerData['name'] ?? sellerData['displayName'] ?? 'AgroZemex Verified Seller';
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
                                        child: Icon(Icons.person, color: Colors.white, size: 28),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'VERIFIED LAND SELLER (${listerType.toUpperCase()})',
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
                                                        Clipboard.setData(ClipboardData(text: sellerPhone));
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(
                                                            content: Text('Seller phone number copied to clipboard!'),
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
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AgroZemexTokens.primary.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.verified, size: 14, color: AgroZemexTokens.primary),
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
                                  if (sellerPhone.isNotEmpty && !_isSellerPhoneRevealed) ...[
                                    const SizedBox(height: 12),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 38,
                                      child: OutlinedButton.icon(
                                        onPressed: () => _handleRevealSellerPhone(sellerPhone),
                                        icon: const Icon(Icons.lock_outline, size: 16, color: AgroZemexTokens.primary),
                                        label: Text(
                                          'Show Phone Number',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: AgroZemexTokens.primary,
                                          ),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          side: const BorderSide(color: AgroZemexTokens.primary),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Map Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AgroZemexTokens.marginMobile,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Boundary & Location',
                      style: AgroZemexTokens.headlineMedium.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        borderRadius: AgroZemexTokens.radiusLargeCard,
                        boxShadow: AgroZemexTokens.softShadows,
                      ),
                      child: ClipRRect(
                        borderRadius: AgroZemexTokens.radiusLargeCard,
                        child: Stack(
                          children: [
                            mapbox.MapWidget(
                              styleUri: mapbox.MapboxStyles.SATELLITE_STREETS,
                              onMapCreated: _onMapCreated,
                              gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                                Factory<OneSequenceGestureRecognizer>(
                                  () => EagerGestureRecognizer(),
                                ),
                              },
                            ),
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Column(
                                children: [
                                  _buildMapControlButton(
                                    icon: Icons.add,
                                    tooltip: 'Zoom In',
                                    onTap: _zoomIn,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildMapControlButton(
                                    icon: Icons.remove,
                                    tooltip: 'Zoom Out',
                                    onTap: _zoomOut,
                                  ),
                                  const SizedBox(height: 8),
                                  _buildMapControlButton(
                                    icon: Icons.open_in_full,
                                    tooltip: 'Fullscreen Map',
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ViewListingMapScreen(
                                            listingId: widget.listingId,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // Sticky Bottom Action Bar with Real-Time Booking Status Lock
      bottomNavigationBar: StreamBuilder<QuerySnapshot>(
        stream: context.read<VisitBookingService>().streamUserBookingForListing(
              buyerId: uid,
              listingId: widget.listingId,
            ),
        builder: (context, snapshot) {
          String bookingStatus = '';
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            final docs = snapshot.data!.docs;
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>?;
              final st = data?['status'] as String? ?? '';
              if (st == 'pending' || st == 'confirmed') {
                bookingStatus = st;
                break;
              }
            }
          }

          Widget buttonWidget;
          if (bookingStatus == 'pending') {
            buttonWidget = ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your site visit request is pending seller confirmation.'),
                    backgroundColor: Colors.amber,
                  ),
                );
              },
              icon: const Icon(Icons.hourglass_top, size: 18, color: Colors.white),
              label: Text(
                'Visit Pending 🔒',
                style: AgroZemexTokens.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber.shade800,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AgroZemexTokens.radiusEight,
                ),
              ),
            );
          } else if (bookingStatus == 'confirmed') {
            buttonWidget = ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your site visit is confirmed! The seller will contact you.'),
                    backgroundColor: AgroZemexTokens.success,
                  ),
                );
              },
              icon: const Icon(Icons.check_circle_outline, size: 18, color: Colors.white),
              label: Text(
                'Visit Scheduled ✓',
                style: AgroZemexTokens.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AgroZemexTokens.success,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AgroZemexTokens.radiusEight,
                ),
              ),
            );
          } else {
            buttonWidget = ElevatedButton.icon(
              onPressed: _handleBookVisit,
              icon: const Icon(Icons.calendar_month, size: 18),
              label: Text(
                'Book Visit',
                style: AgroZemexTokens.bodyLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AgroZemexTokens.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: AgroZemexTokens.radiusEight,
                ),
              ),
            );
          }

          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: AgroZemexTokens.softShadows,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ASKING PRICE',
                          style: AgroZemexTokens.labelCaps.copyWith(
                            fontSize: 10,
                            color: AgroZemexTokens.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '₹ ${widget.price.toStringAsFixed(0)}',
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AgroZemexTokens.primary,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    buttonWidget,
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSpecItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, color: AgroZemexTokens.primary, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          style: AgroZemexTokens.labelCaps.copyWith(
            fontSize: 9,
            color: AgroZemexTokens.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AgroZemexTokens.bodyLarge.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSpecRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AgroZemexTokens.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AgroZemexTokens.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
