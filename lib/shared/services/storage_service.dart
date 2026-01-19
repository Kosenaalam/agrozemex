import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';


class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Upload multiple images and return their download URLs
  Future<List<String>> uploadListingImages(List<File> images) async {
    final List<String> downloadUrls = [];
    final String uid = _auth.currentUser!.uid;
    final String listingId = DateTime.now().millisecondsSinceEpoch.toString();

    for (int i = 0; i < images.length; i++) {
      final ref = _storage.ref(
        'listings/$uid/$listingId/image_$i.jpg',
      );

      final uploadTask = await ref.putFile(images[i]);
      final url = await uploadTask.ref.getDownloadURL();
      downloadUrls.add(url);
    }

    return downloadUrls;
  }
}
