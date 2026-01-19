class ListingFilterModel {
  final bool? roadAccess;
  final String? soilType;
  final String? waterSource;
  final double? minAreaSqM;
  final double? maxAreaSqM;

  const ListingFilterModel({
    this.roadAccess,
    this.soilType,
    this.waterSource,
    this.minAreaSqM,
    this.maxAreaSqM,
  });

  /// Default empty filter
  static const empty = ListingFilterModel();
}
