import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/navigation/main_navigation_shell.dart';

/// Modernized AgroZemex Bottom Navigation Bar strictly adhering to AgroZemexTokens.
/// Supports zero-push tab switching via [onTap] callback when mounted in [MainNavigationShell].
///
/// MUST always be used inside [MainNavigationShell] or provided an [onTap] callback.
class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    this.currentScreen,
    this.onTap,
  });

  final int currentIndex;
  final String? currentScreen;
  final ValueChanged<int>? onTap;

  static const List<_NavItemData> _items = [
    _NavItemData(icon: Icons.landscape_rounded, label: 'Buy Land'),
    _NavItemData(icon: Icons.shopping_bag_rounded, label: 'Buy Crops'),
    _NavItemData(icon: Icons.sell_rounded, label: 'Sell Land'),
    _NavItemData(icon: Icons.agriculture_rounded, label: 'Sell Crops'),
    _NavItemData(icon: Icons.person_rounded, label: 'Profile'),
  ];

  void _handleTap(BuildContext context, int index) {
    if (onTap != null) {
      onTap!(index);
      return;
    }

    // Check if parent shell exists and delegate
    final shell = MainNavigationShell.of(context);
    if (shell != null) {
      shell.switchTab(index);
      return;
    }

    // CustomBottomNav must always be inside MainNavigationShell or given an onTap callback.
    // The old Navigator.pushReplacement fallback was dead code that created orphaned screen
    // instances and lost all tab state — removed intentionally.
    assert(
      false,
      'CustomBottomNav._handleTap: no onTap callback and no MainNavigationShell ancestor found. '
      'Ensure CustomBottomNav is always mounted within MainNavigationShell.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AgroZemexTokens.surfaceContainerLowest,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AgroZemexTokens.roundnessLargeCard),
          topRight: Radius.circular(AgroZemexTokens.roundnessLargeCard),
        ),
        boxShadow: AgroZemexTokens.softShadows,
        border: Border.all(
          color: AgroZemexTokens.surfaceContainerLow,
          width: 1.0,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (index) {
              final isSelected = index == currentIndex;
              final item = _items[index];
              return _buildBottomNavItem(
                context: context,
                index: index,
                icon: item.icon,
                label: item.label,
                isSelected: isSelected,
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => _handleTap(context, index),
      borderRadius: BorderRadius.circular(AgroZemexTokens.roundnessEight),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AgroZemexTokens.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AgroZemexTokens.primary
                  : AgroZemexTokens.onSurfaceVariant,
              size: 22,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AgroZemexTokens.primary
                    : AgroZemexTokens.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItemData {
  final IconData icon;
  final String label;

  const _NavItemData({required this.icon, required this.label});
}

/*
================================================================================
PREVIOUS CUSTOM BOTTOM NAV CODE (PRESERVED IN COMMENTED FORM AS REQUESTED)
================================================================================
import 'package:agrozemex/features/auth/screens/profile_screen_dash.dart';
import 'package:agrozemex/features/crops/screens/crop_home_screen.dart';
import 'package:agrozemex/features/crops/screens/crop_sell_screen.dart';
import 'package:agrozemex/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrozemex/features/maps/screens/map_screen.dart';
import 'package:provider/provider.dart';
import 'package:agrozemex/features/auth/services/auth_service.dart';
import 'package:agrozemex/features/auth/screens/login_screen.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.currentScreen,
  });
  final int currentIndex;
  final String currentScreen;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D47A1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (currentScreen != 'home')
                _bottomNavItem(
                  currentIndex: currentIndex,
                  currentScreen: currentScreen,
                  icon: Icons.landscape_rounded,
                  label: 'Buy Land',
                  onTap: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const HomeScreen()),
                  ),
                ),
              if (currentScreen != 'welcome')
                _bottomNavItem(
                  currentIndex: currentIndex,
                  currentScreen: currentScreen,
                  icon: Icons.person,
                  label: 'Profile',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreenDash(),
                      ),
                    );
                  },
                ),

              _bottomNavItem(
                currentIndex: currentIndex,
                currentScreen: currentScreen,
                icon: Icons.sell_rounded,
                label: 'Sell Land',
                onTap: () {
                  final auth = Provider.of<AuthService>(context, listen: false);
                  if (auth.user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please log in to sell land.')),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MapScreen()),
                    );
                  }
                },
              ),
              _bottomNavItem(
                currentIndex: currentIndex,
                currentScreen: currentScreen,
                icon: Icons.agriculture_rounded,
                label: 'Sell Crops',
                onTap: () {
                  final auth = Provider.of<AuthService>(context, listen: false);
                  if (auth.user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please log in to sell crops.')),
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CropSellScreen()),
                    );
                  }
                },
              ),
              if (currentScreen != 'crop_home')
                _bottomNavItem(
                  currentIndex: currentIndex,
                  currentScreen: currentScreen,
                  icon: Icons.shopping_bag_rounded,
                  label: 'Buy Crops',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CropHomeScreen()),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bottomNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required int currentIndex,
    String? currentScreen,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
================================================================================
*/
