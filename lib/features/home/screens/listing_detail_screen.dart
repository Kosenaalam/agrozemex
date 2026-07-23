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

class ListingDetailScreen extends StatefulWidget {
  final String listingId;
  final String title;
  final double price;
  final String description;
  final double areaInSqMeters;
  final List<mapbox.Point> boundaryPoints;
  final List<String> photoPaths;

  const ListingDetailScreen({
    super.key,
    required this.listingId,
    required this.title,
    required this.price,
    required this.description,
    required this.areaInSqMeters,
    required this.boundaryPoints,
    required this.photoPaths,
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

  @override
  void initState() {
    super.initState();
    _loadBlueCircleIcon();
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

  @override
  Widget build(BuildContext context) {
    final wishlistService = context.read<WishlistService>();
    final auth = context.read<AuthService>();
    final uid = auth.user?.uid ?? '';

    final double areaHa = widget.areaInSqMeters / 10000.0;
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
                  onPressed: () {},
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
              // Hero Gallery
              Padding(
                padding: const EdgeInsets.all(AgroZemexTokens.marginMobile),
                child: Stack(
                  children: [
                    _buildPhoto(mainPhoto, height: 280),
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
                              '1 / ${math.max(1, widget.photoPaths.length)}',
                              style: AgroZemexTokens.labelCaps.copyWith(
                                color: AgroZemexTokens.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Title & Overview Section
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AgroZemexTokens.marginMobile,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
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
                          child: Text(
                            'ARABLE LAND',
                            style: AgroZemexTokens.labelCaps.copyWith(
                              color: AgroZemexTokens.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                            'IRRIGATED',
                            style: AgroZemexTokens.labelCaps.copyWith(
                              color: AgroZemexTokens.secondary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                          : 'Located in the fertile crescent of the central valley, this exceptional parcel offers immediate operational readiness with advanced water management infrastructure and Class 1 soil profiles.',
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
                            label: 'TOTAL AREA',
                            value: areaHa > 0
                                ? '${areaHa.toStringAsFixed(1)} Ha'
                                : '${widget.areaInSqMeters.toStringAsFixed(0)} sq m',
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: AgroZemexTokens.surfaceContainerLow,
                          ),
                          _buildSpecItem(
                            icon: Icons.landscape,
                            label: 'TOPOGRAPHY',
                            value: 'Flat (<2% slope)',
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: AgroZemexTokens.surfaceContainerLow,
                          ),
                          _buildSpecItem(
                            icon: Icons.water_drop,
                            label: 'WATER RIGHTS',
                            value: 'Secured',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Technical Specifications Bento Grid
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AgroZemexTokens.marginMobile,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                        // Soil Profile Card
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
                                      'Soil Profile',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                _buildSpecRow('Type', 'Chernozem'),
                                _buildSpecRow('Organic', '4.5% High'),
                                _buildSpecRow('pH Level', '6.8 Neutral'),
                                _buildSpecRow('Drainage', 'Excellent'),
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
                                _buildSpecRow('Irrigation', 'Center Pivot'),
                                _buildSpecRow('Water', 'Deep Wells'),
                                _buildSpecRow('Access', 'Highway'),
                                _buildSpecRow('Power', '3-Phase'),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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

      // Sticky Bottom Action Bar
      bottomNavigationBar: Container(
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
                ElevatedButton.icon(
                  onPressed: () {},
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AgroZemexTokens.radiusEight,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AgroZemexTokens.onSurfaceVariant,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AgroZemexTokens.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

