import '../models/listing_card_model.dart';

class SearchRankService {
  int calculateScore({
    required ListingCardModel item,
    required String query,
  }) {
    if (query.isEmpty) return 0;

    final q = query.toLowerCase();

    int score = 0;

    if (item.title.toLowerCase().contains(q)) {
      score += 100;
    }

    if (item.description.toLowerCase().contains(q)) {
      score += 40;
    }

    if (q.contains('highway') && item.roadAccess == true) {
      score += 30;
    }

    if (q.contains('large') && item.areaInSqMeters > 20000) {
      score += 20;
    }

    return score;
  }
}
