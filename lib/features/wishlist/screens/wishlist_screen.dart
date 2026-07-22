import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/home/screens/listing_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agrozemex/shared/services/wishlist_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:provider/provider.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlistService = context.read<WishlistService>();

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

              return GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,             
                  childAspectRatio: 0.75,         
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: snap.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snap.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return Card(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
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
                        children: [
                          SizedBox(
                            height: 110, 
                            width: double.infinity,
                            child: (data['photo_paths'] as List? ?? []).isNotEmpty
                                ? Image.network(
                                    data['photo_paths'][0],
                                    fit: BoxFit.cover,
                                    cacheHeight: 220,
                                    errorBuilder: (context, error, stackTrace) => Image.asset(
                                      AppAssets.defaultLand,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : Image.asset(
                                    AppAssets.defaultLand,
                                    fit: BoxFit.cover,
                                  ),
                          ),

                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['title'] ?? 'Untitled Property',
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const Spacer(),
                                  Text(
                                    '₹ ${data['price']}',
                                    style: const TextStyle(
                                      fontSize: 16.5,
                                      color: Colors.green,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${(data['area_sq_m'] as num?)?.toStringAsFixed(2) ?? 0} sq m',
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}