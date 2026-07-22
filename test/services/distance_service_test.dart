import 'package:flutter_test/flutter_test.dart';
import 'package:agrozemex/shared/services/distance_service.dart';

void main() {
  late DistanceService sut;

  setUp(() {
    sut = DistanceService();
  });

  group('DistanceService.distanceBetweenPoints', () {
    test('returns 0 for identical coordinates', () {
      final d = sut.distanceBetweenPoints(12.9716, 77.5946, 12.9716, 77.5946);
      expect(d, closeTo(0.0, 0.001));
    });

    test('Bangalore to Mumbai is approximately 843 km', () {
      // Bangalore: 12.9716, 77.5946  |  Mumbai: 19.0760, 72.8777
      final d = sut.distanceBetweenPoints(12.9716, 77.5946, 19.0760, 72.8777);
      // Allow ±10 km tolerance for haversine approximation
      expect(d / 1000, closeTo(843, 10));
    });

    test('distance is symmetric (A→B == B→A)', () {
      final d1 = sut.distanceBetweenPoints(12.9716, 77.5946, 28.6139, 77.2090);
      final d2 = sut.distanceBetweenPoints(28.6139, 77.2090, 12.9716, 77.5946);
      expect(d1, closeTo(d2, 0.001));
    });

    test('distance increases with greater separation', () {
      final short = sut.distanceBetweenPoints(0.0, 0.0, 0.0, 1.0);
      final longer = sut.distanceBetweenPoints(0.0, 0.0, 0.0, 10.0);
      expect(longer, greaterThan(short));
    });

    test('Earth circumference sanity check: 180° apart is ~20,015 km', () {
      // Opposite poles
      final d = sut.distanceBetweenPoints(0.0, 0.0, 0.0, 180.0);
      expect(d / 1000, closeTo(20015, 50));
    });
  });

  group('DistanceService.distanceToPolygon', () {
    test('returns infinity for empty boundary points', () {
      final d = sut.distanceToPolygon(
        userLat: 12.9716,
        userLng: 77.5946,
        boundaryPoints: [],
      );
      expect(d, equals(double.infinity));
    });
  });
}
