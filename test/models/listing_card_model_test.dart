import 'package:flutter_test/flutter_test.dart';
import 'package:agrozemex/features/home/models/listing_card_model.dart';

/// Factory helper — builds minimal ListingCardModel for unit tests.
ListingCardModel makeTestListing({
  String id = 'listing-1',
  String title = 'Green Valley Land',
  double price = 1500000,
  String description = 'Fertile farmland near highway',
  double area = 15000,
  bool? roadAccess = true,
  String? soilType = 'Black',
  String? waterSource = 'River',
  double? distanceMeters = 2500,
  double? centerLat = 12.9716,
  double? centerLng = 77.5946,
}) {
  return ListingCardModel(
    id: id,
    title: title,
    price: price,
    description: description,
    areaInSqMeters: area,
    photoPaths: [],
    boundaryPoints: [],
    searchTokens: ['green', 'valley', 'land', 'highway'],
    roadAccess: roadAccess,
    soilType: soilType,
    waterSource: waterSource,
    distanceMeters: distanceMeters,
    centerLat: centerLat,
    centerLng: centerLng,
  );
}

void main() {
  group('ListingCardModel construction', () {
    test('stores all required fields correctly', () {
      final model = makeTestListing();
      expect(model.id, 'listing-1');
      expect(model.title, 'Green Valley Land');
      expect(model.price, 1500000.0);
      expect(model.description, 'Fertile farmland near highway');
      expect(model.areaInSqMeters, 15000.0);
      expect(model.photoPaths, isEmpty);
      expect(model.boundaryPoints, isEmpty);
      expect(model.searchTokens, contains('highway'));
    });

    test('optional fields default to null when not provided', () {
      final model = ListingCardModel(
        id: 'min',
        title: 'Minimal',
        price: 100,
        description: 'desc',
        areaInSqMeters: 1000,
        photoPaths: [],
        boundaryPoints: [],
        searchTokens: [],
      );
      expect(model.roadAccess, isNull);
      expect(model.soilType, isNull);
      expect(model.waterSource, isNull);
      expect(model.distanceMeters, isNull);
      expect(model.centerLat, isNull);
      expect(model.centerLng, isNull);
    });

    test('photoPaths stores multiple entries', () {
      final model = makeTestListing().copyWithPhotos(
        ['gs://bucket/img1.jpg', 'gs://bucket/img2.jpg'],
      );
      expect(model.photoPaths.length, 2);
    });

    test('roadAccess stores false correctly', () {
      final model = makeTestListing(roadAccess: false);
      expect(model.roadAccess, isFalse);
    });

    test('area is stored as double', () {
      final model = makeTestListing(area: 20000.5);
      expect(model.areaInSqMeters, isA<double>());
      expect(model.areaInSqMeters, closeTo(20000.5, 0.001));
    });
  });
}

extension _TestHelpers on ListingCardModel {
  ListingCardModel copyWithPhotos(List<String> photos) => ListingCardModel(
        id: id,
        title: title,
        price: price,
        description: description,
        areaInSqMeters: areaInSqMeters,
        photoPaths: photos,
        boundaryPoints: boundaryPoints,
        searchTokens: searchTokens,
        roadAccess: roadAccess,
        soilType: soilType,
        waterSource: waterSource,
        distanceMeters: distanceMeters,
        centerLat: centerLat,
        centerLng: centerLng,
      );
}
