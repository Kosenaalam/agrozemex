import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'package:agrozemex/shared/services/storage_service.dart';
import 'package:agrozemex/shared/services/user_firestore_service.dart';
import 'package:agrozemex/shared/services/location_service.dart';
import 'package:agrozemex/features/auth/services/auth_service.dart';

class CropSellState {
  final List<XFile> pickedImages;
  final GeoPoint? location;
  final String locationStatus; // 'initial', 'fetching', 'success', 'denied'

  const CropSellState({
    this.pickedImages = const [],
    this.location,
    this.locationStatus = 'initial',
  });

  CropSellState copyWith({
    List<XFile>? pickedImages,
    GeoPoint? location,
    String? locationStatus,
  }) {
    return CropSellState(
      pickedImages: pickedImages ?? this.pickedImages,
      location: location ?? this.location,
      locationStatus: locationStatus ?? this.locationStatus,
    );
  }
}

class CropSellController extends AsyncNotifier<CropSellState> {
  final ImagePicker _picker = ImagePicker();

  @override
  Future<CropSellState> build() async {
    _fetchLocation();
    return const CropSellState();
  }

  Future<void> _fetchLocation() async {
    state = const AsyncValue.data(CropSellState(locationStatus: 'fetching'));

    final singleton = LocationService();
    if (singleton.currentPosition != null) {
      final loc = GeoPoint(
        singleton.currentPosition!.latitude,
        singleton.currentPosition!.longitude,
      );
      state = AsyncValue.data(state.value!.copyWith(location: loc, locationStatus: 'success'));
      return;
    }

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      state = AsyncValue.data(state.value!.copyWith(locationStatus: 'denied'));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        state = AsyncValue.data(state.value!.copyWith(locationStatus: 'denied'));
        return;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      state = AsyncValue.data(state.value!.copyWith(locationStatus: 'denied'));
      return;
    }

    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      ).timeout(const Duration(seconds: 5));
      state = AsyncValue.data(state.value!.copyWith(
        location: GeoPoint(position.latitude, position.longitude),
        locationStatus: 'success',
      ));
    } catch (_) {
      state = AsyncValue.data(state.value!.copyWith(locationStatus: 'denied'));
    }
  }

  void setManualLocation(double lat, double lng) {
    state = AsyncValue.data(state.value!.copyWith(
      location: GeoPoint(lat, lng),
      locationStatus: 'success',
    ));
  }

  Future<void> pickImages() async {
    if (state.value == null) return;
    final currentImages = state.value!.pickedImages;
    final availableSlots = 5 - currentImages.length;
    
    if (availableSlots <= 0) {
      return; // Handled in UI
    }

    // Apply imageQuality for production-grade bandwidth saving
    final List<XFile> selected = await _picker.pickMultiImage(
      imageQuality: 70, 
    );
    
    if (selected.isNotEmpty) {
      final newImages = List<XFile>.from(currentImages)..addAll(selected.take(availableSlots));
      state = AsyncValue.data(state.value!.copyWith(pickedImages: newImages));
    }
  }

  void removeImage(int index) {
    if (state.value == null) return;
    final currentImages = List<XFile>.from(state.value!.pickedImages);
    currentImages.removeAt(index);
    state = AsyncValue.data(state.value!.copyWith(pickedImages: currentImages));
  }

  void resetForm() {
    state = const AsyncValue.data(CropSellState());
    _fetchLocation();
  }

  Future<bool> submitCrop({
    required AuthService authService,
    required StorageService storageService,
    required UserFirestoreService firestoreService,
    required String title,
    required double price,
    required double quantity,
    required String description,
    required String cropType,
    required String unit,
    required String village,
    required String harvestStatus,
    required bool isOrganic,
  }) async {
    if (state.value == null) return false;
    final currentState = state.value!;
    
    // Set state to loading
    state = const AsyncValue.loading();
    
    try {
      final user = authService.user;
      if (user == null) throw Exception('User not logged in');
      
      final files = currentState.pickedImages.map((e) => File(e.path)).toList();
      final imageUrls = await storageService.uploadListingImages(files);
      
      // Use fallback location if denied, as user requested "allow" empty/default
      final loc = currentState.location ?? const GeoPoint(20.5937, 78.9629);

      await firestoreService.saveCropListing(
        uid: user.uid,
        title: title,
        price: price,
        description: description,
        quantity: quantity,
        photoPaths: imageUrls,
        cropType: cropType,
        unit: unit,
        village: village,
        location: loc,
        harvestStatus: harvestStatus,
        isOrganic: isOrganic,
      );
      
      // Success, restore to empty state
      state = const AsyncValue.data(CropSellState());
      return true;
    } catch (e, st) {
      // Restore previous state but with error
      state = AsyncValue.error(e, st);
      state = AsyncValue.data(currentState); // Restore so they can try again
      rethrow; // Rethrow to let UI catch and show snackbar
    }
  }
}

final cropSellControllerProvider = AsyncNotifierProvider<CropSellController, CropSellState>(() {
  return CropSellController();
});
