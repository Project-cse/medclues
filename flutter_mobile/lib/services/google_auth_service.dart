import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import '../utils/app_exception.dart';
import '../utils/firebase_error_message.dart';

/// Google Sign-In: web uses Firebase popup (reliable idToken); mobile uses google_sign_in.
class GoogleAuthService {
  GoogleSignIn? _googleSignIn;

  GoogleSignIn get _mobileGoogleSignIn {
    return _googleSignIn ??= GoogleSignIn(
      scopes: const ['email'],
      serverClientId: _resolveWebClientId(),
    );
  }

  static String _resolveWebClientId() {
    if (dotenv.isInitialized) {
      final fromEnv = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim() ?? '';
      final looksPlaceholder = fromEnv.contains('YOUR_GOOGLE') ||
          fromEnv == 'YOUR_GOOGLE_WEB_CLIENT_ID.apps.googleusercontent.com';
      if (fromEnv.isNotEmpty && !looksPlaceholder) return fromEnv;
    }
    return DefaultFirebaseOptions.googleWebClientId;
  }

  static bool get isSupportedPlatform => DefaultFirebaseOptions.isGoogleSignInAvailable;

  static String? get setupHint {
    if (isSupportedPlatform) return null;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return 'Add iOS app in Firebase, copy FIREBASE_APP_ID_IOS to config.env, '
          'and add GoogleService-Info.plist to ios/Runner/.';
    }
    return 'Firebase Google Sign-In is not configured for this platform.';
  }

  Future<User> signInWithGoogle() async {
    if (!isSupportedPlatform) {
      throw AppException.validation(setupHint ?? 'Google Sign-In unavailable');
    }
    try {
      if (kIsWeb) {
        return await _signInWeb();
      }
      return await _signInMobile();
    } on AppException {
      rethrow;
    } catch (e) {
      throw AppException.validation(firebaseAuthErrorMessage(e));
    }
  }

  /// Firebase popup — provides idToken on web (google_sign_in.signIn does not).
  Future<User> _signInWeb() async {
    final provider = GoogleAuthProvider();
    provider.setCustomParameters({'prompt': 'select_account'});
    final result = await FirebaseAuth.instance.signInWithPopup(provider);
    final user = result.user;
    if (user == null || user.email == null || user.email!.isEmpty) {
      throw AppException.validation('Google account has no email');
    }
    return user;
  }

  Future<User> _signInMobile() async {
    final account = await _mobileGoogleSignIn.signIn();
    if (account == null) {
      throw AppException.validation('Sign-in cancelled');
    }

    final auth = await account.authentication;
    if (auth.idToken == null || auth.idToken!.isEmpty) {
      throw AppException.validation(
        'Google did not return an ID token. Check Firebase and OAuth client setup.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: auth.accessToken,
      idToken: auth.idToken,
    );

    final result = await FirebaseAuth.instance.signInWithCredential(credential);
    final user = result.user;
    if (user == null || user.email == null || user.email!.isEmpty) {
      throw AppException.validation('Google account has no email');
    }
    return user;
  }

  Future<void> signOut() async {
    final futures = <Future<void>>[FirebaseAuth.instance.signOut()];
    if (!kIsWeb) {
      futures.add(_mobileGoogleSignIn.signOut());
    }
    await Future.wait(futures);
  }
}
