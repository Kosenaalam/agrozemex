class SearchTokenService {
  static final Map<String, List<String>> synonyms = {
    'road': ['road', 'highway', 'street', 'pathway', 'lane'],
    'village': ['village', 'gaon', 'gram', 'pind'],
    'tehsil': ['tehsil', 'taluka', 'mandal', 'block'],
    'farm': ['farm', 'khet', 'land', 'plot', 'acreage'],
    'water': ['water', 'paani', 'irrigation', 'borewell'],
  };

  static String normalize(String input) {
    String normalized = input.toLowerCase().trim();
    normalized = normalized.replaceAll(RegExp(r'[^a-z0-9 ]'), '');
    normalized = normalized
        .replaceAll('st.', 'street')
        .replaceAll('hwy', 'highway');
    if (normalized.endsWith('pur') || normalized.endsWith('nagar')) {
      normalized = normalized
          .replaceAll('pur', 'pur')
          .replaceAll('nagar', 'nagar');
    }
    return normalized;
  }

  static List<String> expandWithSynonyms(String token) {
    for (final entry in synonyms.entries) {
      if (entry.value.contains(token)) {
        return entry.value;
      }
    }
    return [token];
  }

  static List<String> generateNGrams(String term, {int minLength = 3}) {
    final normalized = normalize(term);
    if (normalized.length < minLength) return [normalized];
    final ngrams = <String>[];
    for (int i = minLength; i <= normalized.length; i++) {
      ngrams.add(normalized.substring(0, i));
    }
    return ngrams;
  }
}
