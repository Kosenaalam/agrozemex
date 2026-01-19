import 'dart:math' as math;
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;


// Calculate distance (in meters / km) between the buyer and a land polygon.

class DistanceService {
  static const double _earthRadius = 6371000; // meters

  /// Calculate distance (meters) between user and land polygon
  double distanceToPolygon({
    required double userLat,
    required double userLng,
    required List<mapbox.Point> boundaryPoints,
  }) {
    if (boundaryPoints.isEmpty) return double.infinity;

    final centroid = _calculateCentroid(boundaryPoints);
    return _haversineDistance(
      userLat,
      userLng,
      centroid.lat.toDouble(),
      centroid.lng.toDouble(),
    );
  }

  /// Calculate centroid of polygon
  mapbox.Position _calculateCentroid(List<mapbox.Point> points) {
    double latSum = 0;
    double lngSum = 0;

    for (final p in points) {
      latSum += p.coordinates.lat;
      lngSum += p.coordinates.lng;
    }

    return mapbox.Position(
      lngSum / points.length,
      latSum / points.length,
    );
  }

  /// Haversine distance (meters)
  double _haversineDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final dLat = _degToRad(lat2 - lat1);
    final dLng = _degToRad(lng2 - lng1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degToRad(lat1)) *
            math.cos(_degToRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return _earthRadius * c;
  }

  double _degToRad(double deg) => deg * (math.pi / 180);
}
