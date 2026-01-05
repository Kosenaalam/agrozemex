import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:geolocator/geolocator.dart';
import 'dart:math' as math;
import 'dart:async';



   enum BoundaryStatus {
  empty,        // 0 points
  drafting,     // 1–2 points
  warning,      // 3 points (triangle)
  valid,        // 4–8 points (ideal farmland)
  noisy,        // >8 points (too many points)
}
    // -------Boundary Quality Levels-------

    enum BoundaryQuality {
  invalid,   // cannot save
  warning,   // usable but needs improvement
  good,      // acceptable
  excellent, // survey-grade
}




class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late mapbox.MapboxMap _mapboxMap;

  // --- GPS QUALITY LIMITS ---
static const double _maxAllowedAccuracy = 12.0; // meters (industrial safe)
static const double _minWalkDistance = 2.5;     // meters (anti-jitter)

    static const double _minCornerAngle = 25.0; // degrees (corner sensitivity)
    // --- POLYGON CLOSING ---
       static const double _snapCloseDistance = 4.0; // meters (survey-grade)

       // --- BOUNDARY SIMPLIFICATION ---
    static const double _simplifyTolerance = 1.2; // meters





  mapbox.PolylineAnnotationManager? _polylineManager;
  mapbox.PointAnnotationManager? _pointManager;
  mapbox.PolygonAnnotationManager? _polygonManager;





  /// Single source of truth (Option A rule)
  final List<mapbox.Point> _boundaryPoints = [];


  bool _isBoundaryLocked = false;


          // ---------------- WALKING MODE ----------------

StreamSubscription<Position>? _positionStream;
Position? _lastRecordedPosition;

bool _isWalkingMode = false;

bool _isBoundaryFinalized = false;





  // ---------------- MAP CREATED ----------------
  void _onMapCreated(mapbox.MapboxMap mapboxMap) async {
    _mapboxMap = mapboxMap;




    _pointManager =
        await _mapboxMap.annotations.createPointAnnotationManager();

    _polylineManager =
        await _mapboxMap.annotations.createPolylineAnnotationManager();

        _polygonManager =
    await _mapboxMap.annotations.createPolygonAnnotationManager();

         
         await _moveCameraToCurrentLocation();

  }

                   // ---------------- CURRENT LOCATION ----------------

