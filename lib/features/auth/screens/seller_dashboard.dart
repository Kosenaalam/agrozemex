import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:agrozemex/features/maps/screens/view_listing_map_screen.dart';
import 'package:provider/provider.dart';
import 'package:agrozemex/core/theme/theme.dart';
import '../services/auth_service.dart';

class SellerDashboard extends StatefulWidget {
  final String userId;
  const SellerDashboard({super.key, required this.userId});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard> {
  late Stream<QuerySnapshot> _listingsStream;

  @override
  void initState() {
    super.initState();
    _listingsStream = FirebaseFirestore.instance
        .collection('listings')
        .where('created_by', isEqualTo: widget.userId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _listingsStream,
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
              shape: RoundedRectangleBorder(borderRadius: AgroZemexTokens.radiusTwelve),
              child: ListTile(
                title: Text(
                  title, 
                  style: AgroZemexTokens.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  isActive ? 'Active' : 'Inactive', 
                  style: TextStyle(
                    color: isActive ? AgroZemexTokens.success : AgroZemexTokens.error,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: isActive,
                      activeThumbColor: AgroZemexTokens.success,
                      activeTrackColor: AgroZemexTokens.success.withValues(alpha: 0.5),
                      onChanged: (value) async {
                        final auth = Provider.of<AuthService>(context, listen: false);
                        if (auth.user == null || listing['created_by'] != auth.user!.uid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Unauthorized: You do not own this listing.')),
                          );
                          return;
                        }
                        await FirebaseFirestore.instance.collection('listings').doc(id).update({'is_active': value});
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.map, color: AgroZemexTokens.primary),
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