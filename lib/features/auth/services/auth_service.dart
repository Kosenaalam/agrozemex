import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../shared/services/user_firestore_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  static const String googleWebClientId = '783000159900-du9p2ris69hsceubc4t0f9fcf4skne4h.apps.googleusercontent.com';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: googleWebClientId,
    serverClientId: googleWebClientId,
  );
  
  User? user;
  bool isLoading = true;
  StreamSubscription<User?>? _authSubscription;

  static const String _savedEmailKey = 'savedEmail';

  AuthService() {
    _initializeGoogleSignIn();
    _authSubscription = _auth.authStateChanges().listen((u) {
      user = u;
      isLoading = false;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initializeGoogleSignIn() async {
    try {
      await _googleSignIn.signInSilently();
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
      await UserFirestoreService().createUserIfNotExists(cred.user!);
      await saveEmailToPrefs(email);
    }
    return cred;
  }

  // --- Email & Password Sign Up ---
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) {
        await UserFirestoreService().createUserIfNotExists(cred.user!);
        await saveEmailToPrefs(email);
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'user-exists';
      }
      rethrow;
    }
  }

  // --- Password Reset ---
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint("Password reset error: $e");
      rethrow;
    }
  }

  Future<void> sendPasswordResetOtp(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint("Password reset OTP sending error: $e");
      rethrow;
    }
  }

  // --- Email Verification OTP Starter & Password Completion ---
  Future<void> sendEmailVerificationOtp(String email) async {
    try {
      final actionCodeSettings = ActionCodeSettings(
        url: 'https://agrozemex.firebaseapp.com',
        handleCodeInApp: true,
        androidPackageName: 'com.agrozemex.app',
        androidMinimumVersion: '1',
        androidInstallApp: true,
        iOSBundleId: 'com.agrozemex.app',
      );
      await _auth.sendSignInLinkToEmail(email: email, actionCodeSettings: actionCodeSettings);
    } catch (e) {
      debugPrint("Email verification OTP sending error: $e");
      rethrow;
    }
  }

  Future<UserCredential> completeSignupWithPassword(
    String email,
    String password,
    String otpVerificationContext,
  ) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      if (cred.user != null) {
        await UserFirestoreService().createUserIfNotExists(cred.user!);
        await saveEmailToPrefs(email);
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        throw 'user-exists';
      }
      rethrow;
    }
  }

  // --- Google Sign In ---
  Future<UserCredential?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return null;
      }
      final googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final cred = await _auth.signInWithCredential(credential);
      if (cred.user != null) {
        await UserFirestoreService().createUserIfNotExists(cred.user!);
        if (cred.user!.email != null) {
          await saveEmailToPrefs(cred.user!.email!);
        }
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw 'An account already exists with the same email address but different sign-in credentials. Please sign in using a provider associated with this email.';
      }
      debugPrint("Google sign-in error: $e");
      rethrow;
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
      if (cred.user != null) {
        await UserFirestoreService().createUserIfNotExists(cred.user!);
        if (cred.user!.email != null) {
          await saveEmailToPrefs(cred.user!.email!);
        }
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'account-exists-with-different-credential') {
        throw 'An account already exists with the same email address but different sign-in credentials. Please sign in using a provider associated with this email.';
      }
      debugPrint("Apple sign-in error: $e");
      rethrow;
    } catch (e) {
      debugPrint("Apple sign-in error: $e");
      rethrow;
    }
  }

  static const String _savedPhoneKey = 'savedPhone';

  // --- Phone OTP Authentication ---
  Future<void> sendOtp({
    required String phone,
    required Function(String verificationId, int? resendToken) onCodeSent,
    required Function(String errorMessage) onError,
    int? forceResendingToken,
  }) async {
    final formattedPhone = phone.startsWith('+') ? phone : '+$phone';
    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: formattedPhone,
        forceResendingToken: forceResendingToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential cred) async {
          try {
            final userCred = await _auth.signInWithCredential(cred);
            if (userCred.user != null) {
              await UserFirestoreService().createUserIfNotExists(userCred.user!);
              if (userCred.user!.phoneNumber != null) {
                await savePhoneToPrefs(userCred.user!.phoneNumber!);
              }
            }
          } catch (e) {
            debugPrint("Auto verification sign-in failed: $e");
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          debugPrint("Phone verification failed: ${e.code} - ${e.message}");
          String message = 'Verification failed. Please try again.';
          if (e.code == 'invalid-phone-number') {
            message = 'The entered phone number is invalid.';
          } else if (e.code == 'too-many-requests') {
            message = 'Too many requests. Please try again later.';
          } else if (e.code == 'quota-exceeded') {
            message = 'SMS quota exceeded. Please contact support.';
          } else if (e.code == 'captcha-check-failed') {
            message = 'reCAPTCHA verification failed. Please try again.';
          } else if (e.message != null && e.message!.isNotEmpty) {
            message = e.message!;
          }
          onError(message);
        },
        codeSent: (String verificationId, int? resendToken) {
          onCodeSent(verificationId, resendToken);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint("OTP auto retrieval timeout for $verificationId");
        },
      );
    } catch (e) {
      onError("Failed to send OTP: ${e.toString()}");
    }
  }

  Future<UserCredential> verifyOtp(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      final cred = await _auth.signInWithCredential(credential);
      if (cred.user != null) {
        await UserFirestoreService().createUserIfNotExists(cred.user!);
        if (cred.user!.phoneNumber != null) {
          await savePhoneToPrefs(cred.user!.phoneNumber!);
        }
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-verification-code') {
        throw 'Invalid OTP. Please check the code and try again.';
      } else if (e.code == 'session-expired') {
        throw 'OTP session expired. Please request a new code.';
      } else {
        throw e.message ?? 'Authentication failed.';
      }
    } catch (e) {
      throw 'Unexpected error during verification. Please try again.';
    }
  }

  // --- SharedPreferences persistent email & phone storage ---
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

  Future<void> savePhoneToPrefs(String phone) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_savedPhoneKey, phone);
  }

  Future<String?> getSavedPhoneFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_savedPhoneKey);
  }

  Future<void> clearSavedPhone() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_savedPhoneKey);
  }

  // --- Sign Out ---
  Future<void> logout() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await clearSavedEmail();
    await clearSavedPhone();
  }
}