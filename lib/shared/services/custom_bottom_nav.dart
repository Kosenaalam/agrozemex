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
