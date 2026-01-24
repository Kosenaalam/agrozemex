import 'package:agrozemex/features/home/screens/listing_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agrozemex/shared/services/wishlist_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlistService = WishlistService();

    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: StreamBuilder<List<String>>(
        stream: wishlistService.getWishlistIds(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No wishlist items'));
          }

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('listings')
                .where(FieldPath.documentId, whereIn: snapshot.data!)
                .snapshots(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              return ListView(
                children: snap.data!.docs.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                 return Card(
  elevation: 4,
  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
  ),
  child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () {
      // Open listing details
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ListingDetailScreen(
            listingId: doc.id,
            title: data['title'],
            price: (data['price'] as num).toDouble(),
            description: data['description'] ?? '',
            areaInSqMeters: (data['area_sq_m'] as num).toDouble(),
            boundaryPoints: (data['boundary_points'] as List)
                .map((p) => mapbox.Point(
                      coordinates: mapbox.Position(
                        p['lng'],
                        p['lat'],
                      ),
                    ))
                .toList(),
            photoPaths: List<String>.from(data['photo_paths'] ?? []),
          ),
        ),
      );
    },
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // IMAGE
        if ((data['photo_paths'] as List).isNotEmpty)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              data['photo_paths'][0],
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),

        Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data['title'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '₹ ${data['price']}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${data['area_sq_m']} sq m',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    ),
  ),
);

                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}
