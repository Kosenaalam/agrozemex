import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/auth/screens/profile_screen_dash.dart';
import 'package:agrozemex/features/home/screens/home_screen.dart';
import 'package:agrozemex/features/maps/screens/map_screen.dart';

/// AgroZemex Discover / Home Landing Screen built strictly from HTML Snippet 1.
class DiscoverHomeScreen extends StatefulWidget {
  const DiscoverHomeScreen({super.key});

  @override
  State<DiscoverHomeScreen> createState() => _DiscoverHomeScreenState();
}

class _DiscoverHomeScreenState extends State<DiscoverHomeScreen> {
  final PageController _carouselController = PageController(viewportFraction: 0.85);

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isDesktop = screenSize.width >= 768;

    return Scaffold(
      backgroundColor: AgroZemexTokens.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: ClipRRect(
          child: AppBar(
            backgroundColor: AgroZemexTokens.surface.withValues(alpha: 0.95),
            elevation: 0,
            title: Row(
              children: [
                Text(
                  'AgroZemex',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AgroZemexTokens.primary,
                    letterSpacing: -0.8,
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 48),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Discover',
                      style: AgroZemexTokens.bodyLarge.copyWith(
                        color: AgroZemexTokens.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Portfolio',
                      style: AgroZemexTokens.bodyLarge.copyWith(
                        color: AgroZemexTokens.onSurfaceVariant,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      'Insights',
                      style: AgroZemexTokens.bodyLarge.copyWith(
                        color: AgroZemexTokens.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
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
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AgroZemexTokens.surfaceContainerLow,
                      width: 2,
                    ),
                    image: const DecorationImage(
                      image: NetworkImage(
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuAM3ZeMJ8kaRIKQ1DuWCITMMC-V46Hl45-0I9w1r2WzleT9cIHQ6sjA8_-vvFJ7zWdj8kl-u1VfTitPXNXy5q2-aA3NnNyqRW1LQGA6kYD6jqM1BNh9DmkcnG2rjn-zBqp1AR012nRGXouSGzmv0gx3hp1PG9WwyIlrYNES01msRvAch177hTbPQtMfeRVPTfDA5HggsT8y_TYdyUQ2m6oh64I18i_2J-BFMDN8pkDTIcEJOSbxZb9GPA',
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Section with Floating Search Pill
            Stack(
              clipBehavior: Clip.none,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 64.0 : 20.0,
                    vertical: isDesktop ? 48.0 : 24.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Invest in the Earth's Foundation.",
                        style: AgroZemexTokens.displayLarge.copyWith(
                          color: AgroZemexTokens.primary,
                          fontSize: isDesktop ? 48.0 : 36.0,
                          fontWeight: FontWeight.bold,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Curated agricultural assets for institutional and visionary investors. Discover premium terroir with unparalleled potential.',
                        style: AgroZemexTokens.bodyLarge.copyWith(
                          color: AgroZemexTokens.onSurfaceVariant,
                          fontSize: isDesktop ? 18.0 : 16.0,
                        ),
                      ),
                      const SizedBox(height: 64),
                    ],
                  ),
                ),

                // Floating Search Pill
                Positioned(
                  bottom: -28,
                  left: 20,
                  right: 20,
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 600),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(40),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                        boxShadow: AgroZemexTokens.softShadows,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const HomeScreen(),
                                  ),
                                );
                              },
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.search,
                                    color: AgroZemexTokens.primary,
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'LOCATION',
                                        style: AgroZemexTokens.labelCaps.copyWith(
                                          fontSize: 10,
                                          color: AgroZemexTokens.onSurfaceVariant,
                                        ),
                                      ),
                                      Text(
                                        'Where to invest?',
                                        style: AgroZemexTokens.bodyLarge.copyWith(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 36,
                            color: AgroZemexTokens.surfaceContainerLow,
                          ),
                          if (isDesktop) ...[
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'ASSET TYPE',
                                      style: AgroZemexTokens.labelCaps.copyWith(
                                        fontSize: 10,
                                        color: AgroZemexTokens.onSurfaceVariant,
                                      ),
                                    ),
                                    Text(
                                      'Arable, Pasture...',
                                      style: AgroZemexTokens.bodyLarge.copyWith(
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomeScreen(),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                            ),
                            style: IconButton.styleFrom(
                              backgroundColor: AgroZemexTokens.primary,
                              padding: const EdgeInsets.all(12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 64),

            // Prime Acquisitions Featured Carousel Section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64.0 : 20.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Prime Acquisitions',
                        style: AgroZemexTokens.headlineMedium.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Exclusive off-market opportunities.',
                        style: AgroZemexTokens.bodyLarge.copyWith(
                          color: AgroZemexTokens.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  if (isDesktop)
                    Row(
                      children: [
                        IconButton(
                          onPressed: () {
                            _carouselController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.chevron_left),
                        ),
                        IconButton(
                          onPressed: () {
                            _carouselController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          },
                          icon: const Icon(Icons.chevron_right),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Snap Carousel
            SizedBox(
              height: 420,
              child: PageView(
                controller: _carouselController,
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildCarouselCard(
                    title: 'Verdant Plains Estate',
                    subtitle: 'Champagne Region, France • 450 Hectares',
                    price: '€12.5M',
                    tags: ['Arable', 'High Yield'],
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuBvZT9eH6ORgCXsljWAT8gMYeW462QGbbTxhYtKLluNl2MQJ8oV2joyVOyFqGFuhOLM6dgJE5d0Ye0PySJKu6ki663vSGC9hruK_qr_E9XvG0Jbz7edRzusUmU0YvSHoCmbHbYdOCXgPu5BosqONp4hJdRT59ABY9z0WIN-7Af07P_gt9hUO3gy9uoT9JGPvcaAGTjx37NxLb52illERLFbqEl868Fkc6jvhAZBt0vm6WcNNMQ2_I0V8Q',
                  ),
                  _buildCarouselCard(
                    title: 'Oak Ridge Vineyards',
                    subtitle: 'Napa Valley, USA • 120 Hectares',
                    price: '\$8.2M',
                    tags: ['Vineyard'],
                    imageUrl:
                        'https://lh3.googleusercontent.com/aida-public/AB6AXuCUOMLSxC79aLqmphuPkz2u3D2P_AVdqag9n-XhfD3kyWcQKhEcrFgl88B9tiwQN96uNbX8NflhftW-z57x_OjILMIggGC2xPInjbKxqGylUwFvbeUyZdg2VcpEUz1JlYeEzD3-O9uAJQuyxlGSSs7kfYR85mIk2vokzKB5ScHqObjnn6S8USW2D_H_rpzAGdn75YrU9OmOtBldGQNxE5jazFJYCl_-v_GyqvZLv3k-fAS3Zgl8L4opuA',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Regional Insights Section
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64.0 : 20.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Regional Insights',
                    style: AgroZemexTokens.headlineMedium.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Explore topographical context and soil vitality.',
                    style: AgroZemexTokens.bodyLarge.copyWith(
                      color: AgroZemexTokens.onSurfaceVariant,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Map Preview Banner
            Container(
              height: 300,
              margin: EdgeInsets.symmetric(
                horizontal: isDesktop ? 64.0 : 20.0,
              ),
              decoration: BoxDecoration(
                borderRadius: AgroZemexTokens.radiusLargeCard,
                image: const DecorationImage(
                  image: NetworkImage(
                    'https://lh3.googleusercontent.com/aida-public/AB6AXuBWiOId1ie6ZoJrEnCGwWM-cO5uM5lKZW_PSdi7oTisdmtW5ixAGo9DLPzlrQO3D7DmpBa_DZyHOCal5Cli4lrYaiJ87rtn-YayAtOd2GGf0RgCcsnp0ILqL_5GYk1vsv75J8MkmVmx7iJ-vRNlrfJOxSl6OWKWR9LI7xfZzPHLPdqGRgkbUous8k6rhB9SikZSiOKHHN0ZJTa734aeQ74uvIuctz68Cas8jTPU1S0r-KcS4JjFk74NZw',
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 16,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AgroZemexTokens.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Showing 42 Premium Listings',
                              style: AgroZemexTokens.labelCaps.copyWith(
                                color: AgroZemexTokens.onSurface,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton.small(
                      heroTag: 'map_btn',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MapScreen()),
                        );
                      },
                      backgroundColor: AgroZemexTokens.primary,
                      child: const Icon(Icons.layers, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildCarouselCard({
    required String title,
    required String subtitle,
    required String price,
    required List<String> tags,
    required String imageUrl,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: AgroZemexTokens.radiusLargeCard,
        boxShadow: AgroZemexTokens.softShadows,
        image: DecorationImage(
          image: NetworkImage(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AgroZemexTokens.radiusLargeCard,
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.8),
              Colors.transparent,
            ],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: tags
                  .map(
                    (t) => Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        t.toUpperCase(),
                        style: AgroZemexTokens.labelCaps.copyWith(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AgroZemexTokens.headlineMedium.copyWith(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AgroZemexTokens.bodyLarge.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bookmark_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