Future<void> _moveCameraToCurrentLocation() async {
  // 1. Check service
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return;

  // 2. Check permission
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return;
  }

  // 3. Get position
  final position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  // 4. Move map camera
  await _mapboxMap.setCamera(
    mapbox.CameraOptions(
      center: mapbox.Point(
        coordinates: mapbox.Position(
          position.longitude,
          position.latitude,
        ),
      ),
      zoom: 19.0, // farmland-level zoom
      pitch: 0,
      bearing: 0,
    ),
  );
}

        //  ----------Start walking capture----------


        Future<void> _startWalkingCapture() async {
  if (_isBoundaryLocked) return;
  if (_isWalkingMode) return;

  _isWalkingMode = true;
  _lastRecordedPosition = null;

  _positionStream = Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 1, // raw GPS updates
    ),
  ).listen((position) async {
    if (!_isWalkingMode) return;
          
          // 1️⃣ Accuracy filter
  if (position.accuracy > _maxAllowedAccuracy) {
    return; // ❌ ignore bad GPS point
  }

    if (_lastRecordedPosition == null) {
      _lastRecordedPosition = position;
      await _addPoint(
        mapbox.Point(
          coordinates: mapbox.Position(
            position.longitude,
            position.latitude,
          ),
        ),
      );
      return;
    }

    final distance =
        _distanceInMeters(_lastRecordedPosition!, position);

    if (distance < _minWalkDistance)  return;
    
     final previous = _lastRecordedPosition!;
final currentBearing = _bearingBetween(previous, position);

double? lastBearing;
if (_boundaryPoints.length >= 2) {
 

 final prevGps = _lastRecordedPosition!;
final lastPoint = _boundaryPoints.last.coordinates;

lastBearing = _bearingBetween(
  prevGps,
  Position(
   latitude: lastPoint.lat.toDouble(),
longitude: lastPoint.lng.toDouble(),

    timestamp: prevGps.timestamp,
    accuracy: prevGps.accuracy,
    altitude: prevGps.altitude,
    altitudeAccuracy: prevGps.altitudeAccuracy,
    heading: prevGps.heading,
    headingAccuracy: prevGps.headingAccuracy,
    speed: prevGps.speed,
    speedAccuracy: prevGps.speedAccuracy,
  ),
);

}

_lastRecordedPosition = position;

// First or second point → always allow
if (lastBearing == null) {
  await _addPoint(
    mapbox.Point(
      coordinates: mapbox.Position(
        position.longitude,
        position.latitude,
      ),
    ),
  );
  return;
}

final angleChange = _angleDifference(lastBearing, currentBearing);

// Only add point if it's a real corner
if (angleChange >= _minCornerAngle) {
  await _addPoint(
    mapbox.Point(
      coordinates: mapbox.Position(
        position.longitude,
        position.latitude,
      ),
    ),
  );
}
        });
}
 
      // ---------- Stop walking capture ----------

          Future<void> _stopWalkingCapture() async {
            if (_isBoundaryFinalized) return;

            if (!_isWalkingMode) return;

  _isWalkingMode = false;
  await _positionStream?.cancel();
  _positionStream = null;

         debugPrint('Walking stopped. Total points: ${_boundaryPoints.length}');

           if (_boundaryPoints.length < 3) {
    debugPrint('Not enough points to draw boundary');
    return;
  }
                 
                 // STEP 5.1 — Trim last noisy GPS points
if (_boundaryPoints.length >= 4) {
  final last = _boundaryPoints.last;
  final secondLast = _boundaryPoints[_boundaryPoints.length - 2];

            final tailDistance = _distanceLatLng(
  last.coordinates.lat.toDouble(),
  last.coordinates.lng.toDouble(),
  secondLast.coordinates.lat.toDouble(),
  secondLast.coordinates.lng.toDouble(),
);


  // Remove tail jitter
  if (tailDistance < 1.5) {
    _boundaryPoints.removeLast();
  }
}


  // 1️⃣ Stop GPS + redraw polyline
await _drawPolyline();

  // STEP 6 — Snap-close polygon if end is near start
if (_shouldSnapClose()) {
  final first = _boundaryPoints.first;
  _boundaryPoints[_boundaryPoints.length - 1] = first;
  }

    // STEP 7 — Simplify boundary (Douglas–Peucker)
     final simplified = _simplifyBoundary(
  _boundaryPoints,
  _simplifyTolerance,
);
        // 4️⃣ STEP-7/8: Normalize + self-intersection check
         
 final processed = _rejectShortEdgesAndSpikes(
  _normalizeBoundary(List.from(_boundaryPoints)),
);

   // // 5️⃣ Validate intersections
if (_hasSelfIntersection(processed)) {
  if (!mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Invalid boundary: lines cross each other'),
      backgroundColor: Colors.red,
    ),
  );
  return;
}

      
     // ✅ STEP-9 (QUALITY EVALUATION)
// ===============================
final quality = evaluateBoundaryQuality(_boundaryPoints);
debugPrint('Boundary quality: ${boundaryQualityLabel(quality)}');

// 6️⃣ Accept final boundary
_boundaryPoints
  ..clear()
  ..addAll(processed);
  _isBoundaryFinalized = true;



_boundaryPoints
  ..clear()
  ..addAll(simplified);

