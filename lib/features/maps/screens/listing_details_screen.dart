import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart' show GoogleFonts;
import 'package:image_picker/image_picker.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import '../../../shared/services/user_firestore_service.dart';
import 'package:provider/provider.dart';
import '../../../shared/services/storage_service.dart';
import '../../auth/services/auth_service.dart';
import 'package:agrozemex/core/theme/theme.dart';

import 'package:agrozemex/features/auth/screens/login_screen.dart';
import 'package:agrozemex/shared/services/phone_binding_dialog.dart';

class ListingDetailsScreen extends StatefulWidget {
  final List<mapbox.Point> boundaryPoints;
  final double areaInSqMeters;

  const ListingDetailsScreen({
    super.key,
    required this.boundaryPoints,
    required this.areaInSqMeters,
  });

  @override
  State<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends State<ListingDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPhoneVerificationGuard();
    });
  }

  Future<void> _checkPhoneVerificationGuard() async {
    final auth = context.read<AuthService>();
    final user = auth.user;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in to list land.')),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return;
    }

    final userService = context.read<UserFirestoreService>();
    final verified = await userService.isPhoneAndTermsVerified(user);
    if (!verified && mounted) {
      final success = await PhoneBindingDialog.show(context);
      if (!success && mounted) {
        Navigator.pop(context);
        return;
      }
    }
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();

  String? _soilType = 'Alluvial';
  String? _waterSource = 'Tube Well';
  bool _roadAccess = true;
  bool _isSubmitting = false;

  final List<XFile> _pickedImages = [];
  final ImagePicker _picker = ImagePicker();

  static const Color _primaryBlue = AgroZemexTokens.primary;
  static const Color _accentGreen = AgroZemexTokens.success;

  final List<String> _soilTypes = [
    'Alluvial',
    'Black',
    'Red',
    'Laterite',
    'Sandy',
    'Clay',
  ];
  final List<String> _waterSources = [
    'Tube Well',
    'Canal',
    'River',
    'Rainfed',
    'Borewell',
  ];

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();

    if (images.isNotEmpty) {
      setState(() {
        _pickedImages.addAll(images);
        if (_pickedImages.length > 10) {
          _pickedImages.length = 10;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum 10 photos allowed')),
          );
        }
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  void _submitListing() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    try {
      if (_formKey.currentState!.validate() && _pickedImages.isNotEmpty) {
        final storageService = context.read<StorageService>();

        final files = _pickedImages.map((e) => File(e.path)).toList();

        final imageUrls = await storageService.uploadListingImages(files);

        if (!mounted) return;
        final auth = context.read<AuthService>();
        if (auth.user == null) throw Exception('User not logged in');
        final firestoreService = context.read<UserFirestoreService>();

        await firestoreService.saveLandListing(
          uid: auth.user!.uid,
          title: _titleController.text,
          price: double.parse(_priceController.text.replaceAll(',', '')),
          description: _descriptionController.text,
          areaInSqMeters: widget.areaInSqMeters,
          boundaryPoints: widget.boundaryPoints,
          photoPaths: imageUrls,
          village: _villageController.text,
          soilType: _soilType!,
          waterSource: _waterSource!,
          roadAccess: _roadAccess,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Listing saved successfully'),
            backgroundColor: _accentGreen,
          ),
        );

        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please complete all fields and add photos'),
          ),
        );
        if (mounted) setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving listing: $e')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Complete Listing',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: _primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Container(
        color: const Color(0xFFF5F7FA),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const Icon(Icons.square_foot, size: 40, color: _primaryBlue),
                      const SizedBox(height: 12),
                      Text(
                        'Land Area',
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        '${widget.areaInSqMeters.toStringAsFixed(2)} sq m',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: _primaryBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              TextFormField(
                controller: _titleController,
                maxLength: 50,
                decoration: InputDecoration(
                  labelText: 'Land Title *',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Price in ₹ *',
                  prefixIcon: const Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _villageController,
                maxLength: 40,
                decoration: const InputDecoration(
                  labelText: 'Village Name',
                  prefixIcon: Icon(Icons.location_city),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
                validator: (v) => v?.isEmpty == true ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 5,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Photo Picker
              Text(
                'Add Photos * (max 10)',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _pickImages,
                icon: const Icon(Icons.add_photo_alternate),
                label: Text(
                  'Pick Photos from Gallery',
                  style: GoogleFonts.inter(),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),

              // Photo Grid Preview
              if (_pickedImages.isNotEmpty)
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 8,
                    crossAxisSpacing: 8,
                  ),
                  itemCount: _pickedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(_pickedImages[index].path),
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 4,
                          right: 4,
                          child: IconButton(
                            icon: const Icon(
                              Icons.remove_circle,
                              color: Colors.red,
                            ),
                            onPressed: () => _removeImage(index),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 24),

              DropdownButtonFormField<String>(
                initialValue: _soilType,
                decoration: InputDecoration(
                  labelText: 'Soil Type',
                  prefixIcon: const Icon(Icons.texture),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _soilTypes
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _soilType = v),
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                initialValue: _waterSource,
                decoration: InputDecoration(
                  labelText: 'Water Source',
                  prefixIcon: const Icon(Icons.water_drop),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: _waterSources
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => _waterSource = v),
              ),
              const SizedBox(height: 16),

              SwitchListTile(
                title: Text(
                  'Road Access',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w500),
                ),
                value: _roadAccess,
                activeThumbColor: _accentGreen,
                thumbColor: WidgetStateProperty.all(Colors.white),
                trackColor: WidgetStateProperty.all(
                  _accentGreen.withValues(alpha: 0.5),
                ),
                onChanged: (v) => setState(() => _roadAccess = v),
              ),
              const SizedBox(height: 32),

              SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitListing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accentGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Submit Listing',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
