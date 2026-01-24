// F:\agrozemex\lib\features\maps\screens\view_listing_map_screen.dart
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class ViewListingMapScreen extends StatefulWidget {
  final String listingId;
  const ViewListingMapScreen({super.key, required this.listingId});

  @override
  State<ViewListingMapScreen> createState() => _ViewListingMapScreenState();
}

class _ViewListingMapScreenState extends State<ViewListingMapScreen> {
  mapbox.MapboxMap? _mapController;
  mapbox.PolygonAnnotationManager? _polygonManager;
  mapbox.CircleAnnotationManager? _circleManager;
  // Uint8List? _blueCircleIcon;

  bool _isLoading = true;
  String? _errorMessage;
  List<mapbox.Point> _boundaryPoints = [];

  @override
  void initState() {
    super.initState();
    // _loadBlueCircleIcon();
    _fetchListing();
  }

  // Future<void> _loadBlueCircleIcon() async {
  //   final data = await rootBundle.load('assets/icons/blue_circle.png');
  //   _blueCircleIcon = data.buffer.asUint8List();
  // }

  Future<void> _fetchListing() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('listings').doc(widget.listingId).get();
      if (!doc.exists || !mounted) {
        setState(() {
          _errorMessage = 'Listing not found';
          _isLoading = false;
        });
        return;
      }

      final data = doc.data()!;
      final points = (data['boundary_points'] as List<dynamic>?)
          ?.map((p) => mapbox.Point(coordinates: mapbox.Position(p['lng'], p['lat'])))
          .toList() ??
          [];

      if (points.isEmpty && mounted) {
        setState(() {
          _errorMessage = 'No boundary data available';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _boundaryPoints = points;
        _isLoading = false;
      });

      // Wait for map to be ready, then draw & zoom
      if (_mapController != null) {
        await _drawAndZoom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onMapCreated(mapbox.MapboxMap controller) async {
    _mapController = controller;
    _polygonManager = await controller.annotations.createPolygonAnnotationManager();
    _circleManager = await controller.annotations.createCircleAnnotationManager();

    // Draw & zoom once map is ready
    if (_boundaryPoints.isNotEmpty) {
      await _drawAndZoom();
    }
  }

  Future<void> _drawAndZoom() async {
    await _polygonManager?.deleteAll();
    await _circleManager?.deleteAll();

    // Add blue circle markers
    for (final point in _boundaryPoints) {
      await _circleManager?.create(
        mapbox.CircleAnnotationOptions(
          geometry: point,
          circleColor: 0xFF0D47A1,
          circleRadius: 8.0,
        ),
      );
    }

    // Draw polygon (fill + border)
    if (_boundaryPoints.length >= 3) {
      final ring = [
        ..._boundaryPoints.map((p) => p.coordinates),
        _boundaryPoints.first.coordinates,
      ];

      await _polygonManager?.create(
        mapbox.PolygonAnnotationOptions(
          geometry: mapbox.Polygon(coordinates: [ring]),
          fillColor: 0xFF0D47A1,
          fillOpacity: 0.28,
        ),
      );

      // Optional border polyline if you want thicker outline
    }

    // Zoom logic (same as your MapScreen)
    final lats = _boundaryPoints.map((p) => p.coordinates.lat).toList();
    final lngs = _boundaryPoints.map((p) => p.coordinates.lng).toList();

    final centerLat = lats.reduce((a, b) => a + b) / lats.length;
    final centerLng = lngs.reduce((a, b) => a + b) / lngs.length;

    final minLng = lngs.reduce(math.min);
    final maxLng = lngs.reduce(math.max);
    final minLat = lats.reduce(math.min);
    final maxLat = lats.reduce(math.max);

    final lngDiff = (maxLng - minLng).abs();
    final latDiff = (maxLat - minLat).abs();
    final maxDiff = math.max(lngDiff, latDiff);

    double zoom = 14;
    if (maxDiff < 0.001){ zoom = 18;}
    else if (maxDiff < 0.005) { zoom = 16;}
    else if (maxDiff < 0.02){ zoom = 14;}
    else{ zoom = 12;}

    await _mapController?.flyTo(
      mapbox.CameraOptions(
        center: mapbox.Point(coordinates: mapbox.Position(centerLng, centerLat)),
        zoom: zoom,
      ),
      mapbox.MapAnimationOptions(duration: 1200),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_errorMessage != null) {
      return Scaffold(body: Center(child: Text(_errorMessage!)));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Listing on Map'),
        backgroundColor: const Color(0xFF0D47A1),
      ),
      body: mapbox.MapWidget(
        styleUri: mapbox.MapboxStyles.SATELLITE_STREETS,
        onMapCreated: _onMapCreated,
      ),
    );
  }
}