import 'dart:math' as math;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class BoundaryService {
  static double calculateAreaSqMeters(List<mapbox.Point> boundaryPoints) {
    if (boundaryPoints.length < 3) return 0.0;

    const double earthRadius = 6378137.0;
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

    area = area * earthRadius * earthRadius / 2.0;
    return area.abs();
  }
}
