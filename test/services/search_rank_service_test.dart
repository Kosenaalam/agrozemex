import 'package:agrozemex/features/home/models/listing_card_model.dart';
import 'package:agrozemex/features/home/services/search_rank_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// A minimal [ListingCardModel] factory for use in unit tests.
/// Uses empty boundary points — no Mapbox rendering is invoked.
ListingCardModel _makeListing({
  String id = 'test-id',
  String title = 'Test Listing',
  String description = 'A test land listing',
  double area = 10000,
  bool? roadAccess,
}) {
  return ListingCardModel(
    id: id,
    title: title,
    description: description,
    price: 500000,
    areaInSqMeters: area,
    photoPaths: [],
    boundaryPoints: [],
    searchTokens: [],
    roadAccess: roadAccess,
  );
}

void main() {
  late SearchRankService sut;

  setUp(() {
    sut = SearchRankService();
  });

  group('SearchRankService.calculateScore', () {
    test('returns 0 when query is empty', () {
      final listing = _makeListing();
      expect(sut.calculateScore(item: listing, query: ''), 0);
    });

    test('scores +100 when title contains query (case-insensitive)', () {
      final listing = _makeListing(title: 'Green Valley Land');
      expect(sut.calculateScore(item: listing, query: 'green'), 100);
    });

    test('scores +40 when description contains query', () {
      final listing = _makeListing(description: 'Fertile black soil plot near river');
      expect(sut.calculateScore(item: listing, query: 'fertile'), 40);
    });

    test('scores +140 when both title and description contain query', () {
      final listing = _makeListing(
        title: 'Sunny Farm',
        description: 'sunny weather and good drainage',
      );
      expect(sut.calculateScore(item: listing, query: 'sunny'), 140);
    });

    test('scores +30 when query contains highway and roadAccess is true', () {
      final listing = _makeListing(roadAccess: true);
      expect(sut.calculateScore(item: listing, query: 'highway access'), 30);
    });

    test('does not score highway bonus when roadAccess is false', () {
      final listing = _makeListing(roadAccess: false);
      expect(sut.calculateScore(item: listing, query: 'highway access'), 0);
    });

    test('scores +20 when query contains large and area > 20000 sqm', () {
      final listing = _makeListing(area: 25000);
      expect(sut.calculateScore(item: listing, query: 'large farm'), 20);
    });

    test('no large bonus when area is exactly 20000 sqm', () {
      final listing = _makeListing(area: 20000);
      expect(sut.calculateScore(item: listing, query: 'large farm'), 0);
    });

    test('accumulates all bonuses correctly', () {
      final listing = _makeListing(
        title: 'Large Highway Farm',
        description: 'near highway with large land',
        area: 30000,
        roadAccess: true,
      );
    // title match = 100, highway bonus = 30, large bonus = 20 → 150
    // Note: 'large highway' is NOT a substring of the description 'near highway with large land',
    // so the description +40 bonus does NOT apply.
      expect(sut.calculateScore(item: listing, query: 'large highway'), 150);
    });
  });
}
