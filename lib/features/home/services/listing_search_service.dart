import '../models/listing_card_model.dart';
import '../models/listing_search_filter.dart';

class ListingSearchService {
  List<ListingCardModel> applySearch({
    required List<ListingCardModel> source,
    required ListingSearchFilter filter,
  }) {
    if (filter.isEmpty) return source;

    final q = filter.normalized;

    return source.where((item) {
      final title = item.title.toLowerCase();
      final desc = item.description.toLowerCase();

      if (q.contains('highway')) {
        return desc.contains('highway') ||
               desc.contains('road') ||
               desc.contains('nh');
      }

      return title.contains(q) || desc.contains(q);
    }).toList();
  }
}
