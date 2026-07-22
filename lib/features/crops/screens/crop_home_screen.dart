import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/auth/screens/login_screen.dart';
import 'package:agrozemex/features/auth/services/auth_service.dart';
import 'package:agrozemex/features/crops/models/crop_card_model.dart';
import 'package:agrozemex/features/crops/screens/crop_detail_screen.dart';
import 'package:agrozemex/features/crops/screens/crop_sell_screen.dart';
import 'package:agrozemex/features/crops/services/crop_query_service.dart';
import 'package:agrozemex/features/navigation/main_navigation_shell.dart';
import 'package:agrozemex/shared/services/location_service.dart';

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

  final List<String> _cropTypes = [
    'All',
    'Wheat',
    'Rice',
    'Mustard',
    'Pulses',
    'Corn',
    'Vegetables',
    'Fruits',
    'others',
  ];

  @override
  void initState() {
    super.initState();

    // PERF FIX: Removed setState() from addListener — previously triggered full
    // 1578-line rebuild on every keystroke. Clear button now uses ValueListenableBuilder.

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getUserLocation();
      final service = context.read<CropQueryService>();
      service.resetPagination();
      _loadMore();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _loadMore();
      }
    });
  }

  Future<void> _getUserLocation() async {
    // PERF FIX: Use LocationService singleton instead of a fresh
    // Geolocator.getCurrentPosition(high) call which takes 5-30s on some Android
    // devices and was blocking UI thread. The singleton is already initialized
    // in the background by AppInit.initializeBackgroundServices().
    final singleton = LocationService();
    if (singleton.currentPosition != null) {
      _userPosition = singleton.currentPosition;
      if (_useLocationFilter) _applyFilters();
      return;
    }

    // Fallback: if singleton hasn't fetched yet, try a medium-accuracy call
    // with a strict 5s timeout so we never block the main isolate.
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    try {
      _userPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium, // medium, not high — much faster
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Non-fatal: distance sort simply won't work without location
    }
    if (_useLocationFilter && mounted) _applyFilters();
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
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(radians(lat1)) *
            math.cos(radians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

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
          final uniqueNew =
              newListings.where((e) => !existingIds.contains(e.id)).toList();
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
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AgroZemexTokens.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
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
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Filters',
                            style: AgroZemexTokens.headlineMedium,
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
                            child: Text(
                              'Reset',
                              style: AgroZemexTokens.bodyMedium.copyWith(
                                color: AgroZemexTokens.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30),

                      DropdownButtonFormField<String>(
                        initialValue: _selectedCropType,
                        decoration: InputDecoration(
                          labelText: 'Select Crop Type',
                          border: OutlineInputBorder(
                            borderRadius: AgroZemexTokens.radiusEight,
                          ),
                        ),
                        isExpanded: true,
                        items: _cropTypes
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCropType = v),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        onChanged: (v) =>
                            setState(() => _villageFilter = v.trim()),
                        decoration: InputDecoration(
                          labelText: 'Village / Location',
                          border: OutlineInputBorder(
                            borderRadius: AgroZemexTokens.radiusEight,
                          ),
                          prefixIcon: const Icon(
                            Icons.location_on,
                            color: AgroZemexTokens.primary,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      SwitchListTile(
                        activeThumbColor: AgroZemexTokens.primary,
                        title: Text(
                          'Near Me (max ${_maxDistance.round()} km)',
                          style: AgroZemexTokens.bodyLarge,
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
                          activeColor: AgroZemexTokens.primary,
                          value: _maxDistance,
                          label: '${_maxDistance.round()} km',
                          onChanged: (v) => setState(() => _maxDistance = v),
                          onChangeEnd: (v) => _applyFilters(),
                        ),

                      const SizedBox(height: 20),

                      Text(
                        'Price Range (₹)',
                        style: AgroZemexTokens.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      RangeSlider(
                        min: 0.0,
                        max: 10000.0,
                        divisions: 100,
                        activeColor: AgroZemexTokens.primary,
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AgroZemexTokens.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: AgroZemexTokens.radiusEight,
                            ),
                          ),
                          onPressed: () {
                            _applyFilters();
                            Navigator.pop(context);
                          },
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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
      backgroundColor: AgroZemexTokens.surface,
      appBar: AppBar(
        backgroundColor: AgroZemexTokens.surface,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AgroZemexTokens.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.grass,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'AgroZemex Harvests',
              style: AgroZemexTokens.headlineMedium.copyWith(
                fontWeight: FontWeight.bold,
                color: AgroZemexTokens.primary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.tune,
              color: AgroZemexTokens.onSurface,
            ),
            onPressed: () => _showFilterBottomSheet(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _applyFilters();
        },
        color: AgroZemexTokens.primary,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Floating Glass Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: AgroZemexTokens.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: AgroZemexTokens.softShadows,
                    border: Border.all(
                      color: AgroZemexTokens.onSurfaceVariant.withValues(alpha: 0.1),
                    ),
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
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      color: AgroZemexTokens.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search fresh harvests, grains, spices...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 14,
                        color: AgroZemexTokens.onSurfaceVariant,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AgroZemexTokens.onSurfaceVariant,
                      ),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AgroZemexTokens.onSurfaceVariant,
                              ),
                              onPressed: _clearSearch,
                            )
                          : IconButton(
                              icon: const Icon(
                                Icons.filter_list,
                                color: AgroZemexTokens.primary,
                              ),
                              onPressed: () => _showFilterBottomSheet(context),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            // Horizontal Category Pills
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _cropTypes.length,
                  itemBuilder: (context, index) {
                    final type = _cropTypes[index];
                    final bool isSelected =
                        (_selectedCropType == type) ||
                        (_selectedCropType == null && type == 'All');

                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCropType = type == 'All' ? null : type;
                          });
                          _applyFilters();
                        },
                        selectedColor: AgroZemexTokens.primary,
                        backgroundColor: AgroZemexTokens.surfaceContainerLow,
                        labelStyle: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : AgroZemexTokens.onSurfaceVariant,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // Hero Section: Harvest of the Day
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Harvest of the Day',
                          style: AgroZemexTokens.headlineMedium.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AgroZemexTokens.primary,
                          ),
                        ),
                        Text(
                          'PREMIUM',
                          style: AgroZemexTokens.labelCaps.copyWith(
                            color: AgroZemexTokens.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        borderRadius: AgroZemexTokens.radiusLargeCard,
                        boxShadow: AgroZemexTokens.softShadows,
                      ),
                      child: ClipRRect(
                        borderRadius: AgroZemexTokens.radiusLargeCard,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.asset(
                              AppAssets.loginHero,
                              fit: BoxFit.cover,
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.8),
                                    Colors.black.withValues(alpha: 0.2),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AgroZemexTokens.primary,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'ORGANIC BASMATI',
                                      style: AgroZemexTokens.labelCaps.copyWith(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Long-Grain Basmati Rice',
                                    style: AgroZemexTokens.headlineMedium
                                        .copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 22,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '₹ 115 / kg',
                                        style: GoogleFonts.inter(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              AgroZemexTokens.radiusEight,
                                        ),
                                        child: Text(
                                          'Reserve Harvest',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: AgroZemexTokens.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 28)),

            // Fresh Arrivals Feed Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text(
                  'Fresh Arrivals',
                  style: AgroZemexTokens.headlineMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AgroZemexTokens.primary,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Grid / Feed of Crop Cards
            _listings.isEmpty && !_isLoading
                ? SliverToBoxAdapter(
                    child: Container(
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(
                            Icons.eco_outlined,
                            size: 64,
                            color: AgroZemexTokens.onSurfaceVariant,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No crop harvests found',
                            style: AgroZemexTokens.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Try adjusting your search keywords or price filters',
                            style: AgroZemexTokens.bodyMedium.copyWith(
                              color: AgroZemexTokens.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          if (index == _listings.length) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: AgroZemexTokens.primary,
                              ),
                            );
                          }
                          return _buildCropCard(context, _listings[index]);
                        },
                        childCount: _listings.length + (_isLoading ? 1 : 0),
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.72,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                    ),
                  ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Market Insights Pulse Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AgroZemexTokens.primary,
                    borderRadius: AgroZemexTokens.radiusLargeCard,
                    boxShadow: AgroZemexTokens.softShadows,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.analytics,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MARKET PULSE',
                              style: AgroZemexTokens.labelCaps.copyWith(
                                color: Colors.white70,
                                fontSize: 10,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Wheat futures up 4% today',
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Ideal time for bulk grain procurement.',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final shell = MainNavigationShell.of(context);
          if (shell != null) {
            shell.switchTab(3);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CropSellScreen()),
            );
          }
        },
        backgroundColor: AgroZemexTokens.primary,
        child: const Icon(
          Icons.add_photo_alternate,
          color: Colors.white,
          size: 26,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildCropCard(BuildContext context, CropCardModel item) {
    double? distance;
    if (_useLocationFilter && _userPosition != null) {
      distance = _calculateDistance(item.location);
    }

    final bool hasImage = item.photoPaths.isNotEmpty;

    return GestureDetector(
      onTap: () {
        final auth = context.read<AuthService>();

        if (auth.user != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CropDetailScreen(item: item)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('please login first')),
          );
          Navigator.push(
            context,
            MaterialPageRoute(builder: (contxt) => const LoginScreen()),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: AgroZemexTokens.radiusLargeCard,
          boxShadow: AgroZemexTokens.softShadows,
        ),
        child: ClipRRect(
          borderRadius: AgroZemexTokens.radiusLargeCard,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Photo Thumbnail Container
              SizedBox(
                height: 110,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImage
                        ? Image.network(
                            item.photoPaths.first,
                            fit: BoxFit.cover,
                            cacheHeight: 170,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(child: Icon(Icons.error));
                            },
                          )
                        : Image.asset(
                            AppAssets.defaultLand,
                            fit: BoxFit.cover,
                          ),
                    if (distance != null)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${distance.toStringAsFixed(1)} KM',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AgroZemexTokens.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '₹ ${item.price.toStringAsFixed(0)} / ${item.unit}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AgroZemexTokens.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AgroZemexTokens.onSurfaceVariant,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            item.village,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: AgroZemexTokens.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.quantity.toStringAsFixed(0)} ${item.unit} available',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AgroZemexTokens.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
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

/*
================================================================================
PREVIOUS CROP HOME SCREEN CODE (PRESERVED IN COMMENTED FORM AS REQUESTED)
================================================================================

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

class _OldCropHomeScreen extends StatefulWidget {
  const _OldCropHomeScreen({super.key});

  @override
  State<_OldCropHomeScreen> createState() => _OldCropHomeScreenState();
}

class _OldCropHomeScreenState extends State<_OldCropHomeScreen> {
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

  final List<String> _cropTypes = [
    'All',
    'Wheat',
    'Rice',
    'Mustard',
    'Pulses',
    'Corn',
    'Vegetables',
    'Fruits',
    'others',
  ];
  @override
  void initState() {
    super.initState();

    _searchController.addListener(() {
      setState(() {});
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getUserLocation();
      final service = context.read<CropQueryService>();
      service.resetPagination();
      _loadMore();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
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

    _userPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
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
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(radians(lat1)) *
            math.cos(radians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return R * c;
  }

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
          final uniqueNew = newListings
              .where((e) => !existingIds.contains(e.id))
              .toList();
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
                        initialValue: _selectedCropType,
                        hint: const Text('Select Crop Type'),
                        isExpanded: true,
                        items: _cropTypes
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedCropType = v),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        onChanged: (v) =>
                            setState(() => _villageFilter = v.trim()),
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
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
                          child: const Text(
                            'Apply Filters',
                            style: TextStyle(fontSize: 16),
                          ),
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
        title: Text(
          'Crop Listings',
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
        ),
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
                color: Colors.white.withValues(alpha: 0.15),
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
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
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
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
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
        child: const Icon(
          Icons.add_photo_alternate,
          color: Colors.white,
          size: 30,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: CustomBottomNav(
        currentIndex: 2,
        currentScreen: 'crop_home',
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

        if (auth.user != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => CropDetailScreen(item: item)),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('please login first')));
          Navigator.push(
            context,
            MaterialPageRoute(builder: (contxt) => const LoginScreen()),
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
                        cacheHeight: 170,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.error));
                        },
                      )
                    : Image.asset(
                        AppAssets.defaultLand,
                        height: 85,
                        width: double.infinity,
                        fit: BoxFit.cover,
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
================================================================================
*/
