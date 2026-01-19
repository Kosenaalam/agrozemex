import '../models/listing_card_model.dart';

class SearchRankService {
  /// Calculate relevance score for a listing
  /// Higher score = higher priority in results
  int calculateScore({
    required ListingCardModel item,
    required String query,
  }) {
    if (query.isEmpty) return 0;

    final q = query.toLowerCase();

    int score = 0;

    // Title match (strongest)
    if (item.title.toLowerCase().contains(q)) {
      score += 100;
    }

    // Description match
    if (item.description.toLowerCase().contains(q)) {
      score += 40;
    }

    // Road access relevance
    if (q.contains('highway') && item.roadAccess == true) {
      score += 30;
    }

    // Area-based relevance (keywords)
    if (q.contains('large') && item.areaInSqMeters > 20000) {
      score += 20;
    }

    return score;
  }
}
