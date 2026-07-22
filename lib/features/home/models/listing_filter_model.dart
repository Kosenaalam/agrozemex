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

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ListingFilterModel &&
          roadAccess == other.roadAccess &&
          soilType == other.soilType &&
          waterSource == other.waterSource &&
          minAreaSqM == other.minAreaSqM &&
          maxAreaSqM == other.maxAreaSqM &&
          village == other.village);

  @override
  int get hashCode => Object.hash(
        roadAccess,
        soilType,
        waterSource,
        minAreaSqM,
        maxAreaSqM,
        village,
      );
}
// this is for query filtering in the search results, not for the listing form