import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'app_exception.dart';

/// Safe Firebase error text on web (avoid casting to [FirebaseAuthException]).
String firebaseAuthErrorMessage(Object error, {String fallback = 'Google sign-in failed'}) {
  if (error is AppException) return error.message;
  if (!kIsWeb && error is FirebaseAuthException) {
    return _mapAuthCode(error);
  }
  final text = error.toString();
  if (text.contains('popup-closed-by-user') || text.contains('cancelled')) {
    return 'Sign-in cancelled';
  }
  if (text.contains('popup-blocked')) {
    return 'Popup was blocked. Allow popups for this site.';
  }
  if (error is PlatformException) {
    return _mapPlatformException(error);
  }
  if (text.contains('ApiException: 10') ||
      text.contains('DEVELOPER_ERROR') ||
      text.contains('code 10')) {
    return 'Google Sign-In setup error. Add your Android SHA-1 in Firebase Console, '
        'download a new google-services.json, then rebuild the app. '
        'Run: .\\get_android_sha.ps1';
  }
  if (text.contains('operation-not-allowed')) {
    return 'Google Sign-In is not enabled in Firebase Console.';
  }
  if (text.contains('auth/invalid-api-key') || text.contains('configuration-not-found')) {
    return 'Firebase configuration error. Check config.env and Firebase Console.';
  }
  if (text.contains('JavaScriptObject')) {
    return 'Google sign-in failed. Restart the app and try again.';
  }
  if (text.length > 120) return fallback;
  return text.replaceFirst('Exception: ', '').replaceFirst('Error: ', '');
}

String _mapPlatformException(PlatformException e) {
  final code = e.code;
  if (code == 'sign_in_failed' || code == '10') {
    return 'Google Sign-In failed (SHA-1 missing in Firebase). '
        'Firebase Console → Project Settings → Android app → Add fingerprint → '
        'replace android/app/google-services.json → flutter run.';
  }
  if (code == 'sign_in_canceled' || code == '12501') {
    return 'Sign-in cancelled';
  }
  final msg = e.message ?? '';
  if (msg.contains('10') || msg.contains('DEVELOPER_ERROR')) {
    return 'Add Android SHA-1 to Firebase (mediclues-e39db). Run .\\get_android_sha.ps1 in flutter_mobile.';
  }
  return msg.isNotEmpty ? msg : 'Google sign-in failed';
}

String _mapAuthCode(FirebaseAuthException e) {
  switch (e.code) {
    case 'account-exists-with-different-credential':
      return 'An account already exists with a different sign-in method.';
    case 'invalid-credential':
      return 'Invalid Google credentials. Check Firebase setup (SHA-1 on Android).';
    case 'operation-not-allowed':
      return 'Google Sign-In is not enabled in Firebase Console.';
    case 'popup-closed-by-user':
      return 'Sign-in cancelled';
    case 'popup-blocked':
      return 'Popup was blocked. Allow popups for this site.';
    case 'user-disabled':
      return 'This account has been disabled.';
    case 'invalid-verification-code':
      return 'Incorrect code. Please check the SMS and try again.';
    case 'invalid-verification-id':
    case 'session-expired':
      return 'The code expired. Please request a new one.';
    case 'invalid-phone-number':
      return 'Enter a valid phone number.';
    case 'too-many-requests':
    case 'quota-exceeded':
      return 'Too many attempts. Please try again later.';
    case 'missing-client-identifier':
    case 'app-not-authorized':
      return 'Phone verification setup error. Add the app SHA-1/SHA-256 in Firebase Console.';
    default:
      return e.message ?? 'Verification failed';
  }
}
