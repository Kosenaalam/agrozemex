import 'package:agrozemex/features/auth/screens/profile_screen_dash.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Import your target screens here
import 'package:agrozemex/features/maps/screens/map_screen.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
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
          _bottomNavItem(
            icon: Icons.person,
            label: 'Profile',
            onTap: () {
              // Note: Use pushReplacement to avoid stacking too many screens
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreenDash()),
              );
            },
          ),
          _bottomNavItem(
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
            icon: Icons.agriculture_rounded,
            label: 'Sell Crops',
            onTap: () {}, // Add your screen here
          ),
          _bottomNavItem(
            icon: Icons.shopping_bag_rounded,
            label: 'Buy Crops',
            onTap: () {}, // Add your screen here
          ),
        ],
      ),
      ),
      ),
    );
  }

  // Helper widget for individual items
  Widget _bottomNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF002E5B), size: 26),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF002E5B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}