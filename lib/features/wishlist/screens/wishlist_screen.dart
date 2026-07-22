import 'dart:async';
import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/home/screens/listing_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:agrozemex/shared/services/wishlist_service.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:provider/provider.dart';
import '../../auth/services/auth_service.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  Stream<List<DocumentSnapshot>> _combineWishlistStreams(List<String> ids) {
    if (ids.isEmpty) return Stream.value([]);

    final chunks = <List<String>>[];
    for (var i = 0; i < ids.length; i += 10) {
      chunks.add(ids.sublist(i, (i + 10).clamp(0, ids.length)));
    }

    final controller = StreamController<List<DocumentSnapshot>>();
    final subscriptions = <StreamSubscription<QuerySnapshot>>[];
    final lastSnapshots = <int, List<DocumentSnapshot>>{};

    void emitCombined() {
      if (controller.isClosed) return;
      final allDocs = <DocumentSnapshot>[];
      for (int i = 0; i < chunks.length; i++) {
        if (lastSnapshots.containsKey(i)) {
          allDocs.addAll(lastSnapshots[i]!);
        }
      }
      controller.add(allDocs);
    }

    for (int i = 0; i < chunks.length; i++) {
      final sub = FirebaseFirestore.instance
          .collection('listings')
          .where(FieldPath.documentId, whereIn: chunks[i])
          .snapshots()
          .listen((snap) {
        lastSnapshots[i] = snap.docs;
        emitCombined();
      }, onError: (err) {
        if (!controller.isClosed) {
          controller.addError(err);
        }
      });
      subscriptions.add(sub);
    }

    controller.onCancel = () {
      for (final sub in subscriptions) {
        sub.cancel();
      }
      controller.close();
    };

    return controller.stream;
  }

  @override
  Widget build(BuildContext context) {
    final wishlistService = context.read<WishlistService>();
    final auth = context.read<AuthService>();
    final uid = auth.user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('My Wishlist')),
      body: StreamBuilder<List<String>>(
        stream: wishlistService.getWishlistIds(uid: uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No wishlist items'));
          }

          return StreamBuilder<List<DocumentSnapshot>>(
            stream: _combineWishlistStreams(snapshot.data!),
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
                itemCount: snap.data!.length,
                itemBuilder: (context, index) {
                  final doc = snap.data![index];
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