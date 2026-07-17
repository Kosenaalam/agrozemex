import 'package:agrozemex/features/home/screens/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../../features/home/models/listing_card_model.dart';

class LandCard extends StatelessWidget {
  final ListingCardModel item;

  const LandCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final double? distanceKm =
        item.distanceMeters != null ? item.distanceMeters! / 1000 : null;

    return InkWell(
      onTap: () {
     //   final auth = context.read<AuthService>();

      //  if (auth.user != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HomeScreen(),
            ),
          );
        // } else {
        //   ScaffoldMessenger.of(context).showSnackBar(
        //     const SnackBar(content: Text("Please login first!")),
        //   );
        //   Navigator.push(
        //     context,
        //     MaterialPageRoute(builder: (_) => const LoginScreen()),
        //   );
        // }
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
                height: 90,
                child: mapbox.MapWidget(
                  styleUri: mapbox.MapboxStyles.SATELLITE_STREETS,
                  cameraOptions: mapbox.CameraOptions(
                    center: item.boundaryPoints.first,
                    zoom: 15,
                  ),
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
                '₹ ${item.price.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  color: const Color(0xFF2E7D32),
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (distanceKm != null)
                Text('${distanceKm.toStringAsFixed(1)} km away'),
              Text('${item.areaInSqMeters.toStringAsFixed(2)} sq m'),
            ],
          ),
        ),
      ),
    );
  }
}