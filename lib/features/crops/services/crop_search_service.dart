
class CropSearchService {
  static List<String> buildSearchTokens({
    required String title,
    required String description,
    required String cropType,
    required String village,
  }) {
    final combined = '$title $description $cropType $village'.toLowerCase().trim();
    final tokens = combined.split(' ').where((t) => t.length > 2).toSet().toList();

    final ngrams = <String>[];
    for (var token in tokens) {
      for (int i = 3; i <= token.length; i++) {
        ngrams.add(token.substring(0, i));
      }
    }

    return [...tokens, ...ngrams];
  }
}