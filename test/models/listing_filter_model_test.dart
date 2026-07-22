import 'package:flutter_test/flutter_test.dart';
import 'package:agrozemex/features/home/models/listing_filter_model.dart';

void main() {
  group('ListingFilterModel', () {
    test('ListingFilterModel.empty has all null fields', () {
      const filter = ListingFilterModel.empty;
      expect(filter.roadAccess, isNull);
      expect(filter.soilType, isNull);
      expect(filter.waterSource, isNull);
      expect(filter.minAreaSqM, isNull);
      expect(filter.maxAreaSqM, isNull);
      expect(filter.village, isNull);
    });

    test('two empty filters are equal', () {
      const a = ListingFilterModel.empty;
      const b = ListingFilterModel.empty;
      expect(a, equals(b));
    });

    test('filters with same values are equal', () {
      const a = ListingFilterModel(
        roadAccess: true,
        soilType: 'Black',
        minAreaSqM: 5000,
        maxAreaSqM: 20000,
        village: 'Nagpur',
      );
      const b = ListingFilterModel(
        roadAccess: true,
        soilType: 'Black',
        minAreaSqM: 5000,
        maxAreaSqM: 20000,
        village: 'Nagpur',
      );
      expect(a, equals(b));
    });

    test('filters with different values are not equal', () {
      const a = ListingFilterModel(roadAccess: true);
      const b = ListingFilterModel(roadAccess: false);
      expect(a, isNot(equals(b)));
    });

    test('filters with different soil types are not equal', () {
      const a = ListingFilterModel(soilType: 'Black');
      const b = ListingFilterModel(soilType: 'Red');
      expect(a, isNot(equals(b)));
    });

    test('hashCode is consistent for equal objects', () {
      const a = ListingFilterModel(roadAccess: true, village: 'Nagpur');
      const b = ListingFilterModel(roadAccess: true, village: 'Nagpur');
      expect(a.hashCode, equals(b.hashCode));
    });

    test('hashCode differs for unequal objects', () {
      const a = ListingFilterModel(soilType: 'Black');
      const b = ListingFilterModel(soilType: 'Clay');
      expect(a.hashCode, isNot(equals(b.hashCode)));
    });

    test('partial filter stores only specified fields', () {
      const filter = ListingFilterModel(soilType: 'Alluvial', maxAreaSqM: 10000);
      expect(filter.soilType, 'Alluvial');
      expect(filter.maxAreaSqM, 10000.0);
      expect(filter.roadAccess, isNull);
      expect(filter.village, isNull);
    });
  });
}
