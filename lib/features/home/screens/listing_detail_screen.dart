import 'dart:io';  // For File to display photos
import 'dart:typed_data';  // For Uint8List to load icon
import 'dart:math' as math;  // For min/max in zoom calculation

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // For rootBundle to load assets
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class ListingDetailScreen extends StatefulWidget {
  final String title;  // Land title from listing
  final double price;  // Price in ₹
  final String description;  // Land description
  final double areaInSqMeters;  // Calculated area in sq m
  final List<mapbox.Point> boundaryPoints;  // Boundary coordinates from seller marking
  final List<String> photoPaths;  // Local paths to photos

  const ListingDetailScreen({
    super.key,
    required this.title,
    required this.price,
    required this.description,
    required this.areaInSqMeters,
    required this.boundaryPoints,
    required this.photoPaths,
  });

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  mapbox.MapboxMap? _mapController;  // Map controller
  mapbox.PointAnnotationManager? _pointManager;  // For blue circle markers
  mapbox.PolygonAnnotationManager? _polygonManager;  // For transparent fill
  mapbox.PolylineAnnotationManager? _outlineManager;  // For blue border

  Uint8List? _blueCircleIcon;  // Custom blue circle image bytes

  @override
  void initState() {
    super.initState();
    _loadBlueCircleIcon();  // Load custom icon for markers
  }

  // Load the blue circle PNG from assets
  Future<void> _loadBlueCircleIcon() async {
    try {
      final ByteData data = await rootBundle.load('assets/icons/blue_circle.png');
      setState(() {
        _blueCircleIcon = data.buffer.asUint8List();
      });
    } catch (e) {
      debugPrint('Error loading icon: $e');
    }
  }

  // Called when map is created — initialize managers and draw boundary
  void _onMapCreated(mapbox.MapboxMap controller) async {
    _mapController = controller;

    _pointManager = await controller.annotations!.createPointAnnotationManager();
    _polygonManager = await controller.annotations!.createPolygonAnnotationManager();
    _outlineManager = await controller.annotations!.createPolylineAnnotationManager();

    await _drawBoundary();  // Draw the polygon and markers
  }

  // Draw the boundary polygon, border, and markers
  Future<void> _drawBoundary() async {
    await _pointManager?.deleteAll();
    await _polygonManager?.deleteAll();
    await _outlineManager?.deleteAll();

    if (widget.boundaryPoints.length < 3) return;

    // Add blue circle markers at each corner
    for (final point in widget.boundaryPoints) {
      await _pointManager?.create(
        mapbox.PointAnnotationOptions(
          geometry: point,
          image: _blueCircleIcon,
          iconSize: 1.0,
        ),
      );
    }

    // Create closed ring for the polygon
    final List<mapbox.Position> ring = [
      ...widget.boundaryPoints.map((p) => p.coordinates),
      widget.boundaryPoints.first.coordinates,
    ];

    // Transparent blue fill for the area
    await _polygonManager?.create(
      mapbox.PolygonAnnotationOptions(
        geometry: mapbox.Polygon(coordinates: [ring]),
        fillColor: const Color(0xFF0D47A1).withOpacity(0.28).value,
      ),
    );

    // Visible blue border around the area
    await _outlineManager?.create(
      mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(coordinates: ring),
        lineColor: const Color(0xFF0D47A1).value,
        lineWidth: 3.5,
      ),
    );

    // Auto-zoom to fit the boundary on the map
    final lngs = widget.boundaryPoints.map((p) => p.coordinates.lng).toList();
    final lats = widget.boundaryPoints.map((p) => p.coordinates.lat).toList();

    final minLng = lngs.reduce(math.min);
    final maxLng = lngs.reduce(math.max);
    final minLat = lats.reduce(math.min);
    final maxLat = lats.reduce(math.max);

    final double centerLng = (minLng + maxLng) / 2;
final double centerLat = (minLat + maxLat) / 2;

// crude zoom estimation (safe + stable)
final double lngDiff = (maxLng - minLng).abs().toDouble();
final double latDiff = (maxLat - minLat).abs().toDouble();
final double maxDiff = math.max(lngDiff, latDiff);

double zoom = 14;
if (maxDiff < 0.001) zoom = 18;
else if (maxDiff < 0.005) zoom = 16;
else if (maxDiff < 0.02) zoom = 14;
else zoom = 12;

_mapController?.flyTo(
  mapbox.CameraOptions(
    center: mapbox.Point(
      coordinates: mapbox.Position(centerLng, centerLat),
    ),
    zoom: zoom,
  ),
  mapbox.MapAnimationOptions(duration: 1200),
);

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Land Details', style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Map with marked boundary (read-only)
            SizedBox(
              height: 300,
              child: mapbox.MapWidget(
                key: const ValueKey('detail_map'),
                styleUri: mapbox.MapboxStyles.SATELLITE_STREETS,
                onMapCreated: _onMapCreated,
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text('₹ ${widget.price.toStringAsFixed(0)}', style: GoogleFonts.poppins(fontSize: 22, color: const Color(0xFF2E7D32), fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text('${widget.areaInSqMeters.toStringAsFixed(2)} sq m', style: GoogleFonts.poppins(fontSize: 18)),
                  const SizedBox(height: 16),
                  Text('Description', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  Text(widget.description, style: GoogleFonts.poppins(fontSize: 16)),
                  const SizedBox(height: 24),
                  Text('Photos', style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 150,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.photoPaths.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(widget.photoPaths[index]),
                              width: 150,
                              height: 150,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}