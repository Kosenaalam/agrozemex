import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';


class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

//   Future<List<String>> uploadListingImages(List<File> images) async {
//     final List<String> downloadUrls = [];
//     final String uid = _auth.currentUser!.uid;
//     final String listingId = DateTime.now().millisecondsSinceEpoch.toString();

//     for (int i = 0; i < images.length; i++) {
//       print("Uploading image $i...");
//       final ref = _storage.ref(
//         'listings/$uid/$listingId/image_$i.jpg',
//       );
//       //-----removable

//       final file = images[i];

// if (!await file.exists()) {
//   print("FILE DOES NOT EXIST ❌: ${file.path}");
//   continue;
// }
// //------------
//    try{
//       final uploadTask = await ref.putFile(images[i]);
//       final url = await uploadTask.ref.getDownloadURL();
//       downloadUrls.add(url);
//    } catch (e) {
//      print("STORAGE ERROR ❌: $e");
//   throw Exception("Image upload failed");
//    }
//     }

//     return downloadUrls;
//   }

Future<List<String>> uploadListingImages(List<File> images) async {
  final String uid = _auth.currentUser!.uid;
  final String listingId = DateTime.now().millisecondsSinceEpoch.toString();

  final uploadTasks = List.generate(images.length, (i) async {
    final file = images[i];

    if (!await file.exists()) {
      print("FILE DOES NOT EXIST ❌: ${file.path}");
      return null;
    }

    try {
      print("Uploading image $i in parallel...");
      final ref = _storage.ref('listings/$uid/$listingId/image_$i.jpg');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
      );

      final uploadTask = await ref.putFile(file, metadata);
      final url = await uploadTask.ref.getDownloadURL();

      print("UPLOAD SUCCESS ✅: $url");
      return url;
    } catch (e) {
      print("STORAGE ERROR ❌: $e");
      throw Exception("Image upload failed");
    }
  });

  final results = await Future.wait(uploadTasks);
  return results.whereType<String>().toList();
}
}
