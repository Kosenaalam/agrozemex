import 'package:agrozemex/features/auth/screens/profile_screen_dash.dart';
import 'package:agrozemex/features/crops/screens/crop_home_screen.dart';
import 'package:agrozemex/features/crops/screens/crop_sell_screen.dart';
import 'package:agrozemex/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrozemex/features/maps/screens/map_screen.dart';

class CustomBottomNav extends StatelessWidget {
   const CustomBottomNav({super.key, required this.currentIndex, required this.currentScreen});
   final int currentIndex;
  final String currentScreen;
     
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color:  const Color(0xFF0D47A1),
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
      child:Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          if(currentScreen != 'home')
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
                    if(currentScreen != 'welcome')
          _bottomNavItem(
            currentIndex: currentIndex,
            currentScreen: currentScreen,
            icon: Icons.person,
            label: 'Profile',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreenDash()),
              );
            },
          ),
                    
          _bottomNavItem(
            currentIndex: currentIndex,
            currentScreen: currentScreen,
            icon: Icons.sell_rounded,
            label: 'Sell Land',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MapScreen()),
              );
            },
          ),
          _bottomNavItem(
            currentIndex: currentIndex,
            currentScreen: currentScreen,
            icon: Icons.agriculture_rounded,
            label: 'Sell Crops',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CropSellScreen()),
            ),
          ),
          if(currentScreen != 'crop_home')
          _bottomNavItem(
            currentIndex: currentIndex,
            currentScreen: currentScreen,
            icon: Icons.shopping_bag_rounded,
            label: 'Buy Crops',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const CropHomeScreen()),
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
            Icon(icon, color:  Colors.white, size: 20),
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