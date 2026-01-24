// NEW FILE: F:\agrozemex\lib\features\admin\admin_panel.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AdminPanel extends StatelessWidget {
  const AdminPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: const Color(0xFF0D47A1),
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
                title: Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                subtitle: Text('Price: ₹$price | Created: $createdAt | By: $createdBy'),
                trailing: Switch(
                  value: isActive,
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