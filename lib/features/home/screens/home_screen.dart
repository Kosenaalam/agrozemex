import 'package:agrozemex/features/auth/screens/login_screen.dart';
import 'package:agrozemex/features/auth/services/auth_service.dart';
import 'package:agrozemex/shared/services/custom_bottom_nav.dart';
import 'package:agrozemex/shared/widget/landcardsell.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../../maps/screens/map_screen.dart';
import '../models/listing_card_model.dart';
import '../services/listing_query_service.dart';
import '../screens/listing_detail_screen.dart';
import 'dart:async';

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

  final Map<String, Widget> _miniMapCache = {};

  final TextEditingController _searchController = TextEditingController();

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final service = context.read<ListingQueryService>(); 
    service.resetPagination();
    _loadMore();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _loadMore();
      }
    });

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
        _hasMore = false; 
      } else {
        final existingIds = _listings.map((e) => e.id).toSet();
        final uniqueNew = newListings.where((e) => !existingIds.contains(e.id)).toList();
        _listings.addAll(uniqueNew);
      }
    });
  } catch (e) {
    debugPrint('LoadMore error.somethinng went wrong');
    if (mounted) {
      setState(() {
        _hasMore = false;
      });
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        title: Text('Land for sale'),
        centerTitle: true,
      
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        elevation: 4,
      ),
      body:  Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .15),
                  borderRadius: BorderRadius.circular(30), 
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) {
                    final query = value.toLowerCase().trim();
                    _debounce?.cancel();
                    _debounce = Timer(const Duration(milliseconds: 300), () {
                      final service = context.read<ListingQueryService>();
                      
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
                  style: GoogleFonts.poppins(color: Colors.black),
                  decoration: InputDecoration(
                    hintText: 'Search village / tehsil ',
                    hintStyle: GoogleFonts.poppins(color: Colors.black12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.black12),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, color: Colors.white70),
                            onPressed: _clearSearch,
                          )
                        : null, 
                  ),
                ),
                         ),
              ),          
      Expanded(
        child: _listings.isEmpty && !_isLoading
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
      ),
            ],
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
       bottomNavigationBar: const CustomBottomNav(
        currentIndex: 1,
        currentScreen: 'home',
       ),
    );
  }

  Widget _buildLandCard(BuildContext context, ListingCardModel item) {
    final double? distanceKm =
        item.distanceMeters != null ? item.distanceMeters! / 1000 : null;

    return InkWell(
    onTap: () {
  final auth = context.read<AuthService>(); 
  if (auth.user != null) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ListingDetailScreen(
          listingId: item.id,
          title: item.title,
          price: item.price,
          description: item.description,
          areaInSqMeters: item.areaInSqMeters,
          boundaryPoints: item.boundaryPoints,
          photoPaths: item.photoPaths,
        ),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please login first!")),
    );
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }
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
    _debounce?.cancel(); 
    super.dispose();
  }
}