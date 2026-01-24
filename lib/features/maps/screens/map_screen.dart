import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:agrozemex/features/maps/screens/listing_details_screen.dart';

/// Professional Land Marking Screen for Agrozemex
/// Premium, attractive, clean UI with modern Material 3 design
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Controllers & Managers
  mapbox.MapboxMap? _mapController;
  mapbox.PointAnnotationManager? _pointManager;
  mapbox.PolygonAnnotationManager? _polygonManager;
  mapbox.PolylineAnnotationManager? _outlineManager;

  // Data
  final List<mapbox.Point> _boundaryPoints = [];
  Uint8List? _blueCircleIcon;

  // State
  double _areaInSqMeters = 0.0;
  bool _isSaved = false;

  // UI Controllers
  final PanelController _panelController = PanelController();

  // Constants
  static const Color _primaryBlue = Color(0xFF0D47A1);
  static const Color _accentGreen = Color(0xFF2E7D32);
  static const Color _lightGray = Color(0xFFF5F7FA);

  @override
  void initState() {
    super.initState();
    _loadCustomMarkerIcon();
    _requestLocationAndCenterMap();
  }

  /// Load custom blue circle marker (64x64 PNG with transparent background)
  Future<void> _loadCustomMarkerIcon() async {
    final ByteData data = await rootBundle.load('assets/icons/blue_circle.png');
    setState(() {
      _blueCircleIcon = data.buffer.asUint8List();
    });
  }

  /// Request location permission and center map on user's position
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

  /// Map ready callback — initialize annotation managers
  void _onMapCreated(mapbox.MapboxMap controller) async {
    _mapController = controller;

    _pointManager = await controller.annotations!.createPointAnnotationManager();
    _polygonManager = await controller.annotations!.createPolygonAnnotationManager();
    _outlineManager = await controller.annotations!.createPolylineAnnotationManager();

    // Enable dragging only if not saved
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

  /// Handle map tap — add new corner point
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

  /// Update polygon fill and visible border
  Future<void> _updatePolygon() async {
    await _polygonManager?.deleteAll();
    await _outlineManager?.deleteAll();

    if (_boundaryPoints.length < 3) return;

    final List<mapbox.Position> closedRing = [
      ..._boundaryPoints.map((p) => p.coordinates),
      _boundaryPoints.first.coordinates, // Close the shape
    ];

    // Transparent fill
    await _polygonManager?.create(
      mapbox.PolygonAnnotationOptions(
        geometry: mapbox.Polygon(coordinates: [closedRing]),
        fillColor: _primaryBlue.withOpacity(0.28).value,
      ),
    );

    // Visible blue border
    await _outlineManager?.create(
      mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(coordinates: closedRing),
        lineColor: _primaryBlue.value,
        lineWidth: 3.5,
      ),
    );
  }

  /// Accurate area calculation using spherical geometry
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

  /// Action: Undo last point
  void _undo() async {
    if (_boundaryPoints.isNotEmpty && !_isSaved) {
      setState(() {
        _boundaryPoints.removeLast();
      });
      await _updatePolygon();
    }
  }

  /// Action: Clear all
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

  /// Action: Save and calculate area
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

  /// Build premium draggable bottom panel
  Widget _buildControlPanel() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, -4)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(width: 48, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              children: [
                Text(
                  _isSaved ? 'Land Successfully Marked' : 'Mark Your Land Boundary',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: _primaryBlue,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _isSaved
                      ? 'Area: ${_areaInSqMeters.toStringAsFixed(2)} square meters'
                      : 'Tap on the map to add corners. Drag blue circles to adjust.',
                  style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[700]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                 SingleChildScrollView(
                scrollDirection: Axis.horizontal, 
              child:  Row(
                 // mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    
                     _actionButton('Undo', Icons.undo, _undo, enabled: !_isSaved),
                    
                    _actionButton('Clear', Icons.delete_outline, _clear, enabled: !_isSaved, destructive: true),
                                        
                    _actionButton('Save', Icons.save, _save, enabled: !_isSaved, primary: true),
              
                  ],

                ),
             )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionButton(String label, IconData icon, VoidCallback onTap, {bool enabled = true, bool destructive = false, bool primary = false}) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: primary ? _accentGreen : destructive ? Colors.red.shade600 : _lightGray,
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: primary || destructive ? Colors.white : _primaryBlue, size: 22),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: primary || destructive ? Colors.white : _primaryBlue,
                  ),
                ),
              ],
            ),
          ),
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
        panelBuilder: (_) => _buildControlPanel(),
        body: Stack(
          children: [
            mapbox.MapWidget(
              styleUri: mapbox.MapboxStyles.SATELLITE_STREETS,
              onMapCreated: _onMapCreated,
              onTapListener: _onMapTap,
            ),
            // Premium center crosshair
            Center(
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 12)],
                ),
                child: const Icon(Icons.add, color: _primaryBlue, size: 32),
              ),
            ),
          ],
        ),
      ),
    );
  }
}