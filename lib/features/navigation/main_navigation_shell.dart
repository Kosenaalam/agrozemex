import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:agrozemex/features/auth/screens/login_screen.dart';
import 'package:agrozemex/features/auth/screens/profile_screen_dash.dart';
import 'package:agrozemex/features/auth/services/auth_service.dart';
import 'package:agrozemex/features/crops/screens/crop_home_screen.dart';
import 'package:agrozemex/features/crops/screens/crop_sell_screen.dart';
import 'package:agrozemex/features/home/screens/home_screen.dart';
import 'package:agrozemex/features/maps/screens/map_screen.dart';
import 'package:agrozemex/shared/services/custom_bottom_nav.dart';

import 'package:agrozemex/shared/widget/offline_banner.dart';

/// Centralized production Navigation Shell for AgroZemex.
/// Hosts an IndexedStack of the 5 primary tabs to maintain state,
/// prevent memory leaks, and provide instant tab switching.
class MainNavigationShell extends StatefulWidget {
  final int initialIndex;

  const MainNavigationShell({
    super.key,
    this.initialIndex = 0,
  });

  static MainNavigationShellState? of(BuildContext context) {
    return context.findAncestorStateOfType<MainNavigationShellState>();
  }

  @override
  State<MainNavigationShell> createState() => MainNavigationShellState();
}

class MainNavigationShellState extends State<MainNavigationShell> {
  late int _selectedIndex;
  final List<bool> _loaded = [false, false, false, false, false];

  final List<Widget> _screens = const [
    HomeScreen(),
    CropHomeScreen(),
    MapScreen(),
    CropSellScreen(),
    ProfileScreenDash(),
  ];

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex.clamp(0, 4);
    _loaded[_selectedIndex] = true;
  }

  void switchTab(int index) {
    if (index < 0 || index >= _screens.length) return;
    _onTabSelected(index);
  }

  void _onTabSelected(int index) {
    final auth = Provider.of<AuthService>(context, listen: false);

    // Protected routes: Sell Land (2), Sell Crops (3), Profile (4)
    // Unauthenticated users are redirected to LoginScreen via push,
    // giving a consistent UX instead of rendering LoginScreen embedded in the tab body.
    if ((index == 2 || index == 3 || index == 4) && auth.user == null) {
      final label = index == 2
          ? 'sell land'
          : index == 3
              ? 'sell crops'
              : 'view your profile';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in to $label.')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
        _loaded[index] = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OfflineBanner(
      child: Scaffold(
        body: IndexedStack(
          index: _selectedIndex,
          children: List.generate(_screens.length, (index) {
            return _loaded[index] ? _screens[index] : const SizedBox.shrink();
          }),
        ),
        bottomNavigationBar: CustomBottomNav(
          currentIndex: _selectedIndex,
          onTap: _onTabSelected,
        ),
      ),
    );
  }
}
