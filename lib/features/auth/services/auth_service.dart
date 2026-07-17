import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/services/user_firestore_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const bool useSimulatedOtp = false;
  static const String googleWebClientId = '783000159900-du9p2ris69hsceubc4t0f9fcf4skne4h.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  
  User? user;
  bool isLoading = true;

  String? _simulatedOtp;
  String? _simulatedOtpEmail;
  static const String _savedEmailKey = 'savedEmail';

  AuthService() {
    _initializeGoogleSignIn();
    _auth.authStateChanges().listen((u) async {
      user = u;
      isLoading = false;
      if (u != null) {
        await UserFirestoreService().createUserIfNotExists(u);
      }
      notifyListeners();
    });
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.initialize(
        serverClientId: googleWebClientId,
      );
      await _googleSignIn.attemptLightweightAuthentication();
    } catch (e) {
      debugPrint("Failed to silently sign in GoogleSignIn: $e");
    }
  }

  // --- Check if email exists in Firestore ---
  Future<bool> checkIfUserExists(String email) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint("Error checking user existence: $e");
      return false;
    }
  }

  // --- Email & Password Sign In ---
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      await saveEmailToPrefs(email);
    }
    return cred;
  }

  // --- Email & Password Sign Up ---
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      await saveEmailToPrefs(email);
    }
    return cred;
  }

  // --- Google Sign In ---
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.authenticate();
      final googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      if (cred.user != null && cred.user!.email != null) {
        await saveEmailToPrefs(cred.user!.email!);
      }
      return cred;
    } catch (e) {
      debugPrint("Google sign-in error: $e");
      rethrow;
    }
  }

  // --- Apple Sign In ---
  Future<UserCredential?> signInWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final AuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final cred = await _auth.signInWithCredential(credential);
      if (cred.user != null && cred.user!.email != null) {
        await saveEmailToPrefs(cred.user!.email!);
      }
      return cred;
    } catch (e) {
      debugPrint("Apple sign-in error: $e");
      rethrow;
    }
  }

  // --- Simulated Email OTP ---
  Future<void> sendSimulatedEmailOtp(String email) async {
    final random = Random();
    final code = (100000 + random.nextInt(900000)).toString();
    _simulatedOtp = code;
    _simulatedOtpEmail = email;
    
    // Print the OTP in a clearly visible developer debug banner
    debugPrint("\n==============================================");
    debugPrint("DEVELOPER EMAIL OTP SIMULATOR");
    debugPrint("To Email: $email");
    debugPrint("OTP Code: $code");
    debugPrint("==============================================\n");
  }

  Future<bool> verifySimulatedEmailOtp(String email, String otp) async {
    if (_simulatedOtp == otp && _simulatedOtpEmail == email) {
      _simulatedOtp = null;
      _simulatedOtpEmail = null;
      return true;
    }
    return false;
  }

  // --- Phone OTP (legacy support) ---
  Future<void> sendOtp(String phone, Function(String) onCodeSent) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phone,
      codeSent: (id, _) => onCodeSent(id),
      verificationCompleted: (cred) async {
        await _auth.signInWithCredential(cred);
      },
      verificationFailed: (e) {
        throw e; 
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
      if (e.code == 'invalid-verification-code') {
        throw 'Invalid OTP. Please try again.';
      } else if (e.code == 'session-expired') {
        throw 'OTP session expired. Request a new one.';
      } else {
        throw 'Authentication error.';
      }
    } catch (e) {
      throw 'Unexpected error. Please try again.';
    }
  }

  // --- SharedPreferences persistent email storage ---
  Future<void> saveEmailToPrefs(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedEmailKey, email);
  }

  Future<String?> getSavedEmailFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedEmailKey);
  }

  Future<void> clearSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedEmailKey);
  }

  // --- Sign Out ---
  Future<void> logout() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await clearSavedEmail();
  }
}