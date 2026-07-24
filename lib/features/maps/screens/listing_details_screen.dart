import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider/provider.dart';
import 'package:agrozemex/core/theme/theme.dart';
import 'package:agrozemex/features/auth/screens/login_screen.dart';
import 'package:agrozemex/shared/services/phone_binding_dialog.dart';
import 'package:agrozemex/shared/services/user_firestore_service.dart';
import '../../auth/services/auth_service.dart';
import '../controllers/listing_details_controller.dart';
import 'package:agrozemex/shared/widget/submit_progress_dialog.dart';

class ListingDetailsScreen extends ConsumerStatefulWidget {
  final List<mapbox.Point> boundaryPoints;
  final double areaInSqMeters;

  const ListingDetailsScreen({
    super.key,
    required this.boundaryPoints,
    required this.areaInSqMeters,
  });

  @override
  ConsumerState<ListingDetailsScreen> createState() => _ListingDetailsScreenState();
}

class _ListingDetailsScreenState extends ConsumerState<ListingDetailsScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _villageController = TextEditingController();

  String _listerType = 'Direct Owner';
  String _landCategory = 'Agricultural';
  String _ownershipStatus = 'Single Owner (Clear Title)';
  String _soilType = 'Alluvial';
  String _waterSource = 'Tube Well';

  bool _roadAccess = true;
  bool _electricityAvailable = false;
  bool _isFenced = false;

  final List<XFile> _pickedImages = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _listerTypes = [
    'Direct Owner',
    'Agent / Broker',
    'Builder / Developer',
  ];

  final List<String> _landCategories = [
    'Agricultural',
    'Orchard / Plantation',
    'Commercial / Industrial',
    'Barren / Fallow',
  ];

  final List<String> _ownershipStatuses = [
    'Single Owner (Clear Title)',
    'Joint / Family Property',
    'Power of Attorney',
  ];

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

  double get _acres => widget.areaInSqMeters / 4046.86;
  double get _bigha => widget.areaInSqMeters / 2529.3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPhoneVerificationGuard();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _villageController.dispose();
    super.dispose();
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

  void _showPhotoPickerSheet() {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add Land Photos (Max 10)',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AgroZemexTokens.primary,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AgroZemexTokens.primary),
              title: const Text('Take Photo with Camera'),
              onTap: () async {
                Navigator.pop(context);
                final XFile? image =
                    await _picker.pickImage(source: ImageSource.camera);
                if (image != null) {
                  _addImages([image]);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AgroZemexTokens.primary),
              title: const Text('Choose from Gallery'),
              onTap: () async {
                Navigator.pop(context);
                final List<XFile> images = await _picker.pickMultiImage();
                if (images.isNotEmpty) {
                  _addImages(images);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _addImages(List<XFile> images) {
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

  void _removeImage(int index) {
    setState(() {
      _pickedImages.removeAt(index);
    });
  }

  Future<void> _submitListing() async {
    final controllerState = ref.read(listingDetailsControllerProvider).asData?.value;
    if (controllerState?.isSubmitting == true) return;

    if (_pickedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least 1 land photo to publish listing.'),
          backgroundColor: AgroZemexTokens.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct form errors before submitting.'),
        ),
      );
      return;
    }

    // Show dynamic progress dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const SubmitProgressDialog(
        title: 'Publishing Land Listing',
      ),
    );

    try {
      final success = await ref.read(listingDetailsControllerProvider.notifier).submitListing(
        context: context,
        pickedImages: _pickedImages,
        areaInSqMeters: widget.areaInSqMeters,
        boundaryPoints: widget.boundaryPoints,
        title: _titleController.text,
        rawPrice: _priceController.text,
        description: _descriptionController.text,
        village: _villageController.text,
        soilType: _soilType,
        waterSource: _waterSource,
        roadAccess: _roadAccess,
        listerType: _listerType,
        landCategory: _landCategory,
        ownershipStatus: _ownershipStatus,
        electricityAvailable: _electricityAvailable,
        isFenced: _isFenced,
      );

      if (mounted) {
        Navigator.pop(context); // Close the progress dialog
      }

      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Land listing published successfully!'),
            backgroundColor: AgroZemexTokens.success,
          ),
        );
        // Important: Return true to tell MapScreen it was successful
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close the progress dialog
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error publishing listing: ${e.toString()}')),
        );
      }
    }
  }

  Future<bool?> _showDiscardDraftDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Discard Unsaved Draft?',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'You have unsaved land listing details. Going back will discard your draft and clear temporary images.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep Editing'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AgroZemexTokens.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Discard & Exit'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double currentPrice = 0.0;
    final parsed = double.tryParse(_priceController.text.replaceAll(',', ''));
    if (parsed != null && parsed > 0) {
      currentPrice = parsed;
    }
    final pricePerAcre = _acres > 0 ? (currentPrice / _acres) : 0.0;

    final bool hasUnsavedChanges = _pickedImages.isNotEmpty ||
        _titleController.text.trim().isNotEmpty ||
        _priceController.text.trim().isNotEmpty ||
        _villageController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty;

    final controllerState = ref.watch(listingDetailsControllerProvider);
    final isLoading = controllerState.asData?.value.isSubmitting ?? false;

    return PopScope(
      canPop: !isLoading && !hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop || isLoading) return;
        final shouldPop = await _showDiscardDraftDialog();
        if (shouldPop == true && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text(
          'Publish Land Listing',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: AgroZemexTokens.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        color: AgroZemexTokens.surfaceContainerLowest,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Section 1: Land Area & Measurement Summary Card
              _buildSectionCard(
                title: 'Land Area Measurement',
                icon: Icons.square_foot,
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildAreaStatItem(
                          label: 'ACRES',
                          value: _acres.toStringAsFixed(2),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: AgroZemexTokens.surfaceContainerLow,
                        ),
                        _buildAreaStatItem(
                          label: 'BIGHA',
                          value: _bigha.toStringAsFixed(2),
                        ),
                        Container(
                          width: 1,
                          height: 36,
                          color: AgroZemexTokens.surfaceContainerLow,
                        ),
                        _buildAreaStatItem(
                          label: 'SQ METERS',
                          value: widget.areaInSqMeters.toStringAsFixed(0),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 2: Property & Lister Overview Card
              _buildSectionCard(
                title: 'Property & Lister Details',
                icon: Icons.assignment_outlined,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _listerType,
                      decoration: InputDecoration(
                        labelText: 'Listed By *',
                        prefixIcon: const Icon(Icons.person_pin, color: AgroZemexTokens.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _listerTypes
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _listerType = v!),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _landCategory,
                      decoration: InputDecoration(
                        labelText: 'Land Usage Category *',
                        prefixIcon: const Icon(Icons.category, color: AgroZemexTokens.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _landCategories
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _landCategory = v!),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _ownershipStatus,
                      decoration: InputDecoration(
                        labelText: 'Legal Ownership Title *',
                        prefixIcon: const Icon(Icons.gavel, color: AgroZemexTokens.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _ownershipStatuses
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _ownershipStatus = v!),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _titleController,
                      maxLength: 50,
                      decoration: InputDecoration(
                        labelText: 'Land Listing Title *',
                        hintText: 'e.g. 5 Acre Fertile Farmland with Canal Water',
                        prefixIcon: const Icon(Icons.title, color: AgroZemexTokens.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Title is required';
                        if (v.trim().length < 5) return 'Title must be at least 5 chars';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Total Asking Price (₹) *',
                        prefixIcon: const Icon(Icons.currency_rupee, color: AgroZemexTokens.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Price is required';
                        final numVal = double.tryParse(v.replaceAll(',', '').trim());
                        if (numVal == null || numVal <= 0) {
                          return 'Enter a valid positive price';
                        }
                        return null;
                      },
                    ),
                    if (pricePerAcre > 0) ...[
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Estimated Price Per Acre: ₹ ${pricePerAcre.toStringAsFixed(0)} / Acre',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AgroZemexTokens.primary,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _villageController,
                      maxLength: 40,
                      decoration: InputDecoration(
                        labelText: 'Village / District Location *',
                        hintText: 'e.g. Anandpur Village, District Vadodara',
                        prefixIcon: const Icon(Icons.location_city, color: AgroZemexTokens.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Village is required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Detailed Description',
                        hintText: 'Describe soil quality, crop history, road distance...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 3: Agricultural Infrastructure & Specs
              _buildSectionCard(
                title: 'Infrastructure & Specifications',
                icon: Icons.tune,
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _soilType,
                      decoration: InputDecoration(
                        labelText: 'Soil Type *',
                        prefixIcon: const Icon(Icons.texture, color: AgroZemexTokens.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _soilTypes
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _soilType = v!),
                    ),
                    const SizedBox(height: 16),

                    DropdownButtonFormField<String>(
                      initialValue: _waterSource,
                      decoration: InputDecoration(
                        labelText: 'Water Source *',
                        prefixIcon: const Icon(Icons.water_drop, color: AgroZemexTokens.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _waterSources
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => _waterSource = v!),
                    ),
                    const SizedBox(height: 16),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Direct Road Access',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Property connects directly to asphalt/tar road'),
                      value: _roadAccess,
                      activeThumbColor: AgroZemexTokens.success,
                      activeTrackColor: AgroZemexTokens.success.withValues(alpha: 0.4),
                      onChanged: (v) => setState(() => _roadAccess = v),
                    ),
                    const Divider(),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        '3-Phase Electricity Available',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Agricultural power line for pumps & tube wells'),
                      value: _electricityAvailable,
                      activeThumbColor: AgroZemexTokens.success,
                      activeTrackColor: AgroZemexTokens.success.withValues(alpha: 0.4),
                      onChanged: (v) => setState(() => _electricityAvailable = v),
                    ),
                    const Divider(),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        'Fenced / Boundary Wall',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      subtitle: const Text('Barbed wire or brick boundary wall installed'),
                      value: _isFenced,
                      activeThumbColor: AgroZemexTokens.success,
                      activeTrackColor: AgroZemexTokens.success.withValues(alpha: 0.4),
                      onChanged: (v) => setState(() => _isFenced = v),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section 4: Photo Gallery Upload
              _buildSectionCard(
                title: 'Land Photo Gallery *',
                icon: Icons.photo_library_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Upload Land Photos',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AgroZemexTokens.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_pickedImages.length} / 10 Photos',
                            style: const TextStyle(
                              color: AgroZemexTokens.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _showPhotoPickerSheet,
                      icon: const Icon(Icons.add_a_photo),
                      label: Text(
                        'Add Photos (Camera or Gallery)',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AgroZemexTokens.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

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
                                borderRadius: BorderRadius.circular(10),
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
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              // Section 5: Submit Button
              SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submitListing,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AgroZemexTokens.success,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Publish Land Listing',
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AgroZemexTokens.radiusLargeCard,
        boxShadow: AgroZemexTokens.softShadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AgroZemexTokens.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AgroZemexTokens.primary,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildAreaStatItem({required String label, required String value}) {
    return Column(
      children: [
        Text(
          label,
          style: AgroZemexTokens.labelCaps.copyWith(
            fontSize: 10,
            color: AgroZemexTokens.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AgroZemexTokens.onSurface,
          ),
        ),
      ],
    );
  }
}
