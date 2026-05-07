import 'package:agrozemex/features/crops/models/crop_card_model.dart';
import 'package:agrozemex/features/crops/screens/crop_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Cropcardsell extends StatelessWidget {
  final CropCardModel item;

  const Cropcardsell({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
  
    return InkWell(
      onTap: () {

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CropHomeScreen(),
            ),
          );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
               child: item.photoPaths.isNotEmpty
                    ? Image.network(
                        item.photoPaths.first,
                        height: 85,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(child: CircularProgressIndicator());
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(child: Icon(Icons.error));
                        },
                      )
                    : const SizedBox(
                        height: 85,
                        child: Center(child: Text('No photo')),
                      ),
              ),
              const SizedBox(height: 7),
              Text(
                item.title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                 '₹ ${item.price.toStringAsFixed(0)} / ${item.unit}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
               Text(
                '${item.quantity.toStringAsFixed(2)} ${item.unit}',
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}