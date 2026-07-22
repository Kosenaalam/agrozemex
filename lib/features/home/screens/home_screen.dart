import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/auth/screens/login_screen.dart';
import 'package:agrozemex/features/auth/screens/profile_screen_dash.dart';
import 'package:agrozemex/features/auth/services/auth_service.dart';
import 'package:agrozemex/features/navigation/main_navigation_shell.dart';
import '../../maps/screens/map_screen.dart';
import '../models/listing_card_model.dart';
import '../services/listing_query_service.dart';
import '../screens/listing_detail_screen.dart';

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

  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    final service = context.read<ListingQueryService>();
    service.resetPagination();
    _loadMore();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
              _scrollController.position.maxScrollExtent - 200 &&
          !_isLoading &&
          _hasMore) {
        _loadMore();
      }
    });
    // PERF FIX: Removed setState() from addListener. Clear button is now driven
    // by ValueListenableBuilder to avoid full 825-line widget rebuild on every keystroke.
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
          final uniqueNew =
              newListings.where((e) => !existingIds.contains(e.id)).toList();
          _listings.addAll(uniqueNew);
        }
      });
    } catch (e) {
      debugPrint('LoadMore error. Something went wrong: $e');
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
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onCardTap(ListingCardModel item) {
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
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    return Scaffold(
      backgroundColor: AgroZemexTokens.surface,
      // PERF FIX: Replaced BackdropFilter (GPU-blocking ImageFilter.blur sigma=20 on every
      // frame) with a plain semi-transparent Container. BackdropFilter was the #1 cause of
      // scroll-related ANR on mid-range devices. Visual is preserved via border + shadow.
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: RepaintBoundary(
          child: Container(
            decoration: BoxDecoration(
              color: AgroZemexTokens.surface.withValues(alpha: 0.97),
              border: Border(
                bottom: BorderSide(
                  color: AgroZemexTokens.onSurfaceVariant.withValues(alpha: 0.08),
                ),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.04),
                  blurRadius: 12,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.menu, color: AgroZemexTokens.primary),
                onPressed: () {},
              ),
              title: Text(
                'AgroZemex',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AgroZemexTokens.primary,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
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
                    margin: const EdgeInsets.only(right: 16),
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AgroZemexTokens.surfaceContainerLow,
                        width: 2,
                      ),
                      image: DecorationImage(
                        image: auth.user?.photoURL != null
                            ? ResizeImage(
                                NetworkImage(auth.user!.photoURL!),
                                width: 100,
                                height: 100,
                              ) as ImageProvider
                            : const AssetImage(AppAssets.defaultAvatar),
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
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Floating Search & Filter Pill Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AgroZemexTokens.marginMobile),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                  boxShadow: AgroZemexTokens.softShadows,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.search,
                      color: AgroZemexTokens.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          final query = value.toLowerCase().trim();
                          _debounce?.cancel();
                          _debounce =
                              Timer(const Duration(milliseconds: 300), () {
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
                        style: GoogleFonts.inter(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search location, village or tehsil...',
                          hintStyle: GoogleFonts.inter(
                            color: AgroZemexTokens.onSurfaceVariant,
                            fontSize: 14,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                        ),
                      ),
                    ),
                    // PERF FIX: ValueListenableBuilder only rebuilds the clear
                    // button widget, not the entire 825-line HomeScreen
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _searchController,
                      builder: (context, value, child) {
                        return value.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: _clearSearch,
                              )
                            : const SizedBox.shrink();
                      },
                    ),
                    Container(
                      width: 1,
                      height: 24,
                      color: AgroZemexTokens.surfaceContainerLow,
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.tune,
                        color: AgroZemexTokens.primary,
                        size: 20,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Dynamic Bento Property Grid
          if (_listings.isEmpty && !_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Text(
                  'No listings found',
                  style: AgroZemexTokens.bodyLarge,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(
                horizontal: AgroZemexTokens.marginMobile,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index == _listings.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24.0),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    // Render Map Callout Banner after 3rd item
                    if (index == 3) {
                      return Column(
                        children: [
                          _buildMapCalloutTile(context),
                          const SizedBox(height: 16),
                          _buildPropertyCard(context, _listings[index]),
                        ],
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: _buildPropertyCard(context, _listings[index]),
                    );
                  },
                  childCount: _listings.length + (_isLoading ? 1 : 0),
                ),
              ),
            ),

          // Load More Button
          if (_hasMore && !_isLoading && _listings.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Center(
                  child: OutlinedButton(
                    onPressed: _loadMore,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: AgroZemexTokens.radiusEight,
                      ),
                      side: const BorderSide(
                        color: AgroZemexTokens.onSurfaceVariant,
                      ),
                    ),
                    child: Text(
                      'Load More Properties',
                      style: AgroZemexTokens.bodyLarge.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 48)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          final shell = MainNavigationShell.of(context);
          if (shell != null) {
            shell.switchTab(2);
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MapScreen()),
            );
          }
        },
        backgroundColor: AgroZemexTokens.primary,
        child: const Icon(Icons.map, color: Colors.white, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildPropertyCard(BuildContext context, ListingCardModel item) {
    final double? distanceKm =
        item.distanceMeters != null ? item.distanceMeters! / 1000 : null;

    final bool hasImage = item.photoPaths.isNotEmpty;

    return GestureDetector(
      onTap: () => _onCardTap(item),
      child: Container(
        height: 320,
        decoration: BoxDecoration(
          borderRadius: AgroZemexTokens.radiusLargeCard,
          boxShadow: AgroZemexTokens.softShadows,
        ),
        child: ClipRRect(
          borderRadius: AgroZemexTokens.radiusLargeCard,
          child: Stack(
            fit: StackFit.expand,
            children: [
              hasImage
                  ? Image.network(
                      item.photoPaths.first,
                      fit: BoxFit.cover,
                      cacheHeight: 640,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AgroZemexTokens.surfaceContainerLow,
                        child: const Icon(
                          Icons.landscape,
                          color: AgroZemexTokens.onSurfaceVariant,
                          size: 48,
                        ),
                      ),
                    )
                  : Image.asset(
                      AppAssets.defaultLand,
                      fit: BoxFit.cover,
                    ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.8),
                      Colors.black.withValues(alpha: 0.1),
                      Colors.transparent,
                    ],
                  ),
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Pills & Favorite
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
                          color: AgroZemexTokens.primary.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'ARABLE',
                          style: AgroZemexTokens.labelCaps.copyWith(
                            color: Colors.white,
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
                          color: Colors.white.withValues(alpha: 0.8),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'PREMIUM',
                          style: AgroZemexTokens.labelCaps.copyWith(
                            color: AgroZemexTokens.onSurface,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite_border,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),

              // Title, Specs & Price
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AgroZemexTokens.headlineMedium.copyWith(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        distanceKm != null
                            ? '${distanceKm.toStringAsFixed(1)} km away'
                            : 'Bordeaux Region',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.straighten,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.areaInSqMeters.toStringAsFixed(0)} sq m',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹ ${item.price.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
    );
  }

  Widget _buildMapCalloutTile(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AgroZemexTokens.surfaceContainerLow,
        borderRadius: AgroZemexTokens.radiusLargeCard,
        border: Border.all(color: AgroZemexTokens.surfaceContainerLow),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.explore,
            size: 40,
            color: AgroZemexTokens.primary,
          ),
          const SizedBox(height: 8),
          Text(
            'Map View Available',
            style: AgroZemexTokens.headlineMedium.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Switch to satellite view to explore boundaries and topology.',
            textAlign: TextAlign.center,
            style: AgroZemexTokens.bodyLarge.copyWith(
              fontSize: 13,
              color: AgroZemexTokens.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen()),
              );
            },
            icon: const Icon(Icons.map, size: 18),
            label: Text(
              'Toggle Map',
              style: AgroZemexTokens.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AgroZemexTokens.primary,
              shape: RoundedRectangleBorder(
                borderRadius: AgroZemexTokens.radiusEight,
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
PREVIOUS HOME SCREEN CODE (PRESERVED IN COMMENTED FORM AS REQUESTED)
================================================================================

import 'package:agrozemex/features/auth/screens/login_screen.dart';
import 'package:agrozemex/features/auth/services/auth_service.dart';
import 'package:agrozemex/shared/services/custom_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../../maps/screens/map_screen.dart';
import '../models/listing_card_model.dart';
import '../services/listing_query_service.dart';
import '../screens/listing_detail_screen.dart';
import 'dart:async';

class _OldHomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();
  final List<ListingCardModel> _listings = [];
  bool _isLoading = false;
  bool _hasMore = true;

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
}
================================================================================
*/