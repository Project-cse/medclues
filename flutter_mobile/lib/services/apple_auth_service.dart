import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../utils/app_exception.dart';
import '../utils/firebase_error_message.dart';

/// Apple Sign-In service — works on iOS, Android, and Web.
/// Uses Firebase Auth as the backend so it integrates seamlessly
/// with the same socialLogin flow used for Google.
class AppleAuthService {
  /// Returns true on platforms where Apple Sign-In is available.
  /// On Android/Web the package shows a Safari web popup via Apple's JS SDK.
  static bool get isSupported => true;

  /// Generates a cryptographically secure nonce string.
  static String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)])
        .join();
  }

  /// Returns the SHA256 hash of [input] as a hex string.
  static String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Signs the user in with Apple via Firebase.
  /// Returns a [User] on success, throws [AppException] on failure/cancel.
  Future<User> signInWithApple() async {
    try {
      final rawNonce = _generateNonce();
      final nonce = _sha256ofString(rawNonce);

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: nonce,
      );

      // Build the full name from Apple's given parts (only sent on first sign-in).
      final displayName = [
        appleCredential.givenName,
        appleCredential.familyName,
      ].where((s) => s != null && s.isNotEmpty).join(' ');

      final oAuthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        rawNonce: rawNonce,
        accessToken: appleCredential.authorizationCode,
      );

      final result =
          await FirebaseAuth.instance.signInWithCredential(oAuthCredential);
      final user = result.user;

      if (user == null) {
        throw AppException.validation('Apple Sign-In failed: no user returned.');
      }

      // Apple only sends the display name on the very first sign-in.
      // If we got a name, update the Firebase profile so it sticks.
      if (displayName.isNotEmpty && (user.displayName == null || user.displayName!.isEmpty)) {
        await user.updateDisplayName(displayName);
        await user.reload();
      }

      return FirebaseAuth.instance.currentUser ?? user;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        throw AppException.validation('Sign-in cancelled');
      }
      throw AppException.validation('Apple Sign-In error: ${e.message}');
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.validation(firebaseAuthErrorMessage(e));
    }
  }
}
