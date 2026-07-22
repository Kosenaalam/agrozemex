import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:agrozemex/core/theme/theme.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: AgroZemexTokens.primary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('listings').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading listings'));
          }

          final listings = snapshot.data?.docs ?? [];

          return ListView.builder(
            itemCount: listings.length,
            itemBuilder: (context, index) {
              final listing = listings[index].data() as Map<String, dynamic>;
              final id = listings[index].id;
              final title = listing['title'] ?? 'N/A';
              final price = listing['price'] ?? 0.0;
              final createdAt = (listing['created_at'] as Timestamp?)?.toDate().toString() ?? 'N/A';
              final createdBy = listing['created_by'] ?? 'N/A';
              final isActive = listing['is_active'] as bool? ?? true;

              return ListTile(
                title: Text(
                  title, 
                  style: AgroZemexTokens.bodyLarge.copyWith(fontWeight: FontWeight.bold),
                ),
                subtitle: Text('Price: ₹$price | Created: $createdAt | By: $createdBy'),
                trailing: Switch(
                  value: isActive,
                  activeThumbColor: AgroZemexTokens.success,
                  activeTrackColor: AgroZemexTokens.success.withValues(alpha: 0.5),
                  onChanged: (value) async {
                    await FirebaseFirestore.instance.collection('listings').doc(id).update({'is_active': value});
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}