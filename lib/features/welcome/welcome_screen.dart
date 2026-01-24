import 'package:agrozemex/features/auth/screens/profile_screen_dash.dart';
import 'package:agrozemex/features/home/screens/home_screen.dart';
import 'package:agrozemex/features/maps/screens/map_screen.dart';
import 'package:agrozemex/features/admin/admin_panel.dart';
import 'package:agrozemex/shared/services/user_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth/services/auth_service.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔹 Top App Bar Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left: Logo + Name
                  Row(
                    children: [
                      const Icon(
                        Icons.agriculture_rounded,
                        color: Color(0xFF002E5B),
                        size: 28,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Agrozemex',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF002E5B),
                        ),
                      ),
                    ],
                  ),

                  // Right: My Profile Button
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreenDash()),
                      );
                    },
                    icon: const Icon(Icons.person,
                        size: 16, color: Color(0xFF002E5B)),
                    label: Text(
                      'My Profile',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF002E5B),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      elevation: 3,
                      shadowColor: Colors.black26,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                    ),
                  ),
                ],
              ),

              // 🔹 Admin Button (Visible only if role = admin)
              Consumer<AuthService>(
                builder: (context, auth, child) {
                  if (auth.user == null) return const SizedBox.shrink();
                  return FutureBuilder<Map<String, dynamic>>(
                    future: UserFirestoreService().getUserData(auth.user!.uid),
                    builder: (context, snapshot) {
                      if (snapshot.hasData &&
                          snapshot.data!['role'] == 'admin') {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding:
                                const EdgeInsets.only(top: 10.0, right: 8.0),
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => const AdminPanel()),
                                );
                              },
                              icon: const Icon(Icons.admin_panel_settings,
                                  size: 16),
                              label: Text(
                                'Admin Panel',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.redAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30)),
                                elevation: 3,
                              ),
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  );
                },
              ),

              const SizedBox(height: 60),

              // 🔹 Center Text Card
              Center(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    'Buy land. Sell land.\nBuy crops. Sell crops.\nGrow smart.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF002E5B),
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              // 🔹 Bottom Navigation Bar (custom design)
              Container(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _bottomNavItem(
                      icon: Icons.landscape_rounded,
                      label: 'Buy Land',
                      onTap: () => Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const HomeScreen()),
                      ),
                    ),
                    _bottomNavItem(
                      icon: Icons.sell_rounded,
                      label: 'Sell Land',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapScreen()),
                      ),
                    ),
                    _bottomNavItem(
                      icon: Icons.agriculture_rounded,
                      label: 'Sell Crops',
                      onTap: () {},
                    ),
                    _bottomNavItem(
                      icon: Icons.shopping_bag_rounded,
                      label: 'Buy Crops',
                      onTap: () {},
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

  // 🔹 Reusable Bottom Navigation Button
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
