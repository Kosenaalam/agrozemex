import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserFirestoreService {
  final _db = FirebaseFirestore.instance;

  Future<void> createUserIfNotExists(User user) async {
    final ref = _db.collection('users').doc(user.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'uid': user.uid,
        'phone': user.phoneNumber,
        'createdAt': DateTime.now(),
      });
    }
  }
}
