// NEW FILE: F:\agrozemex\lib\features\crops\screens\crop_sell_screen.dart
import 'dart:io';
import 'package:agrozemex/shared/services/storage_service.dart';
import 'package:agrozemex/shared/services/user_firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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