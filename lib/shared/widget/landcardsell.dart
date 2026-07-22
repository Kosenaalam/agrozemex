import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/home/screens/listing_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../features/home/models/listing_card_model.dart';

class LandCard extends StatelessWidget {
  final ListingCardModel item;

  const LandCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final double? distanceKm =
        item.distanceMeters != null ? item.distanceMeters! / 1000 : null;

    final bool hasImage = item.photoPaths.isNotEmpty;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListingDetailScreen(
              listingId: item.id,
              title: item.title,
              price: item.price,
              description: item.description,
              areaInSqMeters: item.areaInSqMeters,
              boundaryPoints: item.boundaryPoints,
              photoPaths: item.photoPaths,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AgroZemexTokens.radiusLargeCard,
          boxShadow: AgroZemexTokens.softShadows,
        ),
        child: ClipRRect(
          borderRadius: AgroZemexTokens.radiusLargeCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Thumbnail Container
              SizedBox(
                height: 120,
                width: double.infinity,
                child: hasImage
                    ? Image.network(
                        item.photoPaths.first,
                        fit: BoxFit.cover,
                        cacheHeight: 250,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AgroZemexTokens.surfaceContainerLow,
                          child: const Icon(
                            Icons.landscape,
                            color: AgroZemexTokens.onSurfaceVariant,
                            size: 32,
                          ),
                        ),
                      )
                    : Image.asset(
                        AppAssets.defaultLand,
                        fit: BoxFit.cover,
                      ),
              ),

              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AgroZemexTokens.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₹ ${item.price.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AgroZemexTokens.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (distanceKm != null) ...[
                          Text(
                            '${distanceKm.toStringAsFixed(1)} km away • ',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AgroZemexTokens.onSurfaceVariant,
                            ),
                          ),
                        ],
                        Text(
                          '${item.areaInSqMeters.toStringAsFixed(0)} sq m',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AgroZemexTokens.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/*
================================================================================
PREVIOUS LAND CARD CODE (PRESERVED IN COMMENTED FORM AS REQUESTED)
================================================================================

import 'package:agrozemex/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../../features/home/models/listing_card_model.dart';

class _OldLandCard extends StatelessWidget {
  final ListingCardModel item;

  const _OldLandCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final double? distanceKm =
        item.distanceMeters != null ? item.distanceMeters! / 1000 : null;

    return InkWell(
      onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const HomeScreen(),
            ),
          );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 90,
                child: mapbox.MapWidget(
                  styleUri: mapbox.MapboxStyles.SATELLITE_STREETS,
                  cameraOptions: mapbox.CameraOptions(
                    center: item.boundaryPoints.first,
                    zoom: 15,
                  ),
                ),
              ),
              const SizedBox(height: 7),
              Text(
                item.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '₹ ${item.price.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (distanceKm != null)
                Text('${distanceKm.toStringAsFixed(1)} km away'),
              Text('${item.areaInSqMeters.toStringAsFixed(2)} sq m'),
            ],
          ),
        ),
      ),
    );
  }
}
================================================================================
*/