import 'package:agrozemex/features/auth/screens/profile_screen_dash.dart';
import 'package:agrozemex/features/crops/models/crop_card_model.dart';
import 'package:agrozemex/features/home/models/listing_card_model.dart';
import 'package:agrozemex/shared/widget/cropcardsell.dart';
import 'package:agrozemex/shared/widget/landcardsell.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:agrozemex/features/admin/admin_panel.dart';
import 'package:agrozemex/shared/services/custom_bottom_nav.dart';
import 'package:agrozemex/shared/services/user_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../auth/services/auth_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  late Future<QuerySnapshot> _listingFuture;
  late Future<QuerySnapshot> _cropFuture;

  @override
  void initState() {
    super.initState();
    _listingFuture = FirebaseFirestore.instance
        .collection('listings')
        .limit(1)
        .get();
    _cropFuture = FirebaseFirestore.instance
        .collection('crops')
        .limit(1)
        .get();
  }

  ListingCardModel mapDocToModel(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    return ListingCardModel(
      id: doc.id,
      title: d['title'],
      price: (d['price'] as num).toDouble(),
      description: d['description'],
      areaInSqMeters: (d['area_sq_m'] as num).toDouble(),
      boundaryPoints: (d['boundary_points'] as List)
          .map((p) => mapbox.Point(
                coordinates: mapbox.Position(p['lng'], p['lat']),
              ))
          .toList(),
      photoPaths: List<String>.from(d['photo_paths'] ?? []),
      searchTokens: [],
    );
  }

  CropCardModel mapDocToModels(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CropCardModel(
      id: doc.id,
      title: data['title'] ?? 'N/A',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      quantity: (data['quantity'] as num?)?.toDouble() ?? 0.0,
      photoPaths: List<String>.from(data['photo_paths'] ?? []),
      cropType: data['crop_type'] ?? 'Unknown',
      unit: data['unit'] ?? 'kg',
      village: data['village'] ?? 'Unknown',
      location: data['location'] as GeoPoint? ?? GeoPoint(0, 0),
      createdAt: data['created_at'] as Timestamp,
      isActive: data['is_active'] as bool? ?? true,
      searchTokens: List<String>.from(data['search_tokens'] ?? []),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
    appBar: AppBar(
       backgroundColor: Color(0xFF002E5B),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Agrozemex',
                style: GoogleFonts.poppins(
                    fontSize: 20, fontWeight: FontWeight.w500, color: Colors.white)),
             IconButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const ProfileScreenDash()),
                      );
                    },
                    icon: const Icon(Icons.person_2_rounded,
                        size: 26, color: Colors.white),
                    
                  ),
          ],
        ),
         shape: const RoundedRectangleBorder(
           borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)), 
         ),
         elevation: 4, 
       
    ),
      body: SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
            child: Column(
              children: [
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
            const SizedBox(height: 12,),
                Column(
                  children: [
                    Text('Explore Land for sale'),
                      FutureBuilder<QuerySnapshot>(
                     future: _listingFuture,
                  builder: (context, snapshot) {
               if (!snapshot.hasData) return const SizedBox();
        
            return Column(
        children: snapshot.data!.docs
            .map((doc) => LandCard(item: mapDocToModel(doc)))
            .toList(),
            );
          },
        )
                  ],
                ),
                const SizedBox(height: 10,),
                 Column(
                  children: [
                    Text('Explore Crops for sale'),
                      FutureBuilder<QuerySnapshot>(
                     future: _cropFuture,
                  builder: (context, snapshot) {
               if (!snapshot.hasData) return const SizedBox();
        
            return Column(
        children: snapshot.data!.docs
            .map((doc) => Cropcardsell(item: mapDocToModels(doc)))
            .toList(),
            );
          },
        )
                  ],
                ),
        //                Column(
        //                  children: [
        //                   FutureBuilder<QuerySnapshot>(
        //                    future: FirebaseFirestore.instance
        //                  .collection('listings')
        //                  .limit(1)
        //                  .get(),
        //                builder: (context, snapshot) {
        //              if (!snapshot.hasData) return const SizedBox();
        
        //     return Column(
        //       children: snapshot.data!.docs
        //           .map((doc) => LandCard(item: mapDocToModel(doc)))
        //           .toList(),
        //     );
        //   },
        // )
        //             ],
        //                ),
               
              ],
            ),
          ),
        ),
      ),
       floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
       bottomNavigationBar: const CustomBottomNav(
        currentIndex: 0, 
        currentScreen: 'welcome',
       ),
    );
  }

}
