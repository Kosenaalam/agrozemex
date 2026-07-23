import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/crops/models/crop_card_model.dart';
import 'package:agrozemex/shared/widget/universal_image_widget.dart';

class CropGridItem extends StatelessWidget {
  final CropCardModel item;
  final double? distance;
  final VoidCallback onTap;

  const CropGridItem({
    super.key,
    required this.item,
    required this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasImage = item.photoPaths.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
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
                height: 110,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImage
                        ? UniversalImageWidget(
                            imagePath: item.photoPaths.first,
                            fit: BoxFit.cover,
                          )
                        : Image.asset(
                            AppAssets.defaultLand,
                            fit: BoxFit.cover,
                          ),
                    if (distance != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${distance!.toStringAsFixed(1)} KM',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AgroZemexTokens.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹ ${item.price.toStringAsFixed(0)} / ${item.unit}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AgroZemexTokens.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AgroZemexTokens.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            item.village,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AgroZemexTokens.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.quantity.toStringAsFixed(0)} ${item.unit} available',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AgroZemexTokens.secondary,
                        fontWeight: FontWeight.w500,
                      ),
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
