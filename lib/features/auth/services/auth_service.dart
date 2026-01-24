// F:\agrozemex\lib\features\auth\services\auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../../shared/services/user_firestore_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  bool isLoading = true;

  AuthService() {
    _auth.authStateChanges().listen((u) async {
      user = u;
      isLoading = false;
      if (u != null) {
        await UserFirestoreService().createUserIfNotExists(u);
      }
      notifyListeners();
    });
  }

  Future<void> sendOtp(String phone, Function(String) onCodeSent) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      codeSent: (id, _) => onCodeSent(id),
      verificationCompleted: (cred) async {
        await _auth.signInWithCredential(cred);
      },
      verificationFailed: (e) {
        throw e; // IMPROVED: Propagate error
      },
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> verifyOtp(String id, String otp) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: id,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      // FIXED: Specific handling
      if (e.code == 'invalid-verification-code') {
        throw 'Invalid OTP. Please try again.';
      } else if (e.code == 'session-expired') {
        throw 'OTP session expired. Request a new one.';
      } else {
        throw 'Authentication error: ${e.message}';
      }
    } catch (e) {
      throw 'Unexpected error: $e. Please try again.';
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
  }
}