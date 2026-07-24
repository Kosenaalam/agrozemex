import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/maps/screens/view_listing_map_screen.dart';
import 'package:agrozemex/shared/services/visit_booking_service.dart';
import '../services/auth_service.dart';
import 'package:agrozemex/shared/services/user_firestore_service.dart';

class SellerDashboard extends StatefulWidget {
  final String userId;
  const SellerDashboard({super.key, required this.userId});

  @override
  State<SellerDashboard> createState() => _SellerDashboardState();
}

class _SellerDashboardState extends State<SellerDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Stream<QuerySnapshot> _listingsStream;
  late Stream<QuerySnapshot> _cropsStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _listingsStream = FirebaseFirestore.instance
        .collection('listings')
        .where('created_by', isEqualTo: widget.userId)
        .snapshots();
    _cropsStream = FirebaseFirestore.instance
        .collection('crops')
        .where('created_by', isEqualTo: widget.userId)
        .snapshots();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: AgroZemexTokens.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: AgroZemexTokens.primary,
            labelColor: AgroZemexTokens.primary,
            unselectedLabelColor: AgroZemexTokens.onSurfaceVariant,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Properties'),
              Tab(text: 'Crops'),
              Tab(text: 'Booked Visits'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildListingsView(),
              _buildCropsView(),
              _buildBookedVisitsView(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListingsView() {
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
              shape: RoundedRectangleBorder(
                borderRadius: AgroZemexTokens.radiusTwelve,
              ),
              child: ListTile(
                title: Text(
                  title,
                  style: AgroZemexTokens.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: isActive
                        ? AgroZemexTokens.success
                        : AgroZemexTokens.error,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: isActive,
                      activeThumbColor: AgroZemexTokens.success,
                      activeTrackColor:
                          AgroZemexTokens.success.withValues(alpha: 0.5),
                      onChanged: (value) async {
                        final auth =
                            Provider.of<AuthService>(context, listen: false);
                        if (auth.user == null ||
                            listing['created_by'] != auth.user!.uid) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Unauthorized: You do not own this listing.',
                              ),
                            ),
                          );
                          return;
                        }
                        await FirebaseFirestore.instance
                            .collection('listings')
                            .doc(id)
                            .update({'is_active': value});
                      },
                    ),
                      IconButton(
                        icon: const Icon(
                          Icons.map,
                          color: AgroZemexTokens.primary,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ViewListingMapScreen(listingId: id),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _confirmDeleteLand(context, id),
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

  Widget _buildCropsView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _cropsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return const Center(child: Text('Error loading crops'));
        }

        final crops = snapshot.data?.docs ?? [];

        if (crops.isEmpty) {
          return const Center(child: Text('No crops found'));
        }

        return ListView.builder(
          itemCount: crops.length,
          itemBuilder: (context, index) {
            final crop = crops[index].data() as Map<String, dynamic>;
            final id = crops[index].id;
            final title = crop['title'] ?? 'N/A';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: AgroZemexTokens.radiusTwelve,
              ),
              child: ListTile(
                title: Text(
                  title,
                  style: AgroZemexTokens.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.red,
                      ),
                      onPressed: () => _confirmDeleteCrop(context, id),
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

  Future<void> _confirmDeleteLand(BuildContext context, String listingId) async {
    final userFirestoreService = context.read<UserFirestoreService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Property'),
        content: const Text('Are you sure you want to permanently delete this property?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await userFirestoreService.deleteLandListing(listingId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Property deleted successfully.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  Future<void> _confirmDeleteCrop(BuildContext context, String listingId) async {
    final userFirestoreService = context.read<UserFirestoreService>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Crop'),
        content: const Text('Are you sure you want to permanently delete this crop?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await userFirestoreService.deleteCropListing(listingId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Crop deleted successfully.')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete: $e')),
          );
        }
      }
    }
  }

  Widget _buildBookedVisitsView() {
    final bookingService = context.read<VisitBookingService>();
    return StreamBuilder<QuerySnapshot>(
      stream: bookingService.streamSellerBookings(widget.userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          debugPrint('BookedVisitsStream Error: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Error loading site visit requests: ${snapshot.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AgroZemexTokens.error),
              ),
            ),
          );
        }

        final bookings = snapshot.data?.docs ?? [];
        if (bookings.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.calendar_month_outlined,
                  size: 48,
                  color: AgroZemexTokens.onSurfaceVariant,
                ),
                const SizedBox(height: 12),
                Text(
                  'No site visit bookings yet',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AgroZemexTokens.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final doc = bookings[index];
            final data = doc.data() as Map<String, dynamic>;
            final bookingId = doc.id;
            final listingTitle = data['listing_title'] ?? 'Land Listing';
            final buyerName = data['buyer_name'] ?? 'Buyer';
            final buyerPhone = data['buyer_phone'] ?? 'N/A';
            final status = data['status'] ?? 'pending';
            final note = data['note'] as String?;

            DateTime? visitDate;
            if (data['visit_date'] is Timestamp) {
              visitDate = (data['visit_date'] as Timestamp).toDate();
            }

            final visitFormatted = visitDate != null
                ? "${visitDate.day}/${visitDate.month}/${visitDate.year} at ${TimeOfDay.fromDateTime(visitDate).format(context)}"
                : 'Date Pending';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: AgroZemexTokens.radiusTwelve,
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            listingTitle,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: status == 'confirmed'
                                ? AgroZemexTokens.success.withValues(alpha: 0.15)
                                : AgroZemexTokens.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status.toUpperCase(),
                            style: TextStyle(
                              color: status == 'confirmed'
                                  ? AgroZemexTokens.success
                                  : AgroZemexTokens.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      children: [
                        const Icon(
                          Icons.person_outline,
                          size: 18,
                          color: AgroZemexTokens.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Buyer: ',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AgroZemexTokens.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          buyerName,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.phone_outlined,
                          size: 18,
                          color: AgroZemexTokens.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Phone: ',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AgroZemexTokens.onSurfaceVariant,
                          ),
                        ),
                        SelectableText(
                          buyerPhone,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AgroZemexTokens.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time_outlined,
                          size: 18,
                          color: AgroZemexTokens.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Scheduled Visit: ',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AgroZemexTokens.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          visitFormatted,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    if (note != null && note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Note: $note',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (status == 'pending')
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AgroZemexTokens.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: () async {
                              await bookingService.updateBookingStatus(
                                bookingId,
                                'confirmed',
                              );
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Visit request confirmed.'),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.check, size: 16),
                            label: const Text('Confirm Visit'),
                          ),
                      ],
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