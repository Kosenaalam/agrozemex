import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/maps/screens/listing_details_screen.dart';
import 'package:agrozemex/features/navigation/main_navigation_shell.dart';
import '../widgets/area_stats_panel.dart';
import '../widgets/map_action_buttons.dart';
import '../services/boundary_service.dart';

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

      if (!mounted) return;

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
      int index = -1;
      double minDistance = double.infinity;
      for (int i = 0; i < _boundaryPoints.length; i++) {
        final p = _boundaryPoints[i];
        final dist = ((p.coordinates.lng - newPoint.coordinates.lng).abs() +
                     (p.coordinates.lat - newPoint.coordinates.lat).abs()).toDouble();
        if (dist < minDistance) {
          minDistance = dist;
          index = i;
        }
      }

      if (index != -1 && minDistance < 0.01) {
        setState(() {
          _boundaryPoints[index] = newPoint;
          _areaInSqMeters = _calculateAreaSqMeters();
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

    final sortedPoints = BoundaryService.sortClockwise(_boundaryPoints);

    final List<mapbox.Position> closedRing = [
      ...sortedPoints.map((p) => p.coordinates),
      sortedPoints.first.coordinates,
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
        lineColor: Colors.blue.toARGB32(),
        lineWidth: 3.5,
      ),
    );
  }

  double _calculateAreaSqMeters() {
    final sortedPoints = BoundaryService.sortClockwise(_boundaryPoints);
    return BoundaryService.calculateAreaSqMeters(sortedPoints);
  }

  void _undo() async {
    if (_boundaryPoints.isNotEmpty && !_isSaved) {
      setState(() {
        _boundaryPoints.removeLast();
        _areaInSqMeters = _calculateAreaSqMeters();
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
          boundaryPoints: BoundaryService.sortClockwise(_boundaryPoints),
          areaInSqMeters: _areaInSqMeters,
        ),
      ),
    ).then((result) {
      if (mounted) {
        if (result == true) {
          _clear();
          MainNavigationShell.of(context)?.switchTab(0);
        } else {
          setState(() {
            _isSaved = false;
          });
        }
      }
    });
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
    // PERF FIX: Use unawaited for async calls in dispose() — fire-and-forget
    // cleanup that doesn't need to block the widget tree teardown.
    if (_pointManager != null) {
      _pointManager!.deleteAll().catchError((_) {});
      _pointManager = null;
    }
    if (_polygonManager != null) {
      _polygonManager!.deleteAll().catchError((_) {});
      _polygonManager = null;
    }
    if (_outlineManager != null) {
      _outlineManager!.deleteAll().catchError((_) {});
      _outlineManager = null;
    }
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Map Canvas
          mapbox.MapWidget(
            styleUri: mapbox.MapboxStyles.SATELLITE_STREETS,
            onMapCreated: _onMapCreated,
            onTapListener: _onMapTap,
            gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
              Factory<OneSequenceGestureRecognizer>(
                () => EagerGestureRecognizer(),
              ),
            },
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
                    bottom: 14,
                  ),
                  child: Center(
                    child: Text(
                      'AgroZemex - Sell Land',
                      style: GoogleFonts.inter(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AgroZemexTokens.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
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
                  AreaStatsPanel(
                    pointsCount: _boundaryPoints.length,
                    areaInSqMeters: _areaInSqMeters,
                    hasSelfIntersection: BoundaryService.hasSelfIntersection(_boundaryPoints),
                  ),
                  const SizedBox(height: 16),
                  MapActionButtons(
                    onUndo: _undo,
                    onClear: _clear,
                    onSave: _save,
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