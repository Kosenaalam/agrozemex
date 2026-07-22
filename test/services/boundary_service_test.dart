import 'package:flutter_test/flutter_test.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:agrozemex/features/maps/services/boundary_service.dart';

/// Helper to build a Mapbox Point from lat/lng
mapbox.Point _pt(double lat, double lng) =>
    mapbox.Point(coordinates: mapbox.Position(lng, lat));

void main() {
  group('BoundaryService.calculateAreaSqMeters', () {
    test('returns 0 for fewer than 3 points', () {
      expect(BoundaryService.calculateAreaSqMeters([]), 0.0);
      expect(BoundaryService.calculateAreaSqMeters([_pt(0, 0)]), 0.0);
      expect(
          BoundaryService.calculateAreaSqMeters([_pt(0, 0), _pt(1, 0)]), 0.0);
    });

    test('1x1 degree square near equator is approximately 12,308 sq km', () {
      // A 1°x1° square at the equator ~ 111.32 km × 110.57 km ≈ 12,309 km²
      final square = [
        _pt(0.0, 0.0),
        _pt(0.0, 1.0),
        _pt(1.0, 1.0),
        _pt(1.0, 0.0),
      ];
      final area = BoundaryService.calculateAreaSqMeters(square);
      // Allow ±1% tolerance for spherical approximation
      expect(area / 1e6, closeTo(12308.0, 200.0));
    });

    test('returns positive area regardless of winding order', () {
      final cw = [_pt(0, 0), _pt(0, 1), _pt(1, 1), _pt(1, 0)];
      final ccw = [_pt(0, 0), _pt(1, 0), _pt(1, 1), _pt(0, 1)];
      final areaCw = BoundaryService.calculateAreaSqMeters(cw);
      final areaCcw = BoundaryService.calculateAreaSqMeters(ccw);
      expect(areaCw, greaterThan(0));
      expect(areaCcw, greaterThan(0));
    });

    test('triangle area is less than enclosing square area', () {
      final square = [_pt(0, 0), _pt(0, 1), _pt(1, 1), _pt(1, 0)];
      final triangle = [_pt(0, 0), _pt(0, 1), _pt(1, 0)];
      final squareArea = BoundaryService.calculateAreaSqMeters(square);
      final triangleArea = BoundaryService.calculateAreaSqMeters(triangle);
      expect(triangleArea, lessThan(squareArea));
    });

    test('doubling the polygon size roughly quadruples the area', () {
      final small = [
        _pt(0.0, 0.0), _pt(0.0, 0.5), _pt(0.5, 0.5), _pt(0.5, 0.0)
      ];
      final large = [
        _pt(0.0, 0.0), _pt(0.0, 1.0), _pt(1.0, 1.0), _pt(1.0, 0.0)
      ];
      final smallArea = BoundaryService.calculateAreaSqMeters(small);
      final largeArea = BoundaryService.calculateAreaSqMeters(large);
      // Large should be ~4x small (allow 5% tolerance for spherical distortion)
      expect(largeArea / smallArea, closeTo(4.0, 0.2));
    });
  });
}
