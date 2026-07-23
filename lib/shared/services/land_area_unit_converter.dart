/// Production-grade standardized Land Area Unit Converter for AgroZemex.
/// Converts square meters to Acres, Bigha, Guntha, and Hectares with survey-grade precision.
class LandAreaUnitConverter {
  /// 1 International Acre = 4046.8564224 sq. m
  static const double sqMetersPerAcre = 4046.8564224;

  /// 1 Standard Bigha = 2529.2893 sq. m
  static const double sqMetersPerBigha = 2529.2893;

  /// 1 Guntha = 101.17141 sq. m (1/40 Acre)
  static const double sqMetersPerGuntha = 101.17141;

  /// 1 Hectare = 10,000 sq. m
  static const double sqMetersPerHectare = 10000.0;

  /// Converts area in square meters to Acres.
  static double toAcres(double sqMeters) {
    if (sqMeters <= 0) return 0.0;
    return sqMeters / sqMetersPerAcre;
  }

  /// Converts area in square meters to Bigha.
  static double toBigha(double sqMeters) {
    if (sqMeters <= 0) return 0.0;
    return sqMeters / sqMetersPerBigha;
  }

  /// Converts area in square meters to Guntha.
  static double toGuntha(double sqMeters) {
    if (sqMeters <= 0) return 0.0;
    return sqMeters / sqMetersPerGuntha;
  }

  /// Converts area in square meters to Hectares.
  static double toHectares(double sqMeters) {
    if (sqMeters <= 0) return 0.0;
    return sqMeters / sqMetersPerHectare;
  }

  /// Formats square meters into a human-readable primary land area summary string.
  static String formatPrimaryArea(double sqMeters) {
    if (sqMeters <= 0) return '0.00 Acres';
    final acres = toAcres(sqMeters);
    final bigha = toBigha(sqMeters);
    return '${acres.toStringAsFixed(2)} Acres (${bigha.toStringAsFixed(1)} Bigha)';
  }

  /// Returns a map of formatted strings for all standard agricultural land units.
  static Map<String, String> formatAllUnits(double sqMeters) {
    return {
      'sq_m': '${sqMeters.toStringAsFixed(0)} sq m',
      'acres': '${toAcres(sqMeters).toStringAsFixed(2)} Acres',
      'bigha': '${toBigha(sqMeters).toStringAsFixed(1)} Bigha',
      'guntha': '${toGuntha(sqMeters).toStringAsFixed(1)} Guntha',
      'hectares': '${toHectares(sqMeters).toStringAsFixed(2)} ha',
    };
  }
}