// Force redraw after walking stops
await _drawPolyline();


  _boundaryPoints
  ..clear()
  ..addAll(_normalizeBoundary(List.from(_boundaryPoints)));


  setState(() {});
}




        // ---------------Mapbox tap events----------------




  // ---------------- ADD POINT (MANUAL / GPS / CENTER) ----------------
  Future<void> _addPoint(mapbox.Point point) async {
    if (_isBoundaryFinalized) return;

    if (_isBoundaryLocked) return;

    setState(() {
      if (_isStableCorner(point)) {
      _boundaryPoints.add(point);
      }
    });
    

    await _pointManager?.create(
      mapbox.PointAnnotationOptions(
        geometry: point,
        iconSize: 0.8,
      ),
    );

    await _drawPolyline();
  }

  // ---------------- DRAW POLYLINE ----------------
  Future<void> _drawPolyline() async {
    if (_polylineManager == null) return;
    if (_boundaryPoints.length < 2) return;

    await _polylineManager!.deleteAll();

    final List<mapbox.Position> positions =
      _boundaryPoints.map((p) => p.coordinates).toList();

      // 🔒 CLOSE THE BOUNDARY (Option A – Stable)
        if (positions.length >= 3) {
              positions.add(positions.first);
    }

    await _polylineManager!.create(
      mapbox.PolylineAnnotationOptions(
        geometry: mapbox.LineString(coordinates: positions),
        lineWidth: 3.0,
        lineColor: 0xFFFF0000, // RED (ARGB safe)
      ),
    );

    await _drawPolygon();

  }
        // ---------------- DRAW POLYGON ----------------


       Future<void> _drawPolygon() async {
  if (_polygonManager == null) return;
  if (_boundaryPoints.length < 3) return;

  await _polygonManager!.deleteAll();

  final List<mapbox.Position> positions =
      _boundaryPoints.map((p) => p.coordinates).toList();

  // 🔒 Ensure closed polygon
  if (positions.first != positions.last) {
    positions.add(positions.first);
  }

  await _polygonManager!.create(
    mapbox.PolygonAnnotationOptions(
      geometry: mapbox.Polygon(coordinates: [positions]),
      fillColor: 0x5500FF00,       // semi-transparent green
      fillOutlineColor: 0xFF00FF00,
    ),
  );
     _printBoundaryArea();
}


             // ================== AREA CALCULATION ==================

double _calculatePolygonAreaInSqMeters(List<mapbox.Position> positions) {
  if (positions.length < 3) return 0;

  const double earthRadius = 6378137; // meters (WGS84)
  double area = 0;

  for (int i = 0; i < positions.length; i++) {
    final p1 = positions[i];
    final p2 = positions[(i + 1) % positions.length];

    final lon1 = p1.lng * (3.141592653589793 / 180);
    final lon2 = p2.lng * (3.141592653589793 / 180);
    final lat1 = p1.lat * (3.141592653589793 / 180);
    final lat2 = p2.lat * (3.141592653589793 / 180);

    area += (lon2 - lon1) * (2 + math.sin(lat1) + math.sin(lat2));
  }

  area = area * earthRadius * earthRadius / 2.0;
  return area.abs();
}
         double _toAcres(double sqMeters) => sqMeters * 0.000247105;
