import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mapbox;
import 'package:provider/provider.dart';
import 'package:flutter/material.dart';

import 'package:agrozemex/features/auth/services/auth_service.dart';
import 'package:agrozemex/shared/services/storage_service.dart';
import 'package:agrozemex/shared/services/user_firestore_service.dart';

class ListingDetailsState {
  final bool isSubmitting;
  final String? error;

  const ListingDetailsState({
    this.isSubmitting = false,
    this.error,
  });

  ListingDetailsState copyWith({
    bool? isSubmitting,
    String? error,
  }) {
    return ListingDetailsState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: error,
    );
  }
}

class ListingDetailsController extends AsyncNotifier<ListingDetailsState> {
  @override
  Future<ListingDetailsState> build() async {
    return const ListingDetailsState();
  }

  Future<bool> submitListing({
    required BuildContext context,
    required List<XFile> pickedImages,
    required double areaInSqMeters,
    required List<mapbox.Point> boundaryPoints,
    required String title,
    required String rawPrice,
    required String description,
    required String village,
    required String soilType,
    required String waterSource,
    required bool roadAccess,
    required String listerType,
    required String landCategory,
    required String ownershipStatus,
    required bool electricityAvailable,
    required bool isFenced,
  }) async {
    if (state.value?.isSubmitting == true) return false;

    state = const AsyncValue.data(ListingDetailsState(isSubmitting: true));

    try {
      // Use Provider to get the legacy services since they are in AppRoot
      final storageService = context.read<StorageService>();
      final auth = context.read<AuthService>();
      final firestoreService = context.read<UserFirestoreService>();

      // 1. Upload Images
      final files = pickedImages.map((e) => File(e.path)).toList();
      final imageUrls = await storageService.uploadListingImages(files);

      // 2. Validate User
      if (auth.user == null) throw Exception('User not logged in');

      // 3. Parse Price
      final parsedPrice = double.tryParse(rawPrice.replaceAll(',', '').trim()) ?? 0.0;

      // 4. Save to Firestore
      await firestoreService.saveLandListing(
        uid: auth.user!.uid,
        title: title.trim(),
        price: parsedPrice,
        description: description.trim(),
        areaInSqMeters: areaInSqMeters,
        boundaryPoints: boundaryPoints,
        photoPaths: imageUrls,
        village: village.trim(),
        soilType: soilType,
        waterSource: waterSource,
        roadAccess: roadAccess,
        listerType: listerType,
        landCategory: landCategory,
        ownershipStatus: ownershipStatus,
        electricityAvailable: electricityAvailable,
        isFenced: isFenced,
      );

      state = const AsyncValue.data(ListingDetailsState(isSubmitting: false));
      return true;
    } catch (e) {
      state = AsyncValue.data(ListingDetailsState(
        isSubmitting: false,
        error: e.toString(),
      ));
      rethrow;
    }
  }
}

final listingDetailsControllerProvider =
    AsyncNotifierProvider<ListingDetailsController, ListingDetailsState>(
  () => ListingDetailsController(),
);
