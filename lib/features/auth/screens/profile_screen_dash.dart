import 'package:agrozemex/features/auth/screens/login_screen.dart'; 
import 'package:agrozemex/features/auth/screens/seller_dashboard.dart';
import 'package:agrozemex/shared/services/user_firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:agrozemex/features/wishlist/screens/wishlist_screen.dart';


class ProfileScreenDash extends StatefulWidget {
  const ProfileScreenDash({super.key});

  @override
  State<ProfileScreenDash> createState() => _ProfileScreenDashState();
}

class _ProfileScreenDashState extends State<ProfileScreenDash> {
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
      

    }

    return FutureBuilder<Map<String, dynamic>>(
      future: UserFirestoreService().getUserData(auth.user!.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Scaffold(body: Center(child: Text('Error loading profile')));
        }

        final userData = snapshot.data!;
        final phone = userData['phone'] ?? 'N/A';
        final createdAt = (userData['createdAt'] as Timestamp?)?.toDate().toString() ?? 'N/A';
        final role = userData['role'] ?? 'buyer';

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            backgroundColor: const Color(0xFF0D47A1),
            foregroundColor: Color(0xffffffff),
            actions: [
              IconButton( 
              
                icon: const Icon(Icons.logout),
                color: Color(0xffffffff),
                onPressed: () async {
                  await auth.logout();
                  Navigator.pushReplacement( 
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
              ),
            ],
          ),
          body: 
              RefreshIndicator(
                onRefresh: () async => setState(() {}),
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ListTile(
                              leading: const Icon(Icons.phone, color: Color(0xFF0D47A1)),
                              title: Text('Phone Number', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                              subtitle: Text(phone),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.calendar_today, color: Color(0xFF0D47A1)),
                              title: Text('Account Created', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                              subtitle: Text(createdAt),
                            ),
                            const Divider(),
                            ListTile(
                              leading: const Icon(Icons.person_outline, color: Color(0xFF0D47A1)),
                              title: Text('Role', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                             subtitle: Text(
                             role.isNotEmpty 
                              ? role[0].toUpperCase() + role.substring(1).toLowerCase() 
                            : role
                             ),
                            ),
                          ],
                        ),
                      ),
                    ),
              
                       Card(
                       elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                     child: Column(
                      children: [
                      ListTile(
                     leading: const Icon(Icons.favorite, color: Colors.red),
                     title: Text(
                     'My Wishlist',
                     style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                   ),
                     trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                  builder: (_) => const WishlistScreen(),
                ),
              );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
                    const SizedBox(height: 20),
                    if (role == 'seller') 
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('My Listings', style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 300,
                            child: SellerDashboard(userId: auth.user!.uid),
                          ),
                        ],
                      ),
                    if (role == 'buyer') 
                      const Center(
                        child: Text('You are a buyer. Create a listing to become a seller!'),
                      ),
                  ],
                ),
              ),
        );
      },
    );
  }
}
