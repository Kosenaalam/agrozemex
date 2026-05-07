import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

import '../models/listing_card_model.dart';
import '../services/listing_query_service.dart';

class _MapCluster {
  final double minLat;
  final double minLng;
  final double maxLat;
  final double maxLng;
  final int count;

  _MapCluster({
    required this.minLat,
    required this.minLng,
    required this.maxLat,
    required this.maxLng,
    required this.count,
  });
}

class BuyerMapScreen extends StatefulWidget {
  const BuyerMapScreen({super.key});

  @override
  State<BuyerMapScreen> createState() => _BuyerMapScreenState();
}

class _BuyerMapScreenState extends State<BuyerMapScreen> {
  mapbox.MapboxMap? _map;
  mapbox.PolygonAnnotationManager? _polygonManager;
  mapbox.CircleAnnotationManager? _circleManager;

  static const double _gridSize = 0.02; 
  final List<_MapCluster> _clusters = [];
  bool _rendered = false;

  // MAP CREATED
  Future<void> _onMapCreated(mapbox.MapboxMap controller) async {
    _map = controller;

    _polygonManager =
        await controller.annotations.createPolygonAnnotationManager();
    _circleManager =
        await controller.annotations.createCircleAnnotationManager();

    if (!mounted) return;

    final listings =
        await context.read<ListingQueryService>().fetchNextPage();

    await _renderWithClustering(listings);
  }

  // TAP HANDLER (SCREEN → GEO)
  Future<void> _handleMapTap(mapbox.MapContentGestureContext context) async {
    if (_map == null) return;

    final lat = context.point.coordinates.lat;
    final lng = context.point.coordinates.lng;

    for (final cluster in _clusters) {
      final insideLat = lat >= cluster.minLat && lat <= cluster.maxLat;
      final insideLng = lng >= cluster.minLng && lng <= cluster.maxLng;

      if (insideLat && insideLng) {
        await _zoomIntoCluster(cluster);
        break;
      }
    }
  }

  // CLUSTER LOGIC
  Future<void> _renderWithClustering(List<ListingCardModel> listings) async {
    if (_rendered) return;

    final clusters = <String, List<ListingCardModel>>{};
    _clusters.clear();

    for (final item in listings) {
      if (item.centerLat == null || item.centerLng == null) continue;

      final gx = (item.centerLat! / _gridSize).floor();
      final gy = (item.centerLng! / _gridSize).floor();
      final key = '$gx:$gy';

      clusters.putIfAbsent(key, () => []).add(item);
    }

    for (final entry in clusters.entries) {
      final items = entry.value;

      if (items.length == 1) {
        await _drawPolygon(items.first);
      } else {
        await _drawCluster(items);
      }
    }

    _rendered = true;
  }

  // DRAW SINGLE POLYGON
  Future<void> _drawPolygon(ListingCardModel item) async {
    if (_polygonManager == null) return;
    if (item.boundaryPoints.length < 3) return;

    final ring = [
      ...item.boundaryPoints.map((p) => p.coordinates),
      item.boundaryPoints.first.coordinates,
    ];

    await _polygonManager!.create(
      mapbox.PolygonAnnotationOptions(
        geometry: mapbox.Polygon(coordinates: [ring]),
        fillColor: 0xFF0D47A1,
        fillOpacity: 0.35,
      ),
    );
  }

  // DRAW CLUSTER
  Future<void> _drawCluster(List<ListingCardModel> items) async {
    if (_circleManager == null) return;

    final lats = items.map((e) => e.centerLat!).toList();
    final lngs = items.map((e) => e.centerLng!).toList();

    final minLat = lats.reduce((a, b) => a < b ? a : b);
    final maxLat = lats.reduce((a, b) => a > b ? a : b);
    final minLng = lngs.reduce((a, b) => a < b ? a : b);
    final maxLng = lngs.reduce((a, b) => a > b ? a : b);

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;

    _clusters.add(
      _MapCluster(
        minLat: minLat,
        minLng: minLng,
        maxLat: maxLat,
        maxLng: maxLng,
        count: items.length,
      ),
    );

    await _circleManager!.create(
      mapbox.CircleAnnotationOptions(
        geometry: mapbox.Point(
          coordinates: mapbox.Position(centerLng, centerLat),
        ),
        circleRadius: (items.length * 4).clamp(18, 40).toDouble(),
        circleColor: 0xFF0D47A1,
        circleOpacity: 0.85,
      ),
    );
  }

  // ZOOM INTO CLUSTER
  Future<void> _zoomIntoCluster(_MapCluster cluster) async {
    if (_map == null) return;

    final currentZoom = (await _map!.getCameraState()).zoom;

    await _map!.setCamera(
      mapbox.CameraOptions(
        center: mapbox.Point(
          coordinates: mapbox.Position(
            (cluster.minLng + cluster.maxLng) / 2,
            (cluster.minLat + cluster.maxLat) / 2,
          ),
        ),
        zoom: currentZoom + 2,
      ),
    );

    _rendered = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearby Lands'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: mapbox.MapWidget(
        styleUri: mapbox.MapboxStyles.SATELLITE_STREETS,
        onMapCreated: _onMapCreated,
        onTapListener: _handleMapTap,
      ),
    );
  }
}