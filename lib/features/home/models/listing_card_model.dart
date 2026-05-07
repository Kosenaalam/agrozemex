import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;


// this is for search results and listing details screen, not the map clusters

class ListingCardModel {
  final String id;
  final String title;
  final double price;
  final String description;
  final double areaInSqMeters;
  final List<String> photoPaths;
  final List<mapbox.Point> boundaryPoints;
  final double? distanceMeters;
  final bool? roadAccess;
  final String? soilType;
  final String? waterSource;
 
  
  final List<String> searchTokens;
  final double? centerLat;
  final double? centerLng;
  

   


  ListingCardModel({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.areaInSqMeters,
    required this.photoPaths,
    required this.boundaryPoints,
    this.distanceMeters,
    this.roadAccess,
     this.soilType,
    this.waterSource,
    required this.searchTokens,
    this.centerLat,
    this.centerLng,

  });
}
