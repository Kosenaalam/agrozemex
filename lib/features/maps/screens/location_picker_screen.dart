import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import 'package:agrozemex/core/theme/theme.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  mapbox.MapboxMap? _mapController;
  mapbox.PointAnnotationManager? _pointManager;
  mapbox.Point? _selectedPoint;
  Uint8List? _pinIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkerIcon();
    _requestLocationAndCenterMap();
  }

  Future<void> _loadCustomMarkerIcon() async {
    try {
      final ByteData data = await rootBundle.load('assets/icons/blue_circle.png');
      setState(() {
        _pinIcon = data.buffer.asUint8List();
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
            coordinates: mapbox.Position(position.longitude, position.latitude),
          ),
          zoom: 15.0,
        ),
        mapbox.MapAnimationOptions(duration: 1500),
      );
    }
  }

  void _onMapCreated(mapbox.MapboxMap controller) async {
    _mapController = controller;
    _pointManager = await controller.annotations.createPointAnnotationManager();
  }

  Future<void> _onMapTap(mapbox.MapContentGestureContext context) async {
    final mapbox.Position position = context.point.coordinates;
    final mapbox.Point newPoint = mapbox.Point(coordinates: position);

    await _pointManager?.deleteAll();

    await _pointManager?.create(
      mapbox.PointAnnotationOptions(
        geometry: newPoint,
        image: _pinIcon,
        iconSize: _pinIcon != null ? 1.0 : 1.5,
      ),
    );

    setState(() {
      _selectedPoint = newPoint;
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

  void _confirmLocation() {
    if (_selectedPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please tap the map to drop a pin.')),
      );
      return;
    }
    Navigator.pop(context, {
      'lat': _selectedPoint!.coordinates.lat.toDouble(),
      'lng': _selectedPoint!.coordinates.lng.toDouble(),
    });
  }

  @override
  void dispose() {
    if (_pointManager != null) {
      _pointManager!.deleteAll().catchError((_) {});
      _pointManager = null;
    }
    _mapController = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              child: BackdropFilter(
                filter: AgroZemexTokens.glassBlurFilter,
                child: Container(
                  color: AgroZemexTokens.surface.withValues(alpha: 0.8),
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 8,
                    left: 20,
                    right: 20,
                    bottom: 14,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: AgroZemexTokens.onSurface),
                        onPressed: () => Navigator.pop(context),
                      ),
                      Expanded(
                        child: Text(
                          'Pick Location',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AgroZemexTokens.primary,
                            letterSpacing: -0.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance for centering
                    ],
                  ),
                ),
              ),
            ),
          ),
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
                        icon: const Icon(Icons.add, color: AgroZemexTokens.onSurface),
                        onPressed: _zoomIn,
                      ),
                      Container(
                        width: 32,
                        height: 1,
                        color: AgroZemexTokens.surfaceContainerLow,
                      ),
                      IconButton(
                        icon: const Icon(Icons.remove, color: AgroZemexTokens.onSurface),
                        onPressed: _zoomOut,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                FloatingActionButton.small(
                  heroTag: 'loc_picker_my_location',
                  onPressed: _requestLocationAndCenterMap,
                  backgroundColor: Colors.white.withValues(alpha: 0.85),
                  elevation: 2,
                  child: const Icon(Icons.my_location, color: AgroZemexTokens.primary),
                ),
              ],
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AgroZemexTokens.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AgroZemexTokens.radiusEight,
                  ),
                ),
                onPressed: _selectedPoint == null ? null : _confirmLocation,
                child: Text(
                  _selectedPoint == null ? 'TAP MAP TO SELECT' : 'CONFIRM LOCATION',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
