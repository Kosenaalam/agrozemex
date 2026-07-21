import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/auth/screens/profile_screen_dash.dart';
import 'package:agrozemex/features/maps/screens/listing_details_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  mapbox.MapboxMap? _mapController;
  mapbox.PointAnnotationManager? _pointManager;
  mapbox.PolygonAnnotationManager? _polygonManager;
  mapbox.PolylineAnnotationManager? _outlineManager;

  final List<mapbox.Point> _boundaryPoints = [];
  Uint8List? _blueCircleIcon;

  double _areaInSqMeters = 0.0;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkerIcon();
    _requestLocationAndCenterMap();
  }

  Future<void> _loadCustomMarkerIcon() async {
    try {
      final ByteData data =
          await rootBundle.load('assets/icons/blue_circle.png');
      setState(() {
        _blueCircleIcon = data.buffer.asUint8List();
      });
    } catch (_) {}
  }

  Future<void> _requestLocationAndCenterMap() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _mapController?.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates:
                mapbox.Position(position.longitude, position.latitude),
          ),
          zoom: 17.0,
        ),
        mapbox.MapAnimationOptions(duration: 2000),
      );
    }
  }

  void _onMapCreated(mapbox.MapboxMap controller) async {
    _mapController = controller;

    _pointManager =
        await controller.annotations.createPointAnnotationManager();
    _polygonManager =
        await controller.annotations.createPolygonAnnotationManager();
    _outlineManager =
        await controller.annotations.createPolylineAnnotationManager();

    _pointManager?.dragEvents(onChanged: (annotation) async {
      if (_isSaved) return;

      final mapbox.Point newPoint = annotation.geometry;
      final int index = _boundaryPoints.indexWhere(
        (p) =>
            p.coordinates.lng == newPoint.coordinates.lng &&
            p.coordinates.lat == newPoint.coordinates.lat,
      );

      if (index != -1) {
        setState(() {
          _boundaryPoints[index] = newPoint;
        });
        await _updatePolygon();
      }
    });
  }

  Future<void> _onMapTap(mapbox.MapContentGestureContext context) async {
    if (_isSaved) return;

    final mapbox.Position position = context.point.coordinates;
    final mapbox.Point newPoint = mapbox.Point(coordinates: position);

    setState(() {
      _boundaryPoints.add(newPoint);
    });

    await _pointManager?.create(
      mapbox.PointAnnotationOptions(
        geometry: newPoint,
        image: _blueCircleIcon,
        iconSize: _blueCircleIcon != null ? 1.0 : 1.5,
        isDraggable: true,
      ),
    );

    await _updatePolygon();
  }

  Future<void> _updatePolygon() async {
    await _polygonManager?.deleteAll();
    await _outlineManager?.deleteAll();

    if (_boundaryPoints.length < 3) return;

    final List<mapbox.Position> closedRing = [
      ..._boundaryPoints.map((p) => p.coordinates),
      _boundaryPoints.first.coordinates,
    ];

    await _polygonManager?.create(
      mapbox.PolygonAnnotationOptions(
        geometry: mapbox.Polygon(coordinates: [closedRing]),
        fillColor: AgroZemexTokens.primary.withValues(alpha: 0.28).toARGB32(),
      ),
    );

    await _outlineManager?.create(
      mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(coordinates: closedRing),
        lineColor: AgroZemexTokens.primary.toARGB32(),
        lineWidth: 3.5,
      ),
    );
  }

  double _calculateAreaSqMeters() {
    if (_boundaryPoints.length < 3) return 0.0;

    const double earthRadius = 6378137.0;
    double area = 0.0;

    for (int i = 0; i < _boundaryPoints.length; i++) {
      final mapbox.Position p1 = _boundaryPoints[i].coordinates;
      final mapbox.Position p2 =
          _boundaryPoints[(i + 1) % _boundaryPoints.length].coordinates;

      final double lat1 = p1.lat * (math.pi / 180);
      final double lat2 = p2.lat * (math.pi / 180);
      final double lngDiff = (p2.lng - p1.lng) * (math.pi / 180);

      area += lngDiff * (2 + math.sin(lat1) + math.sin(lat2));
    }

    area = area * earthRadius * earthRadius / 2.0;
    return area.abs();
  }

  void _undo() async {
    if (_boundaryPoints.isNotEmpty && !_isSaved) {
      setState(() {
        _boundaryPoints.removeLast();
      });
      await _updatePolygon();
    }
  }

  void _clear() async {
    if (!_isSaved) {
      setState(() {
        _boundaryPoints.clear();
        _areaInSqMeters = 0.0;
        _isSaved = false;
      });
      await _pointManager?.deleteAll();
      await _updatePolygon();
    }
  }

  void _save() {
    if (_boundaryPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please mark at least 3 corners')),
      );
      return;
    }

    setState(() {
      _areaInSqMeters = _calculateAreaSqMeters();
      _isSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Land saved! Area: ${_areaInSqMeters.toStringAsFixed(2)} sq m',
        ),
        backgroundColor: AgroZemexTokens.primary,
      ),
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListingDetailsScreen(
          boundaryPoints: _boundaryPoints,
          areaInSqMeters: _areaInSqMeters,
        ),
      ),
    );
  }

  void _zoomIn() {
    _mapController?.getCameraState().then((state) {
      _mapController?.flyTo(
        mapbox.CameraOptions(zoom: (state.zoom) + 1.0),
        mapbox.MapAnimationOptions(duration: 300),
      );
    });
  }

  void _zoomOut() {
    _mapController?.getCameraState().then((state) {
      _mapController?.flyTo(
        mapbox.CameraOptions(zoom: (state.zoom) - 1.0),
        mapbox.MapAnimationOptions(duration: 300),
      );
    });
  }

  @override
  void dispose() {
    _pointManager?.deleteAll();
    _polygonManager?.deleteAll();
    _outlineManager?.deleteAll();
    _pointManager = null;
    _polygonManager = null;
    _outlineManager = null;
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double currentAreaHa = _calculateAreaSqMeters() / 10000.0;

    return Scaffold(
      body: Stack(
        children: [
          // Map Canvas
          mapbox.MapWidget(
            styleUri: mapbox.MapboxStyles.SATELLITE_STREETS,
            onMapCreated: _onMapCreated,
            onTapListener: _onMapTap,
          ),

          // Translucent Glass Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: AgroZemexTokens.glassBlurFilter,
                child: Container(
                  color: AgroZemexTokens.surface.withValues(alpha: 0.8),
                  padding: const EdgeInsets.only(
                    top: 48,
                    left: 20,
                    right: 20,
                    bottom: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AgroZemexTokens.primary,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Text(
                            'AgroZemex',
                            style: GoogleFonts.inter(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AgroZemexTokens.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const ProfileScreenDash(),
                            ),
                          );
                        },
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AgroZemexTokens.primary,
                              width: 2,
                            ),
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://lh3.googleusercontent.com/aida-public/AB6AXuBn_16ZaitnTSQY0WNoCE2eiBFq-mwFrahPOOlv2PjKKmUsBXjNdhKsJrnBGBPW8TcaUPrHx8bqmR2s4iys8Q2dAueIXD49Zqq_iJJ1lvS--kAEfW_CY7ARN1sbRljPHKgvkq-iz2-jzthw4OtLHA4gZ1ivNYqaPPJjMUa_KLfPT6c9xAadaPryeCEgRwf297_VVDGVNkmZhAkuzaqDTVY46ojdbteqfRJzdEX9n_j1bJrkPPx2zbQ2dQ',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Floating Map Controls (Right Side)
          Positioned(
            right: 16,
            top: 130,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AgroZemexTokens.softShadows,
                  ),
                  child: Column(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: AgroZemexTokens.onSurface,
                        ),
                        onPressed: _zoomIn,
                      ),
                      Container(
                        width: 32,
                        height: 1,
                        color: AgroZemexTokens.surfaceContainerLow,
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.remove,
                          color: AgroZemexTokens.onSurface,
                        ),
                        onPressed: _zoomOut,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'map_layer',
                  onPressed: () {},
                  backgroundColor: Colors.white.withValues(alpha: 0.85),
                  elevation: 2,
                  child: const Icon(
                    Icons.layers,
                    color: AgroZemexTokens.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'map_location',
                  onPressed: _requestLocationAndCenterMap,
                  backgroundColor: Colors.white.withValues(alpha: 0.85),
                  elevation: 2,
                  child: const Icon(
                    Icons.my_location,
                    color: AgroZemexTokens.primary,
                  ),
                ),
              ],
            ),
          ),

          // Floating Glass Bottom Sheet Preview Card
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: AgroZemexTokens.radiusLargeCard,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                boxShadow: AgroZemexTokens.softShadows,
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Center drag bar handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AgroZemexTokens.onSurfaceVariant.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AgroZemexTokens.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'ARABLE',
                              style: AgroZemexTokens.labelCaps.copyWith(
                                color: AgroZemexTokens.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AgroZemexTokens.secondary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'IRRIGATED',
                              style: AgroZemexTokens.labelCaps.copyWith(
                                color: AgroZemexTokens.secondary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Icon(
                        Icons.favorite_border,
                        color: AgroZemexTokens.onSurfaceVariant,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _boundaryPoints.isNotEmpty
                        ? 'Boundary Marked Parcel (${_boundaryPoints.length} Points)'
                        : "Val d'Orcia Estate",
                    style: AgroZemexTokens.headlineMedium.copyWith(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Siena, Tuscany Region',
                    style: AgroZemexTokens.bodyLarge.copyWith(
                      fontSize: 13,
                      color: AgroZemexTokens.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Area / Yield / Price Stats Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            'AREA',
                            style: AgroZemexTokens.labelCaps.copyWith(
                              fontSize: 10,
                              color: AgroZemexTokens.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentAreaHa > 0
                                ? '${currentAreaHa.toStringAsFixed(1)} ha'
                                : '${_boundaryPoints.length} pts',
                            style: AgroZemexTokens.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'YIELD',
                            style: AgroZemexTokens.labelCaps.copyWith(
                              fontSize: 10,
                              color: AgroZemexTokens.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '6.2 t/ha',
                            style: AgroZemexTokens.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Text(
                            'PRICE',
                            style: AgroZemexTokens.labelCaps.copyWith(
                              fontSize: 10,
                              color: AgroZemexTokens.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '€4.2M',
                            style: AgroZemexTokens.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AgroZemexTokens.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Actions: Undo, Clear, Save
                  Row(
                    children: [
                      IconButton(
                        onPressed: _undo,
                        icon: const Icon(Icons.undo),
                        tooltip: 'Undo',
                      ),
                      IconButton(
                        onPressed: _clear,
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Clear',
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AgroZemexTokens.primary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: AgroZemexTokens.radiusEight,
                            ),
                          ),
                          child: Text(
                            'Save & View Details',
                            style: AgroZemexTokens.bodyLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/*
================================================================================
PREVIOUS MAP SCREEN CODE (PRESERVED IN COMMENTED FORM AS REQUESTED)
================================================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:agrozemex/features/maps/screens/listing_details_screen.dart';

class _OldMapScreenState extends State<MapScreen> {
  mapbox.MapboxMap? _mapController;
  mapbox.PointAnnotationManager? _pointManager;
  mapbox.PolygonAnnotationManager? _polygonManager;
  mapbox.PolylineAnnotationManager? _outlineManager;

  final List<mapbox.Point> _boundaryPoints = [];
  Uint8List? _blueCircleIcon;

  double _areaInSqMeters = 0.0;
  bool _isSaved = false;

  final PanelController _panelController = PanelController();

  static const Color _primaryBlue = Color(0xFF0D47A1);
  static const Color _accentGreen = Color(0xFF2E7D32);
  static const Color _lightGray = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadCustomMarkerIcon();
    _requestLocationAndCenterMap();
  }

  Future<void> _loadCustomMarkerIcon() async {
    final ByteData data = await rootBundle.load('assets/icons/blue_circle.png');
    setState(() {
      _blueCircleIcon = data.buffer.asUint8List();
    });
  }

  Future<void> _requestLocationAndCenterMap() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _mapController?.flyTo(
        mapbox.CameraOptions(
          center: mapbox.Point(
            coordinates: mapbox.Position(position.longitude, position.latitude),
          ),
          zoom: 18.0,
        ),
        mapbox.MapAnimationOptions(duration: 2000),
      );
    }
  }

  void _onMapCreated(mapbox.MapboxMap controller) async {
    _mapController = controller;

    _pointManager = await controller.annotations.createPointAnnotationManager();
    _polygonManager = await controller.annotations.createPolygonAnnotationManager();
    _outlineManager = await controller.annotations.createPolylineAnnotationManager();

    _pointManager?.dragEvents(onChanged: (annotation) async {
      if (_isSaved) return;

      final mapbox.Point newPoint = annotation.geometry;
      final int index = _boundaryPoints.indexWhere(
        (p) => p.coordinates.lng == newPoint.coordinates.lng && p.coordinates.lat == newPoint.coordinates.lat,
      );

      if (index != -1) {
        setState(() {
          _boundaryPoints[index] = newPoint;
        });
        await _updatePolygon();
      }
    });
  }

  Future<void> _onMapTap(mapbox.MapContentGestureContext context) async {
    if (_isSaved) return;

    final mapbox.Position position = context.point.coordinates;
    final mapbox.Point newPoint = mapbox.Point(coordinates: position);

    setState(() {
      _boundaryPoints.add(newPoint);
    });

    await _pointManager?.create(
      mapbox.PointAnnotationOptions(
        geometry: newPoint,
        image: _blueCircleIcon,
        iconSize: _blueCircleIcon != null ? 1.0 : 1.5,
        isDraggable: true,
      ),
    );

    await _updatePolygon();
  }

  Future<void> _updatePolygon() async {
    await _polygonManager?.deleteAll();
    await _outlineManager?.deleteAll();

    if (_boundaryPoints.length < 3) return;

    final List<mapbox.Position> closedRing = [
      ..._boundaryPoints.map((p) => p.coordinates),
      _boundaryPoints.first.coordinates, 
    ];

    await _polygonManager?.create(
      mapbox.PolygonAnnotationOptions(
        geometry: mapbox.Polygon(coordinates: [closedRing]),
        fillColor: _primaryBlue.withValues(alpha: 0.28).toARGB32(),
      ),
    );

    await _outlineManager?.create(
      mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(coordinates: closedRing),
        lineColor: _primaryBlue.toARGB32(),
        lineWidth: 3.5,
      ),
    );
  }

  double _calculateAreaSqMeters() {
    if (_boundaryPoints.length < 3) return 0.0;

    const double earthRadius = 6378137.0; // meters
    double area = 0.0;

    for (int i = 0; i < _boundaryPoints.length; i++) {
      final mapbox.Position p1 = _boundaryPoints[i].coordinates;
      final mapbox.Position p2 = _boundaryPoints[(i + 1) % _boundaryPoints.length].coordinates;

      final double lat1 = p1.lat * (math.pi / 180);
      final double lat2 = p2.lat * (math.pi / 180);
      final double lngDiff = (p2.lng - p1.lng) * (math.pi / 180);

      area += lngDiff * (2 + math.sin(lat1) + math.sin(lat2));
    }

    area = area * earthRadius * earthRadius / 2.0;
    return area.abs();
  }

  void _undo() async {
    if (_boundaryPoints.isNotEmpty && !_isSaved) {
      setState(() {
        _boundaryPoints.removeLast();
      });
      await _updatePolygon();
    }
  }

  void _clear() async {
    if (!_isSaved) {
      setState(() {
        _boundaryPoints.clear();
        _areaInSqMeters = 0.0;
        _isSaved = false;
      });
      await _pointManager?.deleteAll();
      await _updatePolygon();
    }
  }

  void _save() {
    if (_boundaryPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please mark at least 3 corners')),
      );
      return;
    }

    setState(() {
      _areaInSqMeters = _calculateAreaSqMeters();
      _isSaved = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Land saved! Area: ${_areaInSqMeters.toStringAsFixed(2)} sq m'),
        backgroundColor: _accentGreen,
      ),
    );

    _panelController.close();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ListingDetailsScreen(
          boundaryPoints: _boundaryPoints,
          areaInSqMeters: _areaInSqMeters,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlidingUpPanel(
        controller: _panelController,
        minHeight: 140,
        maxHeight: MediaQuery.of(context).size.height * 0.5,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        panelBuilder: (_) => Container(),
        body: Stack(
          children: [
            mapbox.MapWidget(
              styleUri: mapbox.MapboxStyles.SATELLITE_STREETS,
              onMapCreated: _onMapCreated,
              onTapListener: _onMapTap,
            ),
          ],
        ),
      ),
    );
  }
}
================================================================================
*/