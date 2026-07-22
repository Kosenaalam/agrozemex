import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/shared/services/storage_service.dart';
import 'package:agrozemex/shared/services/user_firestore_service.dart';

class CropSellScreen extends StatefulWidget {
  const CropSellScreen({super.key});

  @override
  State<CropSellScreen> createState() => _CropSellScreenState();
}

class _CropSellScreenState extends State<CropSellScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  GeoPoint? _location;
  String? _cropType;
  String? _unit = 'kg';
  bool _isSubmitting = false;
  final List<XFile> _pickedImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _cropTypes = [
    'Wheat',
    'Rice',
    'Mustard',
    'Pulses',
    'Corn',
    'Vegetables',
    'Fruits',
    'others',
  ];
  final List<String> _units = ['kg', 'ton', 'quintal'];

  Future<void> _pickImages() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        if (_pickedImages.length >= 5) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Maximum limit of 5 photos reached.')),
          );
          return;
        }
        _pickedImages.add(image);
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  @override
  void initState() {
    super.initState();
    _getLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _villageController.dispose();
    super.dispose();
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services disabled')),
      );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
        );
        return;
      }
    }
    if (!mounted) return;
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission permanently denied')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    _location = GeoPoint(position.latitude, position.longitude);
  }

  void _submitCrop() async {
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Location not determined yet. Please check permissions.')),
      );
      return;
    }
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      if (_formKey.currentState!.validate() &&
          _pickedImages.isNotEmpty &&
          _cropType != null) {
        final storageService = context.read<StorageService>();
        final files = _pickedImages.map((e) => File(e.path)).toList();
        final imageUrls = await storageService.uploadListingImages(files);
        if (!mounted) return;
        final firestoreService = context.read<UserFirestoreService>();
        await firestoreService.saveCropListing(
          title: _titleController.text,
          price: double.parse(_priceController.text),
          description: _descriptionController.text,
          quantity: double.parse(_quantityController.text),
          photoPaths: imageUrls,
          cropType: _cropType!,
          unit: _unit!,
          village: _villageController.text,
          location: _location!,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crop listed successfully')),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Complete all fields and add photos')),
        );
        if (mounted) setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AgroZemexTokens.surface,
      appBar: AppBar(
        backgroundColor: AgroZemexTokens.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AgroZemexTokens.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sell Your Harvest',
          style: AgroZemexTokens.headlineMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AgroZemexTokens.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Progress Header Step 3 of 4
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AgroZemexTokens.surfaceContainerLow,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionalTranslation(
                translation: Offset.zero,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.75,
                  decoration: BoxDecoration(
                    color: AgroZemexTokens.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'STEP 3 OF 4',
                  style: AgroZemexTokens.labelCaps,
                ),
                Text(
                  'MEDIA & REVIEW',
                  style: AgroZemexTokens.labelCaps.copyWith(
                    color: AgroZemexTokens.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            Text(
              'Capture the Harvest',
              style: AgroZemexTokens.displayLarge.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'High-quality photos significantly increase buyer trust and speed up transactions.',
              style: AgroZemexTokens.bodyMedium.copyWith(
                color: AgroZemexTokens.onSurfaceVariant,
              ),
            ),

            const SizedBox(height: 20),

            // Form Inputs Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AgroZemexTokens.radiusLargeCard,
                boxShadow: AgroZemexTokens.softShadows,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    maxLength: 12,
                    style: AgroZemexTokens.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Title *',
                      border: OutlineInputBorder(
                        borderRadius: AgroZemexTokens.radiusEight,
                      ),
                    ),
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: TextInputType.number,
                          style: AgroZemexTokens.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Price per unit (₹) *',
                            border: OutlineInputBorder(
                              borderRadius: AgroZemexTokens.radiusEight,
                            ),
                          ),
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _unit,
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(
                              borderRadius: AgroZemexTokens.radiusEight,
                            ),
                          ),
                          items: _units
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _unit = v),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _quantityController,
                          keyboardType: TextInputType.number,
                          style: AgroZemexTokens.bodyLarge,
                          decoration: InputDecoration(
                            labelText: 'Quantity *',
                            border: OutlineInputBorder(
                              borderRadius: AgroZemexTokens.radiusEight,
                            ),
                          ),
                          validator: (v) =>
                              v?.isEmpty ?? true ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _cropType,
                          decoration: InputDecoration(
                            labelText: 'Crop Type *',
                            border: OutlineInputBorder(
                              borderRadius: AgroZemexTokens.radiusEight,
                            ),
                          ),
                          hint: const Text('Select'),
                          items: _cropTypes
                              .map(
                                (e) => DropdownMenuItem(
                                  value: e,
                                  child: Text(e),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _cropType = v),
                          validator: (v) => v == null ? 'Required' : null,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _villageController,
                    maxLength: 15,
                    style: AgroZemexTokens.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Village / Location *',
                      border: OutlineInputBorder(
                        borderRadius: AgroZemexTokens.radiusEight,
                      ),
                      prefixIcon: const Icon(
                        Icons.location_on,
                        color: AgroZemexTokens.primary,
                      ),
                    ),
                    validator: (v) =>
                        v?.isEmpty ?? true ? 'Required' : null,
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _descriptionController,
                    maxLength: 100,
                    maxLines: 3,
                    style: AgroZemexTokens.bodyLarge,
                    decoration: InputDecoration(
                      labelText: 'Harvest Description',
                      border: OutlineInputBorder(
                        borderRadius: AgroZemexTokens.radiusEight,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Photo Picker Section
            Text(
              'Harvest Photos (Max 5)',
              style: AgroZemexTokens.headlineMedium.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _pickImages,
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  color: AgroZemexTokens.surfaceContainerLow,
                  borderRadius: AgroZemexTokens.radiusLargeCard,
                  border: Border.all(
                    color: AgroZemexTokens.primary.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add_a_photo,
                      color: AgroZemexTokens.primary,
                      size: 32,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Add Primary Harvest Photo',
                      style: AgroZemexTokens.bodyLarge.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AgroZemexTokens.primary,
                      ),
                    ),
                    Text(
                      'PNG, JPG up to 10MB',
                      style: AgroZemexTokens.labelCaps,
                    ),
                  ],
                ),
              ),
            ),

            if (_pickedImages.isNotEmpty) ...[
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.0,
                ),
                itemCount: _pickedImages.length,
                itemBuilder: (context, index) {
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: ClipRRect(
                          borderRadius: AgroZemexTokens.radiusEight,
                          child: Image.file(
                            File(_pickedImages[index].path),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: Colors.red.withValues(alpha: 0.8),
                          child: IconButton(
                            padding: EdgeInsets.zero,
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                            onPressed: () => _removeImage(index),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],

            const SizedBox(height: 32),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AgroZemexTokens.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AgroZemexTokens.radiusEight,
                  ),
                ),
                onPressed: _isSubmitting ? null : _submitCrop,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'PUBLISH LISTING',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 20,
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/*
================================================================================
PREVIOUS CROP SELL SCREEN CODE (PRESERVED IN COMMENTED FORM AS REQUESTED)
================================================================================

import 'dart:io';
import 'package:agrozemex/shared/services/storage_service.dart';
import 'package:agrozemex/shared/services/user_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class _OldCropSellScreen extends StatefulWidget {
  const _OldCropSellScreen({super.key});

  @override
  State<_OldCropSellScreen> createState() => _OldCropSellScreenState();
}

class _OldCropSellScreenState extends State<_OldCropSellScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _villageController = TextEditingController(); 
  GeoPoint? _location; 
  String? _cropType;
  String? _unit = 'kg';
  bool _isSubmitting = false;
  final List<XFile> _pickedImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _cropTypes = ['Wheat', 'Rice', 'Mustard','Pulses', 'Corn', 'Vegetables', 'Fruits','others'];
  final List<String> _units = ['kg', 'ton', 'quintal'];

  Future<void> _pickImages() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImages.add(image);
        if (_pickedImages.length > 5) _pickedImages.length = 5;
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }
  @override
  void initState() {
    super.initState();
    _getLocation(); 
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!mounted) return;
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location services disabled')));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (!mounted) return;
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission denied')));
        return;
      }
    }
           if(!mounted) return;
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location permission permanently denied')));
      return;
    }

    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    _location = GeoPoint(position.latitude, position.longitude);
  }
  void _submitCrop() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      if (_formKey.currentState!.validate() && _pickedImages.isNotEmpty && _cropType != null) {
        final storageService = context.read<StorageService>();
        final files = _pickedImages.map((e) => File(e.path)).toList();
        final imageUrls = await storageService.uploadListingImages(files);
        if (!mounted) return;
        final firestoreService = context.read<UserFirestoreService>();
        await firestoreService.saveCropListing( 
          title: _titleController.text,
          price: double.parse(_priceController.text),
          description: _descriptionController.text,
          quantity: double.parse(_quantityController.text),
          photoPaths: imageUrls,
          cropType: _cropType!,
          unit: _unit!,
          village: _villageController.text, 
          location: _location!, 
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Crop listed successfully')));
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Complete all fields and add photos')));
        if (mounted) setState(() => _isSubmitting = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sell Crop'),
        backgroundColor: const Color(0xFF0D47A1),
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              maxLength: 12,
              decoration: const InputDecoration(labelText: 'Title *'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            TextFormField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Price per unit *'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity *'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _cropType,
              hint: const Text('Crop Type'),
              items: _cropTypes.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _cropType = v),
              validator: (v) => v == null ? 'Required' : null,
            ),
            DropdownButtonFormField<String>(
              initialValue: _unit,
              hint: const Text('Unit'),
              items: _units.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) => setState(() => _unit = v),
            ),
            TextFormField(
              controller: _villageController, 
              maxLength: 15,
              decoration: const InputDecoration(labelText: 'Village / Location *'),
              validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
            ),
            TextFormField(
              controller: _descriptionController,
              maxLength: 100,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.add_photo_alternate),
              label: const Text('Add Photos (max 5)'),
            ),
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
                      Image.file(File(_pickedImages[index].path), fit: BoxFit.cover),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeImage(index),
                        ),
                      ),
                    ],
                  );
                },
              ),
            const SizedBox(height: 24),
            SafeArea(
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitCrop,
                child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) 
                : const Text('Submit Crop Listing'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
================================================================================
*/