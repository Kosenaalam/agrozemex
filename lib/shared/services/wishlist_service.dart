import 'package:cloud_firestore/cloud_firestore.dart';

class WishlistService {
  final FirebaseFirestore _db;

  WishlistService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  Future<void> toggleWishlist(String listingId, {required String uid}) async {
    if (uid.isEmpty) return;

    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .doc(listingId);

    final snap = await ref.get();

    if (snap.exists) {
      await ref.delete();
    } else {
      await ref.set({
        'created_at': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<bool> isWishlisted(String listingId, {required String uid}) {
    if (uid.isEmpty) return Stream.value(false);

    return _db
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .doc(listingId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<List<String>> getWishlistIds({required String uid}) {
    if (uid.isEmpty) return Stream.value([]);
    return _db
        .collection('users')
        .doc(uid)
        .collection('wishlist')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }
}
