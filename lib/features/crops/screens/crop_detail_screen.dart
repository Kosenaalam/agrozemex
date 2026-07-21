import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:agrozemex/core/theme/theme.dart';
import '../models/crop_card_model.dart';

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

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
                          return Image.network(
                            photos[index],
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Container(
                              color: AgroZemexTokens.surfaceContainerLow,
                              child: const Icon(
                                Icons.grass,
                                color: AgroZemexTokens.onSurfaceVariant,
                                size: 64,
                              ),
                            ),
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

                      // Floating Top Bar Buttons
                      Positioned(
                        top: MediaQuery.of(context).padding.top + 8,
                        left: 16,
                        right: 16,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.white.withValues(alpha: 0.8),
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
                                    onPressed: () {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text('Sharing harvest link'),
                                        ),
                                      );
                                    },
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

                      // Organic Certified Badge Overlay
                      Positioned(
                        bottom: 16,
                        left: 20,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AgroZemexTokens.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AgroZemexTokens.softShadows,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.verified,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'ORGANIC CERTIFIED',
                                style: AgroZemexTokens.labelCaps.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
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
                            'MOISTURE',
                            '11.4%',
                            Icons.water_drop_outlined,
                          ),
                          _buildBentoStatCard(
                            'HARVEST DATE',
                            'Fresh Yield',
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

                      // Soil Health Card Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AgroZemexTokens.surfaceContainerLow,
                          borderRadius: AgroZemexTokens.radiusEight,
                          border: Border.all(
                            color: AgroZemexTokens.onSurfaceVariant.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.analytics_outlined,
                              color: AgroZemexTokens.primary,
                              size: 32,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Certified Soil Health Card',
                                    style: AgroZemexTokens.bodyLarge.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Verified Potassium & Organic Carbon Content',
                                    style: AgroZemexTokens.labelCaps,
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: Text(
                                'VIEW PDF',
                                style: AgroZemexTokens.labelCaps.copyWith(
                                  color: AgroZemexTokens.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Verified Seller Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: AgroZemexTokens.radiusLargeCard,
                          boxShadow: AgroZemexTokens.softShadows,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'VERIFIED SELLER',
                              style: AgroZemexTokens.labelCaps.copyWith(
                                color: AgroZemexTokens.secondary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 26,
                                  backgroundColor: AgroZemexTokens.primary,
                                  child: Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Rajesh K. Parmar',
                                      style: AgroZemexTokens.bodyLarge.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.star,
                                          color: Colors.amber,
                                          size: 16,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '4.9 (124 reviews)',
                                          style: AgroZemexTokens.labelCaps,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Sticky Bottom Action Bar
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: AgroZemexTokens.softShadows,
                border: Border(
                  top: BorderSide(
                    color: AgroZemexTokens.onSurfaceVariant.withValues(alpha: 0.1),
                  ),
                ),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: const BorderSide(color: AgroZemexTokens.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: AgroZemexTokens.radiusEight,
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Connecting to Seller...'),
                            ),
                          );
                        },
                        child: Text(
                          'CONTACT SELLER',
                          style: AgroZemexTokens.labelCaps.copyWith(
                            color: AgroZemexTokens.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AgroZemexTokens.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: AgroZemexTokens.radiusEight,
                          ),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Order placed successfully!'),
                            ),
                          );
                        },
                        child: Text(
                          'PLACE ORDER / OFFER',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

/*
================================================================================
PREVIOUS CROP DETAIL SCREEN CODE (PRESERVED IN COMMENTED FORM AS REQUESTED)
================================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/crop_card_model.dart';

class _OldCropDetailScreen extends StatelessWidget {
  final CropCardModel item;

  const _OldCropDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(item.title),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.photoPaths.isNotEmpty)
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: item.photoPaths.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          item.photoPaths[index],
                          width: 180,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
                        ),
                      ),
                    );
                  },
                ),
              ),
            const SizedBox(height: 16),
            Text(
              item.title,
              style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '₹ ${item.price.toStringAsFixed(0)} / ${item.unit}',
              style: GoogleFonts.poppins(fontSize: 20, color: const Color(0xFF2E7D32)),
            ),
            const SizedBox(height: 8),
            Text(
              'Quantity: ${item.quantity.toStringAsFixed(2)} ${item.unit}',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Type: ${item.cropType}',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Location: ${item.village}',
              style: GoogleFonts.poppins(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Text(
              item.description,
              style: GoogleFonts.poppins(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
================================================================================
*/