double _toHectares(double sqMeters) => sqMeters * 0.0001;


           void _printBoundaryArea() {
  if (_boundaryPoints.length < 3) return;

  final positions =
      _boundaryPoints.map((p) => p.coordinates).toList();

  final areaSqM = _calculatePolygonAreaInSqMeters(positions);
  final acres = _toAcres(areaSqM);
  final hectares = _toHectares(areaSqM);

  debugPrint('Area: ${areaSqM.toStringAsFixed(2)} m²');
  debugPrint('Area: ${acres.toStringAsFixed(2)} acres');
  debugPrint('Area: ${hectares.toStringAsFixed(2)} hectares');
}
             
            //  ---------------- BOUNDARY STATUS EVALUATION ----------------

             BoundaryStatus _evaluateBoundaryStatus() {
            final count = _boundaryPoints.length;

             if (count == 0) {
            return BoundaryStatus.empty;
      }

           if (count < 3) {
            return BoundaryStatus.drafting;
     }

           if (count == 3) {
          return BoundaryStatus.warning;
     }

          if (count <= 8) {
         return BoundaryStatus.valid;
  }

  return BoundaryStatus.noisy;
}    
         

        //  ----------ADD SAVE ELIGIBILITY CHECK----------


        bool _canSaveBoundary() {
  return _evaluateBoundaryStatus() == BoundaryStatus.valid;
}
                  // ----------------Show Area on Screen----------------

                  String _formattedAreaText() {
  if (_boundaryPoints.length < 3) {
    return '';
  }

  final positions =
      _boundaryPoints.map((p) => p.coordinates).toList();

  final areaSqM = _calculatePolygonAreaInSqMeters(positions);
  final acres = _toAcres(areaSqM);
  final hectares = _toHectares(areaSqM);

  return 'Area: ${acres.toStringAsFixed(2)} acres '
         '(${hectares.toStringAsFixed(2)} hectares)';
}

            //  ------------distance calculation helper------------

            double _distanceInMeters(Position a, Position b) {
  return Geolocator.distanceBetween(
    a.latitude,
    a.longitude,
    b.latitude,
    b.longitude,
  );
}

    //  -------helper: Line segment intersection---------

    bool _segmentsIntersect(
  double ax, double ay,
  double bx, double by,
  double cx, double cy,
  double dx, double dy,
) {
  double _cross(double x1, double y1, double x2, double y2) {
    return x1 * y2 - y1 * x2;
  }

  bool _intersect1D(double a, double b, double c, double d) {
    if (a > b) { final t = a; a = b; b = t; }
    if (c > d) { final t = c; c = d; d = t; }
    return math.max(a, c) <= math.min(b, d);
  }

  if (
    !_intersect1D(ax, bx, cx, dx) ||
    !_intersect1D(ay, by, cy, dy)
  ) {
    return false;
  }

  final abx = bx - ax;
  final aby = by - ay;
  final acx = cx - ax;
  final acy = cy - ay;
  final adx = dx - ax;
  final ady = dy - ay;

  final cdx = dx - cx;
  final cdy = dy - cy;
  final cax = ax - cx;
  final cay = ay - cy;
  final cbx = bx - cx;
  final cby = by - cy;

  return
    _cross(abx, aby, acx, acy) * _cross(abx, aby, adx, ady) <= 0 &&
    _cross(cdx, cdy, cax, cay) * _cross(cdx, cdy, cbx, cby) <= 0;
}
          // ------------self-intersection checker------------

          bool _hasSelfIntersection(List<mapbox.Point> points) {
  if (points.length < 4) return false;

  for (int i = 0; i < points.length - 1; i++) {
    final a1 = points[i].coordinates;
    final a2 = points[i + 1].coordinates;

    for (int j = i + 2; j < points.length - 1; j++) {
      // Skip adjacent edges
      if (i == 0 && j == points.length - 2) continue;

      final b1 = points[j].coordinates;
      final b2 = points[j + 1].coordinates;

      if (_segmentsIntersect(
        a1.lng.toDouble(), a1.lat.toDouble(),
  a2.lng.toDouble(), a2.lat.toDouble(),
  b1.lng.toDouble(), b1.lat.toDouble(),
  b2.lng.toDouble(), b2.lat.toDouble(),
      )) {
        return true;
      }
    }
  }
  return false;
}

              //  --------- distance lat lng----------

          double _distanceLatLng(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  return Geolocator.distanceBetween(lat1, lng1, lat2, lng2);
}

        //  ---------Douglas–Peucker helper---------

        List<mapbox.Point> _simplifyBoundary(
  List<mapbox.Point> points,
  double tolerance,
) {
  if (points.length < 3) return points;

  final List<bool> keep = List.filled(points.length, false);
  keep[0] = true;
  keep[points.length - 1] = true;

  void simplifySection(int start, int end) {
    double maxDistance = 0;
    int index = -1;

    for (int i = start + 1; i < end; i++) {
      final dist = _perpendicularDistance(
        points[i].coordinates,
        points[start].coordinates,
        points[end].coordinates,
      );

      if (dist > maxDistance) {
        maxDistance = dist;
        index = i;
      }
    }

    if (maxDistance > tolerance && index != -1) {
      keep[index] = true;
      simplifySection(start, index);
      simplifySection(index, end);
    }
  }

  simplifySection(0, points.length - 1);

  final List<mapbox.Point> result = [];
  for (int i = 0; i < points.length; i++) {
    if (keep[i]) result.add(points[i]);
  }

  return result;
}
                  //  ---------perpendicular distance helper---------

                  double _perpendicularDistance(
  mapbox.Position p,
  mapbox.Position a,
  mapbox.Position b,
) {
  final double x0 = p.lng.toDouble();
  final double y0 = p.lat.toDouble();
  final double x1 = a.lng.toDouble();
  final double y1 = a.lat.toDouble();
  final double x2 = b.lng.toDouble();
  final double y2 = b.lat.toDouble();

  final double dx = x2 - x1;
  final double dy = y2 - y1;

  if (dx == 0 && dy == 0) {
    return _distanceLatLng(y0, x0, y1, x1);
  }

  final double t =
      ((x0 - x1) * dx + (y0 - y1) * dy) / (dx * dx + dy * dy);

  final double projX = x1 + t * dx;
  final double projY = y1 + t * dy;

  return _distanceLatLng(y0, x0, projY, projX);
}



        // ---------GPS point is very close to the first point then snap close---------

        bool _shouldSnapClose() {
  if (_boundaryPoints.length < 3) return false;

  final first = _boundaryPoints.first.coordinates;
  final last = _boundaryPoints.last.coordinates;

  final distance = _distanceLatLng(
    first.lat.toDouble(),
    first.lng.toDouble(),
    last.lat.toDouble(),
    last.lng.toDouble(),
  );

  return distance <= _snapCloseDistance;
}



                // ----------helper functions----------

                double _bearingBetween(Position a, Position b) {
  final lat1 = a.latitude * (3.141592653589793 / 180);
  final lat2 = b.latitude * (3.141592653589793 / 180);
  final dLon = (b.longitude - a.longitude) * (3.141592653589793 / 180);

  final y = math.sin(dLon) * math.cos(lat2);
  final x = math.cos(lat1) * math.sin(lat2) -
      math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

  final bearing = math.atan2(y, x);
  return (bearing * 180 / 3.141592653589793 + 360) % 360;
}

