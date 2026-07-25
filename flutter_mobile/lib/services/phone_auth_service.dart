import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';
import '../utils/app_exception.dart';
import '../utils/firebase_error_message.dart';

/// Firebase phone (SMS OTP) verification used during signup.
///
/// Flow: [sendOtp] triggers an SMS and returns a verification id; the user
/// types the 6-digit code into [confirmOtp], which returns a Firebase ID token
/// carrying the verified `phone_number` claim. That token is sent to the
/// backend, which verifies it and marks the phone as verified.
class PhoneAuthService {
  /// Phone OTP uses the native flow on Android/iOS. Web needs a separate
  /// RecaptchaVerifier flow, so it is disabled there for now.
  static bool get isSupportedPlatform {
    if (kIsWeb) return false;
    return DefaultFirebaseOptions.isGoogleSignInAvailable &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);
  }

  /// Normalize to E.164. Indian numbers default to +91 when no country code.
  static String formatPhone(String raw, {String defaultCountryCode = '+91'}) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('+')) {
      return '+${trimmed.substring(1).replaceAll(RegExp(r'[^0-9]'), '')}';
    }
    final digits = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    final national = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    return '$defaultCountryCode$national';
  }

  /// Sends an OTP. Returns a [verificationId] to pass to [confirmOtp].
  /// If the platform auto-retrieves the code, [onAutoVerified] fires with the
  /// resulting ID token and the returned verificationId may be unused.
  Future<String> sendOtp(
    String phoneNumber, {
    void Function(String idToken)? onAutoVerified,
  }) async {
    if (!isSupportedPlatform) {
      throw AppException.validation('Phone verification is not available on this device');
    }

    final completer = Completer<String>();

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: PhoneAuthService.formatPhone(phoneNumber),
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Android instant/auto retrieval — sign in and hand back the token.
        try {
          final token = await _signInAndGetToken(credential);
          if (token != null) onAutoVerified?.call(token);
        } catch (_) {
          // Ignore — user can still enter the code manually.
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        if (!completer.isCompleted) {
          completer.completeError(AppException.validation(firebaseAuthErrorMessage(e)));
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (!completer.isCompleted) completer.complete(verificationId);
      },
    );

    return completer.future;
  }

  /// Confirms the SMS code and returns the Firebase ID token (with phone claim).
  Future<String> confirmOtp(String verificationId, String smsCode) async {
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode.trim(),
      );
      final token = await _signInAndGetToken(credential);
      if (token == null || token.isEmpty) {
        throw AppException.validation('Could not verify the code. Please try again.');
      }
      return token;
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.validation(firebaseAuthErrorMessage(e));
    }
  }

  Future<String?> _signInAndGetToken(PhoneAuthCredential credential) async {
    final result = await FirebaseAuth.instance.signInWithCredential(credential);
    final token = await result.user?.getIdToken();
    // We only needed the token; drop the transient Firebase phone session.
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
    return token;
  }
}
