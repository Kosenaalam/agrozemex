import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class ListingDetailScreen extends StatefulWidget {
  final String title;
  final double price;
  final String description;
  final double areaInSqMeters;
  final List<mapbox.Point> boundaryPoints;
  final List<String> photoPaths; // CAN BE URL OR LOCAL PATH

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
  mapbox.MapboxMap? _mapController;
  mapbox.PointAnnotationManager? _pointManager;
  mapbox.PolygonAnnotationManager? _polygonManager;
  mapbox.PolylineAnnotationManager? _outlineManager;

  Uint8List? _blueCircleIcon;

  @override
  void initState() {
    super.initState();
    _loadBlueCircleIcon();
  }

  Future<void> _loadBlueCircleIcon() async {
    final data = await rootBundle.load('assets/icons/blue_circle.png');
    _blueCircleIcon = data.buffer.asUint8List();
  }

  void _onMapCreated(mapbox.MapboxMap controller) async {
    _mapController = controller;
    _pointManager = await controller.annotations!.createPointAnnotationManager();
    _polygonManager =
        await controller.annotations!.createPolygonAnnotationManager();
    _outlineManager =
        await controller.annotations!.createPolylineAnnotationManager();

    await _drawBoundary();
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
        iconSize: 0.5,
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
  if (maxDiff < 0.001) 
  {
    zoom = 18;
  }
  else if (maxDiff < 0.005)
  {
     zoom = 16;
  }
  else if (maxDiff < 0.02) 
  {
    zoom = 14;
  }
  else
  {
     zoom = 12;
  }
  
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


  // 🔥 IMPORTANT FIX HERE
  Widget _buildPhoto(String path) {
    final bool isNetwork = path.startsWith('http');

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: isNetwork
          ? Image.network(
              path,
              width: 150,
              height: 150,
              fit: BoxFit.cover,
              loadingBuilder: (c, w, p) =>
                  p == null ? w : const Center(child: CircularProgressIndicator()),
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.broken_image),
            )
          : Image.file(
              File(path),
              width: 150,
              height: 150,
              fit: BoxFit.cover,
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Land Details'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 300,
              child: mapbox.MapWidget(
                styleUri: mapbox.MapboxStyles.SATELLITE_STREETS,
                onMapCreated: _onMapCreated,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.title,
                      style: GoogleFonts.poppins(
                          fontSize: 24, fontWeight: FontWeight.bold)),
                  Text('₹ ${widget.price.toStringAsFixed(0)}'),
                  Text(
                      '${widget.areaInSqMeters.toStringAsFixed(2)} sq m'),
                  const SizedBox(height: 16),
                  Text(widget.description),
                  const SizedBox(height: 24),
                  Text('Photos',
                      style: GoogleFonts.poppins(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 150,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: widget.photoPaths.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: 12),
                      itemBuilder: (context, index) =>
                          _buildPhoto(widget.photoPaths[index]),
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
