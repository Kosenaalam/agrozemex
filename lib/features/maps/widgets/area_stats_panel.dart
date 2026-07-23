import 'package:flutter/material.dart';
import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/shared/services/land_area_unit_converter.dart';

class AreaStatsPanel extends StatelessWidget {
  final int pointsCount;
  final double areaInSqMeters;
  final bool hasSelfIntersection;

  const AreaStatsPanel({
    super.key,
    required this.pointsCount,
    required this.areaInSqMeters,
    this.hasSelfIntersection = false,
  });

  @override
  Widget build(BuildContext context) {
    final acres = LandAreaUnitConverter.toAcres(areaInSqMeters);
    final bigha = LandAreaUnitConverter.toBigha(areaInSqMeters);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Center drag bar handle
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AgroZemexTokens.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    'ARABLE',
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
                    'VERIFIED GIS',
                    style: AgroZemexTokens.labelCaps.copyWith(
                      color: AgroZemexTokens.secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Icon(
              Icons.verified,
              color: AgroZemexTokens.primary,
              size: 20,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          pointsCount > 0
              ? 'Land Boundary ($pointsCount Corner Points)'
              : 'Mark Land Boundary',
          style: AgroZemexTokens.headlineMedium.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          pointsCount > 0
              ? 'Tap corners or drag pins to adjust boundary'
              : 'Tap on map corners to mark land boundaries (min 3 points)',
          style: AgroZemexTokens.bodyLarge.copyWith(
            fontSize: 13,
            color: AgroZemexTokens.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),

        // Area / Bigha / Status Stats Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                Text(
                  'ACRES',
                  style: AgroZemexTokens.labelCaps.copyWith(
                    fontSize: 10,
                    color: AgroZemexTokens.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  areaInSqMeters > 0
                      ? '${acres.toStringAsFixed(2)} Acres'
                      : '0.00 Acres',
                  style: AgroZemexTokens.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AgroZemexTokens.primary,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  'BIGHA',
                  style: AgroZemexTokens.labelCaps.copyWith(
                    fontSize: 10,
                    color: AgroZemexTokens.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  areaInSqMeters > 0
                      ? '${bigha.toStringAsFixed(1)} Bigha'
                      : '0.0 Bigha',
                  style: AgroZemexTokens.bodyLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                Text(
                  'STATUS',
                  style: AgroZemexTokens.labelCaps.copyWith(
                    fontSize: 10,
                    color: AgroZemexTokens.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  hasSelfIntersection
                      ? '⚠️ Crossing Lines'
                      : (pointsCount >= 3 ? 'Ready to Save' : 'Need ${3 - pointsCount} more'),
                  style: AgroZemexTokens.bodyLarge.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: hasSelfIntersection
                        ? AgroZemexTokens.error
                        : (pointsCount >= 3
                            ? AgroZemexTokens.primary
                            : AgroZemexTokens.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
