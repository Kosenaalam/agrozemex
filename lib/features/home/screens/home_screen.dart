import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/auth/screens/login_screen.dart';
import 'package:agrozemex/features/auth/screens/profile_screen_dash.dart';
import 'package:agrozemex/features/auth/services/auth_service.dart';
import 'package:agrozemex/features/legal/screens/about_us_screen.dart';
import 'package:agrozemex/features/legal/screens/help_support_screen.dart';
import 'package:agrozemex/features/legal/screens/policies_screen.dart';
import 'package:agrozemex/features/legal/screens/terms_conditions_screen.dart';
import 'package:agrozemex/features/navigation/main_navigation_shell.dart';
import '../../maps/screens/map_screen.dart';
import '../models/listing_card_model.dart';
import '../models/listing_filter_model.dart';
import '../services/listing_query_service.dart';
import '../screens/listing_detail_screen.dart';
import 'package:agrozemex/shared/services/wishlist_service.dart';
import 'package:agrozemex/shared/widget/land_card_shimmer.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  ListingFilterModel _filter = ListingFilterModel.empty;

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
      final newListings = await service.fetchNextPage(
        searchQuery: _searchQuery,
        filter: _filter,
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

  Future<void> _onRefresh() async {
    final service = context.read<ListingQueryService>();
    service.resetPagination();
    setState(() {
      _listings.clear();
      _hasMore = true;
      _isLoading = false;
    });
    await _loadMore();
  }

  void _clearSearch() {
    final service = context.read<ListingQueryService>();
    service.resetPagination();

    _searchController.clear();

    setState(() {
      _searchQuery = '';
      _filter = ListingFilterModel.empty;
      _listings.clear();
      _hasMore = true;
    });

    _loadMore();
  }

  void _applyFilters(ListingFilterModel newFilter) {
    final service = context.read<ListingQueryService>();
    service.resetPagination();

    setState(() {
      _filter = newFilter;
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
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final List<String> soilTypes = [
              'All',
              'Alluvial',
              'Black',
              'Clay',
              'Loam',
              'Sandy',
            ];
            final List<String> waterSources = [
              'All',
              'Well',
              'Canal',
              'Borewell',
              'Rainfed',
            ];

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[350],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Filter Properties',
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AgroZemexTokens.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Soil Type',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: soilTypes.map((type) {
                        final selected = (_filter.soilType ?? 'All') == type;
                        return ChoiceChip(
                          label: Text(type),
                          selected: selected,
                          selectedColor: AgroZemexTokens.primary.withValues(
                            alpha: 0.15,
                          ),
                          labelStyle: TextStyle(
                            color: selected
                                ? AgroZemexTokens.primary
                                : Colors.black87,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (v) {
                            setSheetState(() {
                              _filter = ListingFilterModel(
                                roadAccess: _filter.roadAccess,
                                soilType: type == 'All' ? null : type,
                                waterSource: _filter.waterSource,
                                minAreaSqM: _filter.minAreaSqM,
                                maxAreaSqM: _filter.maxAreaSqM,
                                village: _filter.village,
                              );
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Water Source',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: waterSources.map((source) {
                        final selected =
                            (_filter.waterSource ?? 'All') == source;
                        return ChoiceChip(
                          label: Text(source),
                          selected: selected,
                          selectedColor: AgroZemexTokens.primary.withValues(
                            alpha: 0.15,
                          ),
                          labelStyle: TextStyle(
                            color: selected
                                ? AgroZemexTokens.primary
                                : Colors.black87,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (v) {
                            setSheetState(() {
                              _filter = ListingFilterModel(
                                roadAccess: _filter.roadAccess,
                                soilType: _filter.soilType,
                                waterSource: source == 'All' ? null : source,
                                minAreaSqM: _filter.minAreaSqM,
                                maxAreaSqM: _filter.maxAreaSqM,
                                village: _filter.village,
                              );
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Road Access',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Any'),
                          selected: _filter.roadAccess == null,
                          onSelected: (v) {
                            setSheetState(() {
                              _filter = ListingFilterModel(
                                roadAccess: null,
                                soilType: _filter.soilType,
                                waterSource: _filter.waterSource,
                                minAreaSqM: _filter.minAreaSqM,
                                maxAreaSqM: _filter.maxAreaSqM,
                                village: _filter.village,
                              );
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Yes'),
                          selected: _filter.roadAccess == true,
                          onSelected: (v) {
                            setSheetState(() {
                              _filter = ListingFilterModel(
                                roadAccess: true,
                                soilType: _filter.soilType,
                                waterSource: _filter.waterSource,
                                minAreaSqM: _filter.minAreaSqM,
                                maxAreaSqM: _filter.maxAreaSqM,
                                village: _filter.village,
                              );
                            });
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('No'),
                          selected: _filter.roadAccess == false,
                          onSelected: (v) {
                            setSheetState(() {
                              _filter = ListingFilterModel(
                                roadAccess: false,
                                soilType: _filter.soilType,
                                waterSource: _filter.waterSource,
                                minAreaSqM: _filter.minAreaSqM,
                                maxAreaSqM: _filter.maxAreaSqM,
                                village: _filter.village,
                              );
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              setSheetState(() {
                                _filter = ListingFilterModel.empty;
                              });
                            },
                            child: const Text('Clear All'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _applyFilters(_filter);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AgroZemexTokens.primary,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Apply'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
            sellerId: item.sellerId,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please login first!")));
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
      key: _scaffoldKey,
      backgroundColor: AgroZemexTokens.surface,
      drawer: Drawer(
        backgroundColor: AgroZemexTokens.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: AgroZemexTokens.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'AgroZemex',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your land & crop marketplace',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.person_outline,
                color: AgroZemexTokens.primary,
              ),
              title: const Text('My Profile'),
              onTap: () {
                Navigator.pop(context); // close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreenDash()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.settings_outlined,
                color: AgroZemexTokens.primary,
              ),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings under development')),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.help_outline,
                color: AgroZemexTokens.primary,
              ),
              title: const Text('Help & Support'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                );
              },
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(
                Icons.info_outline,
                color: AgroZemexTokens.primary,
              ),
              title: const Text('About Us'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AboutUsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.policy_outlined,
                color: AgroZemexTokens.primary,
              ),
              title: const Text('Policies'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PoliciesScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.description_outlined,
                color: AgroZemexTokens.primary,
              ),
              title: const Text('Terms & Conditions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TermsConditionsScreen()),
                );
              },
            ),
          ],
        ),
      ),
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
                  color: AgroZemexTokens.onSurfaceVariant.withValues(
                    alpha: 0.08,
                  ),
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
                onPressed: () {
                  _scaffoldKey.currentState?.openDrawer();
                },
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
                                  )
                                  as ImageProvider
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
      body: RefreshIndicator(
        color: AgroZemexTokens.primary,
        onRefresh: _onRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
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
                            _debounce = Timer(
                              const Duration(milliseconds: 300),
                              () {
                                final service = context
                                    .read<ListingQueryService>();
                                service.resetPagination();
                                setState(() {
                                  _searchQuery = query;
                                  _listings.clear();
                                  _hasMore = true;
                                  _isLoading = false;
                                });
                                _loadMore();
                              },
                            );
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
                        onPressed: () => _showFilterBottomSheet(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Dynamic Bento Property Grid
            if (_listings.isEmpty && _isLoading)
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AgroZemexTokens.marginMobile,
                ),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const LandCardShimmer(),
                    childCount: 3,
                  ),
                ),
              )
            else if (_listings.isEmpty && !_isLoading)
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
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index == _listings.length) {
                      return const LandCardShimmer();
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
                  }, childCount: _listings.length + (_isLoading ? 1 : 0)),
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
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'home_map_fab',
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
    final auth = context.read<AuthService>();
    final wishlistService = context.read<WishlistService>();
    final uid = auth.user?.uid ?? '';

    final double? distanceKm = item.distanceMeters != null
        ? item.distanceMeters! / 1000
        : null;

    final bool hasImage = item.photoPaths.isNotEmpty;
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardHeight = (screenWidth * 0.8).clamp(280.0, 340.0);

    return GestureDetector(
      onTap: () => _onCardTap(item),
      child: Container(
        height: cardHeight,
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
                  : Image.asset(AppAssets.defaultLand, fit: BoxFit.cover),
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
                            if (item.soilType != null &&
                                item.soilType!.isNotEmpty) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AgroZemexTokens.primary.withValues(
                                    alpha: 0.8,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  item.soilType!.toUpperCase(),
                                  style: AgroZemexTokens.labelCaps.copyWith(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            if (item.areaInSqMeters > 20000)
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
                        StreamBuilder<bool>(
                          stream: uid.isNotEmpty
                              ? wishlistService.isWishlisted(item.id, uid: uid)
                              : Stream.value(false),
                          builder: (context, snapshot) {
                            final isFav = snapshot.data ?? false;
                            return GestureDetector(
                              onTap: () {
                                if (auth.user != null) {
                                  wishlistService.toggleWishlist(
                                    item.id,
                                    uid: auth.user!.uid,
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Please login first!'),
                                    ),
                                  );
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginScreen(),
                                    ),
                                  );
                                }
                              },
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: isFav
                                      ? Colors.red.withValues(alpha: 0.25)
                                      : Colors.white.withValues(alpha: 0.3),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isFav ? Icons.favorite : Icons.favorite_border,
                                  color: isFav ? Colors.red : Colors.white,
                                  size: 20,
                                ),
                              ),
                            );
                          },
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
                                  : 'Resign',
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
          const Icon(Icons.explore, size: 40, color: AgroZemexTokens.primary),
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