double _angleDifference(double a, double b) {
  final diff = (a - b).abs();
  return diff > 180 ? 360 - diff : diff;
}
            //  -------bearinglatlng helper---------
            double _bearingLatLng(
  double lat1,
  double lng1,
  double lat2,
  double lng2,
) {
  final double phi1 = lat1 * math.pi / 180;
  final double phi2 = lat2 * math.pi / 180;
  final double dLambda = (lng2 - lng1) * math.pi / 180;

  final double y = math.sin(dLambda) * math.cos(phi2);
  final double x = math.cos(phi1) * math.sin(phi2) -
      math.sin(phi1) * math.cos(phi2) * math.cos(dLambda);

  final double bearing = math.atan2(y, x) * 180 / math.pi;
  return (bearing + 360) % 360;
}

         
        //  -----------CORNER DENSITY NORMALIZATION-----------

        List<mapbox.Point> _normalizeBoundary(List<mapbox.Point> input) {
  if (input.length < 5) return input;

  final List<mapbox.Point> result = [input.first];

  for (int i = 1; i < input.length - 1; i++) {
    final prev = result.last.coordinates;
    final curr = input[i].coordinates;

   final dist = _distanceLatLng(
    prev.lat.toDouble(),
  prev.lng.toDouble(),
  curr.lat.toDouble(),
  curr.lng.toDouble(),
); 

    if (dist > 1.8) {
      result.add(input[i]);
    }
  }

  result.add(input.last);
  return result;
}         
    // ----------Minimum Edge Length & Spike Rejection----------

        List<mapbox.Point> _rejectShortEdgesAndSpikes(
  List<mapbox.Point> input, {
  double minEdgeMeters = 1.8,
  double maxSpikeAngleDeg = 25.0,
}) {
  if (input.length < 4) return input;

  final List<mapbox.Point> result = [input.first];

  for (int i = 1; i < input.length - 1; i++) {
    final prev = result.last.coordinates;
    final curr = input[i].coordinates;
    final next = input[i + 1].coordinates;

    // 1️⃣ Reject very short edges
    final edgeLen = _distanceLatLng(
      prev.lat.toDouble(),
      prev.lng.toDouble(),
      curr.lat.toDouble(),
      curr.lng.toDouble(),
    );

    if (edgeLen < minEdgeMeters) {
      continue;
    }

    // 2️⃣ Reject GPS spikes (sharp zig-zags)
   final b1 = _bearingLatLng(
  prev.lat.toDouble(),
  prev.lng.toDouble(),
  curr.lat.toDouble(),
  curr.lng.toDouble(),
);

final b2 = _bearingLatLng(
  curr.lat.toDouble(),
  curr.lng.toDouble(),
  next.lat.toDouble(),
  next.lng.toDouble(),
);


    final angle = _angleDifference(b1, b2);

    if (angle < maxSpikeAngleDeg) {
      continue;
    }

    result.add(input[i]);
  }

  result.add(input.last);
  return result;
}





              // ----------Stabilize Corner Zig-Zag--------------

              bool _isStableCorner(mapbox.Point newPoint) {
  if (_boundaryPoints.length < 2) return true;

  final last = _boundaryPoints.last.coordinates;
  final prev = _boundaryPoints[_boundaryPoints.length - 2].coordinates;

  final dx1 = last.lng - prev.lng;
  final dy1 = last.lat - prev.lat;

  final dx2 = newPoint.coordinates.lng - last.lng;
  final dy2 = newPoint.coordinates.lat - last.lat;

  // dot product angle check
  final dot = dx1 * dx2 + dy1 * dy2;

  return dot >= 0; // reject sharp back-tracking
}

      //  -------boundary Quality Evaluator------------

      BoundaryQuality evaluateBoundaryQuality(List<mapbox.Point> points) {
  if (points.length < 3) {
    return BoundaryQuality.invalid;
  }

  // Reject self-intersections
  if (_hasSelfIntersection(points)) {
    return BoundaryQuality.invalid;
  }

  // Edge length sanity check
  int shortEdges = 0;
  for (int i = 0; i < points.length - 1; i++) {
    final a = points[i].coordinates;
    final b = points[i + 1].coordinates;

    final d = _distanceLatLng(
      a.lat.toDouble(),
      a.lng.toDouble(),
      b.lat.toDouble(),
      b.lng.toDouble(),
    );

    if (d < _minWalkDistance) {
      shortEdges++;
    }
  }

  if (shortEdges > points.length * 0.25) {
    return BoundaryQuality.warning;
  }

  // Snap-close check
  if (!_shouldSnapClose()) {
    return BoundaryQuality.good;
  }

  return BoundaryQuality.excellent;
}






            //  ------------BoundaryStatus → text------------
            String _boundaryStatusLabel(BoundaryStatus status) {
  switch (status) {
    case BoundaryStatus.empty:
      return 'No boundary points added';
    case BoundaryStatus.drafting:
      return 'Drafting boundary (add more points)';
    case BoundaryStatus.warning:
      return 'Triangle boundary (allowed, but add more corners)';
    case BoundaryStatus.valid:
      return 'Valid farmland boundary';
    case BoundaryStatus.noisy:
      return 'Too many points (check accuracy)';
  }
}
          //  -------boundary evalution output------------

          String boundaryQualityLabel(BoundaryQuality q) {
  switch (q) {
    case BoundaryQuality.invalid:
      return 'Invalid boundary';
    case BoundaryQuality.warning:
      return 'Boundary needs improvement';
    case BoundaryQuality.good:
      return 'Good boundary';
    case BoundaryQuality.excellent:
      return 'Excellent (survey-grade)';
  }
}





      // ------------ reset / undo boundary-----------


      Future<void> _undoLastPoint() async {

        if (_isBoundaryFinalized) return;

  if (_boundaryPoints.isEmpty) return;
         
         setState(() {
          _boundaryPoints.removeLast();
         });

  await _pointManager?.deleteAll();
  await _polylineManager?.deleteAll();

  // Re-draw remaining points
  for (final point in _boundaryPoints) {
    await _pointManager?.create(
      mapbox.PointAnnotationOptions(
        geometry: point,
        iconSize: 0.8,
      ),
    );
  }

  await _drawPolyline();
}

