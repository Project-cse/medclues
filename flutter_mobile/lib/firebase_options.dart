// Firebase options for MedClues (project: mediclues-e39db).
// Web values match frontend/.env; Android from google-services.json.
// iOS: set FIREBASE_*_IOS in assets/config.env after adding iOS app in Firebase.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      if (!webConfigured) {
        throw UnsupportedError('Firebase web is not configured in config.env');
      }
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        if (!iosConfigured) {
          throw UnsupportedError(
            'Firebase iOS is not configured. Add FIREBASE_APP_ID_IOS to config.env '
            'and GoogleService-Info.plist to ios/Runner/.',
          );
        }
        return ios;
      default:
        throw UnsupportedError('Firebase is not supported on this platform.');
    }
  }

  static bool get isGoogleSignInAvailable {
    if (kIsWeb) return webConfigured;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return true;
      case TargetPlatform.iOS:
        return iosConfigured;
      default:
        return false;
    }
  }

  static bool get webConfigured => web.appId.isNotEmpty;

  static bool get iosConfigured {
    final id = _env('FIREBASE_APP_ID_IOS');
    return id != null && id.isNotEmpty;
  }

  static String? _env(String key) {
    if (!dotenv.isInitialized) return null;
    final v = dotenv.env[key]?.trim();
    return (v != null && v.isNotEmpty) ? v : null;
  }

  static const String googleWebClientId =
      '675557370566-c9jkgqf6pl58e3i1ftjb765lv0akmf1g.apps.googleusercontent.com';

  /// iOS URL scheme for Google Sign-In (REVERSED_CLIENT_ID from Web client).
  static const String iosGoogleUrlScheme =
      'com.googleusercontent.apps.675557370566-c9jkgqf6pl58e3i1ftjb765lv0akmf1g';

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyC_CxTOYgWiWL04oc385OF6n_3CozOEwiw',
    appId: '1:675557370566:android:4dff6f066786e9f916c5c7',
    messagingSenderId: '675557370566',
    projectId: 'mediclues-e39db',
    storageBucket: 'mediclues-e39db.firebasestorage.app',
  );

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _env('FIREBASE_API_KEY_WEB') ?? 'AIzaSyDcWZzA1WD0NjgldHlmd8upGa8ywWbCDxg',
        appId: _env('FIREBASE_APP_ID_WEB') ?? '1:675557370566:web:c753723cef28de0416c5c7',
        messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID') ?? '675557370566',
        projectId: _env('FIREBASE_PROJECT_ID') ?? 'mediclues-e39db',
        storageBucket:
            _env('FIREBASE_STORAGE_BUCKET') ?? 'mediclues-e39db.firebasestorage.app',
        authDomain: _env('FIREBASE_AUTH_DOMAIN') ?? 'mediclues-e39db.firebaseapp.com',
        measurementId: _env('FIREBASE_MEASUREMENT_ID') ?? 'G-E7S46B7445',
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _env('FIREBASE_API_KEY_IOS') ?? '',
        appId: _env('FIREBASE_APP_ID_IOS') ?? '',
        messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID') ?? '675557370566',
        projectId: _env('FIREBASE_PROJECT_ID') ?? 'mediclues-e39db',
        storageBucket:
            _env('FIREBASE_STORAGE_BUCKET') ?? 'mediclues-e39db.firebasestorage.app',
        iosBundleId: 'com.medichain.medichainMobile',
      );
}
