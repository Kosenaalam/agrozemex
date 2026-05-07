import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:agrozemex/features/maps/screens/view_listing_map_screen.dart';

class SellerDashboard extends StatelessWidget {
  final String userId;
  const SellerDashboard({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>( 
      stream: FirebaseFirestore.instance
          .collection('listings')
          .where('created_by', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading listings'));
        }

        final listings = snapshot.data?.docs ?? [];

        if (listings.isEmpty) {
          return const Center(child: Text('No listings found'));
        }

        return ListView.builder(
          itemCount: listings.length,
          itemBuilder: (context, index) {
            final listing = listings[index].data() as Map<String, dynamic>;
            final id = listings[index].id;
            final title = listing['title'] ?? 'N/A';
            final isActive = listing['is_active'] as bool? ?? true;

            return Card( 
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                subtitle: Text(isActive ? 'Active' : 'Inactive', style: TextStyle(color: isActive ? Colors.green : Colors.red)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: isActive,
                      activeThumbColor: Colors.green,
                      onChanged: (value) async {
                        await FirebaseFirestore.instance.collection('listings').doc(id).update({'is_active': value});
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.map, color: Color(0xFF0D47A1)),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => ViewListingMapScreen(listingId: id)),
                        );
                      },
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
}