import 'dart:math' as math;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class BoundaryService {
  /// Calculates survey-grade land area in square meters using WGS-84 ellipsoidal
  /// authalic radius correction at centroid latitude.
  static double calculateAreaSqMeters(List<mapbox.Point> boundaryPoints) {
    if (boundaryPoints.length < 3) return 0.0;

    // Calculate centroid latitude in radians
    double sumLatRad = 0.0;
    for (final pt in boundaryPoints) {
      sumLatRad += pt.coordinates.lat * (math.pi / 180);
    }
    final double centroidLat = sumLatRad / boundaryPoints.length;

    // WGS-84 Ellipsoid constants
    const double a = 6378137.0; // Equatorial radius (meters)
    const double b = 6356752.3142; // Polar radius (meters)

    // Compute local WGS-84 authalic radius of curvature at centroid latitude
    final double cosLat = math.cos(centroidLat);
    final double sinLat = math.sin(centroidLat);
    final double num = (a * a * cosLat) * (a * a * cosLat) + (b * b * sinLat) * (b * b * sinLat);
    final double den = (a * cosLat) * (a * cosLat) + (b * sinLat) * (b * sinLat);
    final double effectiveRadius = math.sqrt(num / den);

    double area = 0.0;
    for (int i = 0; i < boundaryPoints.length; i++) {
      final mapbox.Position p1 = boundaryPoints[i].coordinates;
      final mapbox.Position p2 =
          boundaryPoints[(i + 1) % boundaryPoints.length].coordinates;

      final double lat1 = p1.lat * (math.pi / 180);
      final double lat2 = p2.lat * (math.pi / 180);
      final double lngDiff = (p2.lng - p1.lng) * (math.pi / 180);

      area += lngDiff * (2 + math.sin(lat1) + math.sin(lat2));
    }

    area = area * effectiveRadius * effectiveRadius / 2.0;
    return area.abs();
  }

  /// Checks if polygon boundary line segments cross/self-intersect.
  static bool hasSelfIntersection(List<mapbox.Point> boundaryPoints) {
    final n = boundaryPoints.length;
    if (n < 4) return false;

    for (int i = 0; i < n; i++) {
      final p1 = boundaryPoints[i].coordinates;
      final p2 = boundaryPoints[(i + 1) % n].coordinates;

      for (int j = i + 2; j < n; j++) {
        if (i == 0 && j == n - 1) continue; // Skip adjacent first and last edge

        final p3 = boundaryPoints[j].coordinates;
        final p4 = boundaryPoints[(j + 1) % n].coordinates;

        if (_segmentsIntersect(p1, p2, p3, p4)) {
          return true;
        }
      }
    }
    return false;
  }

  static bool _segmentsIntersect(
    mapbox.Position a,
    mapbox.Position b,
    mapbox.Position c,
    mapbox.Position d,
  ) {
    int ccw(mapbox.Position p1, mapbox.Position p2, mapbox.Position p3) {
      final val = (p2.lng - p1.lng) * (p3.lat - p1.lat) -
          (p2.lat - p1.lat) * (p3.lng - p1.lng);
      if (val.abs() < 1e-9) return 0;
      return val > 0 ? 1 : -1;
    }

    final ccw1 = ccw(a, b, c);
    final ccw2 = ccw(a, b, d);
    final ccw3 = ccw(c, d, a);
    final ccw4 = ccw(c, d, b);

    return (ccw1 != ccw2) && (ccw3 != ccw4);
  }
}
