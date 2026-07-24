import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:provider/provider.dart';

import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/shared/services/storage_service.dart';
import 'package:agrozemex/shared/services/user_firestore_service.dart';
import 'package:agrozemex/features/auth/services/auth_service.dart';
import 'package:agrozemex/features/navigation/main_navigation_shell.dart';
import 'package:agrozemex/features/crops/controllers/crop_sell_controller.dart';
import 'package:agrozemex/features/maps/screens/location_picker_screen.dart'; // We will create this
import 'package:agrozemex/shared/widget/submit_progress_dialog.dart';

class CropSellScreen extends ConsumerStatefulWidget {
  final bool isActive;
  const CropSellScreen({super.key, this.isActive = true});

  @override
  ConsumerState<CropSellScreen> createState() => _CropSellScreenState();
}

class _CropSellScreenState extends ConsumerState<CropSellScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();
  
  String? _cropType;
  String? _unit = 'kg';
  String _harvestStatus = 'Ready for Pickup';
  bool _isOrganic = false;

  final List<String> _cropTypes = [
    'Wheat',
    'Rice',
    'Mustard',
    'Pulses',
    'Corn',
    'Vegetables',
    'Fruits',
    'Others',
  ];
  final List<String> _units = ['kg', 'ton', 'quintal'];
  final List<String> _harvestStatusOptions = [
    'Ready for Pickup',
    'Harvested Recently',
    'Standing Crop / Upcoming',
  ];

  bool get _hasUnsavedData {
    final images = ref.read(cropSellControllerProvider).value?.pickedImages ?? [];
    return images.isNotEmpty ||
      _titleController.text.trim().isNotEmpty ||
      _priceController.text.trim().isNotEmpty ||
      _quantityController.text.trim().isNotEmpty ||
      _descriptionController.text.trim().isNotEmpty ||
      _villageController.text.trim().isNotEmpty;
  }

  Future<bool> _showDiscardDialog() async {
    if (!_hasUnsavedData) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Discard Unsaved Draft?'),
        content: const Text(
          'You have unsaved harvest listing details. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep Editing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AgroZemexTokens.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Discard',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _resetForm() {
    _titleController.clear();
    _priceController.clear();
    _quantityController.clear();
    _descriptionController.clear();
    _villageController.clear();
    setState(() {
      _cropType = null;
      _unit = 'kg';
      _harvestStatus = 'Ready for Pickup';
      _isOrganic = false;
    });
    _formKey.currentState?.reset();
    ref.read(cropSellControllerProvider.notifier).resetForm();
  }

  Future<void> _handleClose() async {
    final wasDirty = _hasUnsavedData;
    final shouldDiscard = await _showDiscardDialog();
    if (!mounted || !shouldDiscard) return;
    
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      _resetForm();
      MainNavigationShell.of(context)?.switchTab(1); // Go to Home tab safely
      if (wasDirty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Draft discarded.')),
        );
      }
    }
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

  void _submitCrop() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final parsedPrice = double.parse(_priceController.text);
    final parsedQty = double.parse(_quantityController.text);

    final controllerState = ref.read(cropSellControllerProvider);
    if (controllerState.value?.pickedImages.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one photo')),
      );
      return;
    }

    // Show dynamic progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SubmitProgressDialog(
        title: 'Publishing Crop Listing',
      ),
    );

    try {
      final success = await ref.read(cropSellControllerProvider.notifier).submitCrop(
        authService: context.read<AuthService>(),
        storageService: context.read<StorageService>(),
        firestoreService: context.read<UserFirestoreService>(),
        title: _titleController.text,
        price: parsedPrice,
        quantity: parsedQty,
        description: _descriptionController.text,
        cropType: _cropType!,
        unit: _unit!,
        village: _villageController.text,
        harvestStatus: _harvestStatus,
        isOrganic: _isOrganic,
      );

      if (mounted) {
        Navigator.pop(context); // Close the progress dialog
      }

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Crop listed successfully')),
        );
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        } else {
          _resetForm();
          MainNavigationShell.of(context)?.switchTab(1); // Redirect to Crop Home
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close the progress dialog
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cropStateAsync = ref.watch(cropSellControllerProvider);
    final isLoading = cropStateAsync.isLoading;
    final cropState = cropStateAsync.value;
    final pickedImages = cropState?.pickedImages ?? [];
    final locationStatus = cropState?.locationStatus ?? 'initial';

    return PopScope(
      canPop: !widget.isActive || (!isLoading && !_hasUnsavedData),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || !widget.isActive || isLoading) return;
        await _handleClose();
      },
      child: Scaffold(
        backgroundColor: AgroZemexTokens.surface,
        appBar: AppBar(
          backgroundColor: AgroZemexTokens.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AgroZemexTokens.onSurface),
            onPressed: isLoading ? null : _handleClose,
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
              // Progress Header
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: const LinearProgressIndicator(
                  value: 1.0,
                  minHeight: 6,
                  backgroundColor: AgroZemexTokens.surfaceContainerLow,
                  color: AgroZemexTokens.primary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FINAL STEP',
                    style: AgroZemexTokens.labelCaps,
                  ),
                  Text(
                    'LISTING DETAILS & MEDIA',
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
                      enabled: !isLoading,
                      maxLength: 50,
                      style: AgroZemexTokens.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Title *',
                        hintText: 'e.g. Fresh Sharbati Wheat Grade A',
                        border: OutlineInputBorder(
                          borderRadius: AgroZemexTokens.radiusEight,
                        ),
                      ),
                      validator: (v) =>
                          v?.trim().isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: _priceController,
                            enabled: !isLoading,
                            keyboardType: TextInputType.number,
                            style: AgroZemexTokens.bodyLarge,
                            decoration: InputDecoration(
                              labelText: 'Price per unit (₹) *',
                              border: OutlineInputBorder(
                                borderRadius: AgroZemexTokens.radiusEight,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final p = double.tryParse(v);
                              if (p == null || p <= 0) return 'Must be > 0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _unit,
                            isExpanded: true,
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
                            onChanged: isLoading ? null : (v) {
                              if (v != null) setState(() => _unit = v);
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _quantityController,
                            enabled: !isLoading,
                            keyboardType: TextInputType.number,
                            style: AgroZemexTokens.bodyLarge,
                            decoration: InputDecoration(
                              labelText: 'Quantity *',
                              border: OutlineInputBorder(
                                borderRadius: AgroZemexTokens.radiusEight,
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Required';
                              final p = double.tryParse(v);
                              if (p == null || p <= 0) return 'Must be > 0';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _cropType,
                            isExpanded: true,
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
                            onChanged: isLoading ? null : (v) => setState(() => _cropType = v),
                            validator: (v) => v == null ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _villageController,
                      enabled: !isLoading,
                      maxLength: 50,
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
                          v?.trim().isEmpty ?? true ? 'Required' : null,
                    ),

                    const SizedBox(height: 16),

                    // Location Status Indication
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AgroZemexTokens.surfaceContainerLow,
                        borderRadius: AgroZemexTokens.radiusEight,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            locationStatus == 'success'
                                ? Icons.check_circle
                                : locationStatus == 'fetching'
                                    ? Icons.hourglass_empty
                                    : Icons.warning,
                            color: locationStatus == 'success'
                                ? Colors.green
                                : locationStatus == 'fetching'
                                    ? Colors.orange
                                    : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              locationStatus == 'success'
                                  ? 'GPS Coordinates acquired'
                                  : locationStatus == 'fetching'
                                      ? 'Acquiring GPS location...'
                                      : 'GPS unavailable / denied',
                              style: AgroZemexTokens.bodyMedium,
                            ),
                          ),
                          if (locationStatus == 'denied' || locationStatus == 'fetching')
                            TextButton(
                              onPressed: isLoading ? null : () async {
                                // Navigate to Map picker
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const LocationPickerScreen(),
                                  ),
                                );
                                if (result != null && result is Map<String, double>) {
                                  ref.read(cropSellControllerProvider.notifier)
                                     .setManualLocation(result['lat']!, result['lng']!);
                                }
                              },
                              child: const Text('Pick on Map'),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _harvestStatus,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Harvest Availability',
                        border: OutlineInputBorder(
                          borderRadius: AgroZemexTokens.radiusEight,
                        ),
                      ),
                      items: _harvestStatusOptions
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(e),
                            ),
                          )
                          .toList(),
                      onChanged: isLoading ? null : (v) {
                        if (v != null) setState(() => _harvestStatus = v);
                      },
                    ),

                    const SizedBox(height: 16),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeThumbColor: AgroZemexTokens.primary,
                      title: Text(
                        'Organic / Natural Farming',
                        style: AgroZemexTokens.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        'Check if crop is organic or chemical-free',
                        style: AgroZemexTokens.bodyMedium.copyWith(
                          color: AgroZemexTokens.onSurfaceVariant,
                        ),
                      ),
                      value: _isOrganic,
                      onChanged: isLoading ? null : (v) => setState(() => _isOrganic = v),
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      enabled: !isLoading,
                      maxLength: 300,
                      maxLines: 3,
                      style: AgroZemexTokens.bodyLarge,
                      decoration: InputDecoration(
                        labelText: 'Harvest Description',
                        hintText: 'Describe crop quality, moisture level, harvest date...',
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
                onTap: isLoading ? null : () => ref.read(cropSellControllerProvider.notifier).pickImages(),
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

              if (pickedImages.isNotEmpty) ...[
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
                  itemCount: pickedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Positioned.fill(
                          child: ClipRRect(
                            borderRadius: AgroZemexTokens.radiusEight,
                            child: Image.file(
                              File(pickedImages[index].path),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        if (!isLoading)
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
                                onPressed: () => ref.read(cropSellControllerProvider.notifier).removeImage(index),
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
                  onPressed: isLoading ? null : _submitCrop,
                  child: isLoading
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
      ),
    );
  }
}