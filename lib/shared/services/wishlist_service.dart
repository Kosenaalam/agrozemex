import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> toggleWishlist(String listingId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _db
        .collection('users')
        .doc(user.uid)
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

  Stream<bool> isWishlisted(String listingId) {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(false);

    return _db
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .doc(listingId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<List<String>> getWishlistIds() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);
    return _db
        .collection('users')
        .doc(user.uid)
        .collection('wishlist')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.id).toList());
  }
}