Future<void> _resetBoundary() async {
  _isBoundaryFinalized = false;


  setState(() {
    _boundaryPoints.clear();
  });

  await _pointManager?.deleteAll();
  await _polylineManager?.deleteAll();
}

        



  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Draw Land Boundary'),
      ),
      body: Stack(
        children: [
          mapbox.MapWidget(
            styleUri: mapbox.MapboxStyles.SATELLITE,
            onMapCreated: _onMapCreated,
          ),


          // ----------------small UI text widget----------------

          Padding(
  padding: const EdgeInsets.all(8.0),
  child: Text(
    _boundaryStatusLabel(_evaluateBoundaryStatus()),
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
  ),
),  



            // -----------SHOW AREA TEXT IN UI------------

            if (_canSaveBoundary())
  Padding(
    padding: const EdgeInsets.only(top: 5),
    child: Text(
      _formattedAreaText(),
      style: const TextStyle(
        fontSize: 13,
        color: Colors.green,
      ),
    ),
  ),
                    

                    // ------------READ-ONLY-------
                    if (_isBoundaryLocked)
  const Padding(
    padding: EdgeInsets.only(top: 4),
    child: Text(
      'Boundary finalized (read-only)',
      style: TextStyle(fontSize: 12, color: Colors.grey),
    ),
  ),



          /// OPTION A — ADD BOUNDRY POINT ADD BUTTON
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: ElevatedButton(
              onPressed: _isBoundaryLocked
    ? null
    : () async {
        final cameraState = await _mapboxMap.getCameraState();
        final point = mapbox.Point(
          coordinates: mapbox.Position(
            cameraState.center.coordinates.lng,
            cameraState.center.coordinates.lat,
          ),
        );
        await _addPoint(point);
      },

              child: const Text('Add Boundary Point'),
        
            ),
          ),


          // ------------Walking Mode Toggle Button------------

          Positioned(
  bottom: 160,
  right: 20,
  child: FloatingActionButton.extended(
    backgroundColor: _isWalkingMode ? Colors.red : Colors.green,
    icon: Icon(_isWalkingMode ? Icons.stop : Icons.directions_walk),
    label: Text(_isWalkingMode ? 'Stop Walking' : 'Start Walking'),
    onPressed: () async {
      if (_isWalkingMode) {
        await _stopWalkingCapture();
      } else {
        await _startWalkingCapture();
      }
      setState(() {});
    },
  ),
),



          // ------------Save Boundary” BUTTON------------


          ElevatedButton(
  onPressed: _canSaveBoundary()
      ? () {
          setState(() {
            _isBoundaryLocked = true;
          });
           debugPrint('Boundary locked (finalized)');
        }
      : null, // disabled
  child: const Text('Save Boundary'),
),


          // edit lad boundary



          Positioned(
             bottom: 80,
              left: 20,
       child: FloatingActionButton(
         heroTag: 'undo',
            backgroundColor: Colors.orange,
             onPressed: _isBoundaryLocked ? null : _undoLastPoint,
            child: const Icon(Icons.undo),
           ),
         ),

          Positioned(
          bottom: 80,
             right: 20,
             child: FloatingActionButton(
              heroTag: 'reset',
               backgroundColor: Colors.red,
               onPressed: _isBoundaryLocked ? null : _resetBoundary,
                    child: const Icon(Icons.delete),
         ),
      ),

        ],
      ),
    );
  }
}
