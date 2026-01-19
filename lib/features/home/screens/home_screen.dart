// F:\agrozemex\lib\features\home\screens\home_screen.dart
// (No changes needed here—your provided version with debounce, deduping, and resets is already correct)
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../services/listing_search_service.dart';
import '../../maps/screens/map_screen.dart';
import '../models/listing_card_model.dart';
import '../services/listing_query_service.dart';
import '../screens/listing_detail_screen.dart';
import 'dart:async'; // CHANGED: Added import for Timer to support debounce

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  final List<ListingCardModel> _listings = [];
  bool _isLoading = false;
  bool _hasMore = true;

  // Mini map cache
  final Map<String, Widget> _miniMapCache = {};

  // Add a TextEditingController for better control over the search field
  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce; // CHANGED: Added Timer for debouncing search input

  @override
  void initState() {
    super.initState();
    final service = context.read<ListingQueryService>(); // CHANGED: Added this line to get service
    service.resetPagination(); // CHANGED: Added resetPagination() to force reload on screen open
    _loadMore();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _loadMore();
      }
    });

    // Listen to controller for dynamic UI changes (e.g., show clear button)
    _searchController.addListener(() {
      setState(() {});
    });
  }

  Future<void> _loadMore() async {
  if (_isLoading || !_hasMore) return;

  _isLoading = true;

  try {
    final service = context.read<ListingQueryService>();
    final newListings =
        await service.fetchNextPage(searchQuery: _searchQuery);

    if (!mounted) return;

    setState(() {
      if (newListings.isEmpty) {
        _hasMore = false; // 🔒 stop loader forever
      } else {
        // CHANGED: Added deduping by id to prevent duplicate listings
        final existingIds = _listings.map((e) => e.id).toSet();
        final uniqueNew = newListings.where((e) => !existingIds.contains(e.id)).toList();
        _listings.addAll(uniqueNew);
      }
    });
  } catch (e) {
    // 🔒 SAFETY: never hang UI
    debugPrint('LoadMore error: $e');
    if (mounted) {
      setState(() {
        _hasMore = false;
      });
    }
  } finally {
    // 🔥 GUARANTEED RELEASE
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

  // Clear search function
  void _clearSearch() {
  final service = context.read<ListingQueryService>();
  service.resetPagination();

  _searchController.clear();

  setState(() {
    _searchQuery = '';
    _listings.clear();
    _hasMore = true;
  });

  _loadMore();
}

  @override
  Widget build(BuildContext context) {
    final searchService = context.read<ListingSearchService>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15), // Subtle background for search bar
            borderRadius: BorderRadius.circular(30), // Rounded corners
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              final query = value.toLowerCase().trim();
              // CHANGED: Added debounce to prevent race conditions on fast typing
              _debounce?.cancel();
              _debounce = Timer(const Duration(milliseconds: 300), () {
                // 1. Get the service
                final service = context.read<ListingQueryService>();
                
                // 2. CRITICAL: Reset the cursor so the new search starts fresh
                service.resetPagination();
                setState(() {
                  _searchQuery = query;
                  _listings.clear();
                  _hasMore = true;
                  _isLoading = false;
                  
                });
                _loadMore();
              });
            },
            style: GoogleFonts.poppins(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search village / tehsil / highway',
              hintStyle: GoogleFonts.poppins(color: Colors.white70),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              prefixIcon: const Icon(Icons.search, color: Colors.white),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: Colors.white70),
                      onPressed: _clearSearch,
                    )
                  : null, // Dynamic clear button
            ),
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)), // Curved bottom for AppBar
        ),
        elevation: 4, // Slight elevation for depth
      ),
      body: _listings.isEmpty && !_isLoading
          ? const Center(child: Text('No listings found'))
          : GridView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _listings.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _listings.length) {
                  return const Center(child: CircularProgressIndicator());
                }
                return _buildLandCard(context, _listings[index]);
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const MapScreen()),
          );
        },
        backgroundColor: const Color(0xFF0D47A1),
        child: const Icon(Icons.add_location_alt, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildLandCard(BuildContext context, ListingCardModel item) {
    final double? distanceKm =
        item.distanceMeters != null ? item.distanceMeters! / 1000 : null;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ListingDetailScreen(
              title: item.title,
              price: item.price,
              description: item.description,
              areaInSqMeters: item.areaInSqMeters,
              boundaryPoints: item.boundaryPoints,
              photoPaths: item.photoPaths,
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _buildMiniMap(item.id, item.boundaryPoints),
              ),
              const SizedBox(height: 7),
              Text(
                item.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '₹ ${item.price.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (distanceKm != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.place, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${distanceKm.toStringAsFixed(1)} km away',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              Text(
                '${item.areaInSqMeters.toStringAsFixed(2)} sq m',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniMap(
    String listingId,
    List<mapbox.Point> boundaryPoints,
  ) {
    if (_miniMapCache.containsKey(listingId)) {
      return _miniMapCache[listingId]!;
    }

    if (boundaryPoints.length < 3) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('Boundary not available')),
      );
    }

    final widget = SizedBox(
      height: 95,
      child: mapbox.MapWidget(
        key: ValueKey('mini_map_$listingId'),
        styleUri: mapbox.MapboxStyles.SATELLITE_STREETS,
        cameraOptions: mapbox.CameraOptions(
          center: boundaryPoints.first,
          zoom: 15,
        ),
        onMapCreated: (controller) async {
          final polygonManager =
              await controller.annotations.createPolygonAnnotationManager();

          final ring = [
            ...boundaryPoints.map((p) => p.coordinates),
            boundaryPoints.first.coordinates,
          ];

          await polygonManager.create(
            mapbox.PolygonAnnotationOptions(
              geometry: mapbox.Polygon(coordinates: [ring]),
              fillColor: 0xFF0D47A1,
              fillOpacity: 0.35,
            ),
          );
        },
      ),
    );

    _miniMapCache[listingId] = widget;
    return widget;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel(); // CHANGED: Added cancel to clean up debounce timer
    super.dispose();
  }
}