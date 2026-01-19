import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;




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
  //it remove listing old land
 // final String village;
 
  
// 🔍 Searchable tokens prepared at write-time
  final List<String> searchTokens;
  // ADD THESE TWO FIELDS
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
  //   required this.village,
    // 🔍 
    required this.searchTokens,
    this.centerLat,
    this.centerLng,

  });
}
