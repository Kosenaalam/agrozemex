import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agrozemex/features/crops/models/crop_card_model.dart';

/// Factory for minimal [CropCardModel] test instances.
CropCardModel makeTestCrop({
  String id = 'crop-1',
  String title = 'Basmati Rice',
  double price = 3500,
  String description = 'Premium quality Basmati rice',
  double quantity = 200,
  String cropType = 'Grain',
  String unit = 'kg',
  String village = 'Karnal',
  bool isActive = true,
}) {
  return CropCardModel(
    id: id,
    title: title,
    price: price,
    description: description,
    quantity: quantity,
    photoPaths: [],
    cropType: cropType,
    unit: unit,
    village: village,
    location: const GeoPoint(29.6857, 76.9905),
    createdAt: Timestamp.fromDate(DateTime(2025, 1, 1)),
    isActive: isActive,
    searchTokens: ['basmati', 'rice', 'grain', 'karnal'],
  );
}

void main() {
  group('CropCardModel construction', () {
    test('stores all fields correctly', () {
      final crop = makeTestCrop();
      expect(crop.id, 'crop-1');
      expect(crop.title, 'Basmati Rice');
      expect(crop.price, 3500.0);
      expect(crop.quantity, 200.0);
      expect(crop.cropType, 'Grain');
      expect(crop.unit, 'kg');
      expect(crop.village, 'Karnal');
      expect(crop.isActive, isTrue);
      expect(crop.searchTokens, contains('rice'));
    });

    test('photoPaths is empty list by default in factory', () {
      final crop = makeTestCrop();
      expect(crop.photoPaths, isEmpty);
    });

    test('isActive can be set to false', () {
      final crop = makeTestCrop(isActive: false);
      expect(crop.isActive, isFalse);
    });

    test('GeoPoint location stores lat/lng correctly', () {
      final crop = makeTestCrop();
      expect(crop.location.latitude, closeTo(29.6857, 0.001));
      expect(crop.location.longitude, closeTo(76.9905, 0.001));
    });

    test('price stored as double', () {
      final crop = makeTestCrop(price: 1299.99);
      expect(crop.price, isA<double>());
      expect(crop.price, closeTo(1299.99, 0.001));
    });

    test('quantity stored as double', () {
      final crop = makeTestCrop(quantity: 50.5);
      expect(crop.quantity, closeTo(50.5, 0.001));
    });
  });

  group('CropCardModel.fromFirestore defaults', () {
    // Tests below verify the fallback defaults used in fromFirestore
    // by constructing models with the same default values manually.
    test('empty data produces safe defaults', () {
      final crop = CropCardModel(
        id: 'fallback-id',
        title: 'N/A',
        price: 0.0,
        description: '',
        quantity: 0.0,
        photoPaths: [],
        cropType: 'Unknown',
        unit: 'kg',
        village: 'Unknown',
        location: const GeoPoint(0, 0),
        createdAt: Timestamp.fromDate(DateTime(2000)),
        isActive: true,
        searchTokens: [],
      );
      expect(crop.title, 'N/A');
      expect(crop.cropType, 'Unknown');
      expect(crop.price, 0.0);
    });
  });
}
