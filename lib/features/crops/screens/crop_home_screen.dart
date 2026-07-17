import 'dart:async';
import 'package:agrozemex/features/auth/screens/login_screen.dart';
import 'package:agrozemex/features/auth/services/auth_service.dart';
import 'package:agrozemex/features/crops/screens/crop_sell_screen.dart';
import 'package:agrozemex/shared/services/custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/crop_query_service.dart';
import '../models/crop_card_model.dart';
import 'crop_detail_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

class CropHomeScreen extends StatefulWidget {
  const CropHomeScreen({super.key});

  @override
  State<CropHomeScreen> createState() => _CropHomeScreenState();
}

class _CropHomeScreenState extends State<CropHomeScreen> {
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  final List<CropCardModel> _listings = [];
  bool _isLoading = false;
  bool _hasMore = true;

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  String? _selectedCropType;
  double _minPrice = 0.0;
  double _maxPrice = 10000.0;
  String _villageFilter = ''; 
  double _maxDistance = 50.0;
  Position? _userPosition; 
  bool _useLocationFilter = false; 

  final List<String> _cropTypes = ['All', 'Wheat', 'Rice', 'Mustard', 'Pulses', 'Corn', 'Vegetables', 'Fruits', 'others'];
@override
void initState() {
  super.initState();
  
  _searchController.addListener(() {
    setState(() {});
  });

  // Safe way to call after build
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _getUserLocation();
    final service = context.read<CropQueryService>();
    service.resetPagination();
    _loadMore();
  });

  _scrollController.addListener(() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading && _hasMore) {
      _loadMore();
    }
  });
}

  Future<void> _getUserLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    _userPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (_useLocationFilter) _applyFilters(); 
  }

  double _calculateDistance(GeoPoint cropLocation) {
    if (_userPosition == null) return double.infinity;

    final double lat1 = _userPosition!.latitude;
    final double lon1 = _userPosition!.longitude;
    final double lat2 = cropLocation.latitude;
    final double lon2 = cropLocation.longitude;

    const R = 6371; 
    final dLat = radians(lat2 - lat1);
    final dLon = radians(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
              math.cos(radians(lat1)) * math.cos(radians(lat2)) *
              math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }
  //  distance helper
       double radians(double degrees) => degrees * (math.pi / 180);

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;

    try {
      final service = context.read<CropQueryService>();
      final newListings = await service.fetchNextPage(
        searchQuery: _searchQuery,
        cropType: _selectedCropType != 'All' ? _selectedCropType : null,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        village: _villageFilter.isNotEmpty ? _villageFilter : null, 
      );

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
      debugPrint('Crop load error. please check internet connection');
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

  void _applyFilters() {
    final service = context.read<CropQueryService>();
    service.resetPagination();
    setState(() {
      _listings.clear();
      _hasMore = true;
    });
    _loadMore();
  }

  void _clearSearch() {
    final service = context.read<CropQueryService>();
    service.resetPagination();
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      _listings.clear();
      _hasMore = true;
    });
    _loadMore();
  }
 void _showFilterBottomSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,     
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Filters',
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _selectedCropType = null;
                              _villageFilter = '';
                              _useLocationFilter = false;
                              _maxDistance = 50;
                              _minPrice = 0;
                              _maxPrice = 10000;
                            });
                            Navigator.pop(context);
                            _applyFilters();
                          },
                          child: const Text('Reset'),
                        ),
                      ],
                    ),
                    const Divider(height: 30),

                    DropdownButtonFormField<String>(
                      value: _selectedCropType,
                      hint: const Text('Select Crop Type'),
                      isExpanded: true,
                      items: _cropTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (v) => setState(() => _selectedCropType = v),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      onChanged: (v) => setState(() => _villageFilter = v.trim()),
                      decoration: const InputDecoration(
                        labelText: 'Village / Location',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),

                    const SizedBox(height: 20),

                    SwitchListTile(
                      title: Text(
                        'Near Me (max ${_maxDistance.round()} km)',
                        style: GoogleFonts.poppins(),
                      ),
                      value: _useLocationFilter,
                      onChanged: (v) async {
                        setState(() => _useLocationFilter = v);
                        if (v && _userPosition == null) {
                          await _getUserLocation();
                        }
                      },
                    ),

                    if (_useLocationFilter)
                      Slider(
                        min: 0.0,
                        max: 100.0,
                        value: _maxDistance,
                        label: '${_maxDistance.round()} km',
                        onChanged: (v) => setState(() => _maxDistance = v),
                        onChangeEnd: (v) => _applyFilters(),
                      ),

                    const SizedBox(height: 20),

                    Text(
                      'Price Range (₹)',
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    RangeSlider(
                      min: 0.0,
                      max: 10000.0,
                      divisions: 100,
                      values: RangeValues(_minPrice, _maxPrice),
                      labels: RangeLabels(
                        '₹${_minPrice.round()}',
                        '₹${_maxPrice.round()}',
                      ),
                      onChanged: (values) {
                        setState(() {
                          _minPrice = values.start;
                          _maxPrice = values.end;
                        });
                      },
                    ),

                    const SizedBox(height: 30),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          _applyFilters();
                          Navigator.pop(context);
                        },
                        child: const Text('Apply Filters', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
        title: Text('Crop Listings', style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
        elevation: 4,
actions: [
  ElevatedButton.icon(
    icon: const Icon(Icons.filter_list_rounded, size: 28),
    label: Text('Filter'),
    onPressed: () => _showFilterBottomSheet(context),
  ),
],
      ),
      body: Column(
            children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha:0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                final query = value.toLowerCase().trim();
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  final service = context.read<CropQueryService>();
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
              style: GoogleFonts.poppins(color: Colors.black87),
              decoration: InputDecoration(
                hintText: 'Search crop type / name',
                hintStyle: GoogleFonts.poppins(color: Colors.black38),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.black38),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.black54),
                        onPressed: _clearSearch,
                      )
                    : null,
              ),
            ),
                    ),
          ),
     
          Expanded(
            child: _listings.isEmpty && !_isLoading
                ? const Center(child: Text('No crops found'))
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
                      return _buildCropCard(context, _listings[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CropSellScreen()),
          );
        },
        backgroundColor: const Color(0xFF0D47A1),
        child: const Icon(Icons.add_photo_alternate, color: Colors.white, size: 30),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        currentScreen: 'crop_home',
     //  ),
      ),
    );
  }

  Widget _buildCropCard(BuildContext context, CropCardModel item) {
    double? distance;
    if (_useLocationFilter && _userPosition != null) {
      distance = _calculateDistance(item.location);
    }
    return InkWell(
      onTap: () {
        final auth = context.read<AuthService>();

        if (auth.user != null){
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CropDetailScreen(item: item),
          ),
        );
      
      }else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('please login first')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (contxt) => const LoginScreen ()),
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
                child: item.photoPaths.isNotEmpty
                    ? Image.network(
                        item.photoPaths.first,
                        height: 85,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.error));
                        },
                      )
                    : const SizedBox(
                        height: 85,
                        child: Center(child: Text('No photo')),
                      ),
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
                '₹ ${item.price.toStringAsFixed(0)} / ${item.unit}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${item.quantity.toStringAsFixed(2)} ${item.unit}',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
              // Text(
              //   item.cropType,
              //   style: GoogleFonts.poppins(fontSize: 13, color: Colors.grey[700]),
              // ),
              // Text(
              //   'Location: ${item.village}', 
              //   style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
              // ),
              if (distance != null) 
                Text(
                  '${distance.toStringAsFixed(1)} km away',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}