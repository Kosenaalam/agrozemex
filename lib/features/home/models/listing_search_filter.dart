class ListingSearchFilter {
  final String query;

  const ListingSearchFilter(this.query);

  bool get isEmpty => query.trim().isEmpty;

  String get normalized => query.toLowerCase().trim();
}
