class ListingFilterModel {
  final bool? roadAccess;
  final String? soilType;
  final String? waterSource;
  final double? minAreaSqM;
  final double? maxAreaSqM;
  final String? village;

  const ListingFilterModel({
    this.roadAccess,
    this.soilType,
    this.waterSource,
    this.minAreaSqM,
    this.maxAreaSqM,
    this.village,
  });

  static const empty = ListingFilterModel();
}
 // this is for query filtering in the search results, not for the listing form