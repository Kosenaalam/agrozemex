import 'package:agrozemex/features/home/screens/home_screen.dart';
import 'package:agrozemex/features/maps/screens/map_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';




class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D47A1), // Deep blue background
      body: SafeArea(
        child: Stack(
          children: [
            // Background gradient overlay (subtle)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF0D47A1).withOpacity(0.95),
                    const Color(0xFF1565C0),
                  ],
                ),
              ),
            ),

            // Main content
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo / App Name
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.agriculture_rounded,
                        size: 30,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Agrozemex',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 35),

                    // My Profile button (top right style)
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Navigate to profile
                        },
                        icon: const Icon(Icons.person, size: 15),
                        label: Text(
                          'My Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF0D47A1),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 4,
                        ),
                      ),
                    ),
                  ),

                  // Main headline text
                  Text(
                    'Buy land.Sell land.\nBuy crops.Sell crops.\nGrow smart.',
        
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      height: 1.3,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 45),


                  const Spacer(flex: 2),

                  // Action buttons (big rounded pills)
                  _buildActionButton(
                    label: 'Buy Land',
                    icon: Icons.landscape_rounded,
                    onPressed: () {
                      // Navigate to buy land screen
                      Navigator.push(
                        context,
                         MaterialPageRoute(builder: (_) => const HomeScreen()));

                    },
                  ),
                  const SizedBox(height: 15),
                  _buildActionButton(
                    label: 'Sell Land',
                    icon: Icons.sell_rounded,
                    onPressed: () {
                      // Navigate to sell land (map screen)
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen()));
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildActionButton(
                    label: 'Sell Crops',
                    icon: Icons.agriculture_rounded,
                    onPressed: () {
                      // Navigate to sell crops
                    },
                  ),
                  const SizedBox(height: 15),
                  _buildActionButton(
                    label: 'Buy Crops',
                    icon: Icons.shopping_basket_rounded,
                    onPressed: () {
                      // Navigate to buy crops
                    },
                  ),

                  const Spacer(flex: 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable big pill button
  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 28, color: const Color(0xFF0D47A1)),
        label: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0D47A1),
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF0D47A1),
          padding: const EdgeInsets.symmetric(vertical: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(60), // Very rounded pill
          ),
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
      ),
    );
  }
}