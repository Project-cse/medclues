// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// PMS FNL 2 — Flutter Analysis Summary (from mobile/ + fastapi_back/)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// RN screens (patient path): ~20+ including auth, home, appointments,
// booking, profile, settings, notifications, records, payments
// Backend routers: 18 modules; patient APIs under /api/user, /api/doctor,
// /api/specialty/public/all, /api/ai/doctor-slots, /api/auth
// Auth: JWT HS256 (payload.id, 7-day exp), Authorization Bearer + token header
// Base URL: http://localhost:5000 (PORT from fastapi_back .env)
// Key flows: splash/auth → dashboard; login/register; doctor browse/search;
// book → confirm → success → receipt (PDF/share)
// App branding: MediChain+ (mobile/app.json)
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:medichain_mobile/l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'config/api_config.dart';
import 'firebase_options.dart';
import 'helpers/storage_helper.dart';
import 'providers/auth_provider.dart';
import 'providers/locale_provider.dart';
import 'providers/theme_provider.dart';
import 'onboarding/onboarding_manager.dart';
import 'routes/app_router.dart';
import 'services/api_service.dart';
import 'services/push_notification_service.dart';
import 'themes/app_theme.dart';
import 'utils/web_safe_media_query.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _loadEnv();
  await _initFirebase();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  if (kDebugMode) {
    debugPrint('MEDCLUES API: ${ApiConfig.baseUrl}');
  }

  const secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock_this_device),
  );
  final prefs = await SharedPreferences.getInstance();
  final storage = StorageHelper(secure, prefs);

  final api = ApiService.create(storage);

  final container = ProviderContainer(
    overrides: [
      storageHelperProvider.overrideWithValue(storage),
      apiServiceProvider.overrideWithValue(api),
    ],
  );

  api.bindUnauthorized(() async {
    await container.read(authProvider.notifier).logout();
  });

  PushNotificationService.instance.bind(api: api, navKey: rootNavigatorKey);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MedcluesApp(),
    ),
  );
}

/// Web cannot bundle dotfiles (`.env` → 404). Use `assets/config.env` instead.
Future<void> _loadEnv() async {
  const candidates = ['assets/config.env', '.env'];
  for (final path in candidates) {
    try {
      await dotenv.load(fileName: path);
      if (kDebugMode) debugPrint('Loaded env from $path');
      return;
    } catch (e) {
      if (kDebugMode) debugPrint('Env not loaded from $path ($e)');
    }
  }
  if (kDebugMode) {
    debugPrint('Using dart-define / platform defaults for API URL.');
  }
}

Future<void> _initFirebase() async {
  if (!DefaultFirebaseOptions.isGoogleSignInAvailable) {
    if (kDebugMode) {
      debugPrint('Firebase init skipped: Google Sign-In not configured for this platform');
    }
    return;
  }
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) debugPrint('Firebase initialized');
}

class MedcluesApp extends ConsumerWidget {
  const MedcluesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    return MaterialApp.router(
      title: 'MEDCLUES',
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        final body = child ?? const SizedBox.shrink();
        Widget wrapped = AnimatedTheme(
          data: Theme.of(context),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: body,
        );
        wrapped = OnboardingManager(child: wrapped);
        if (kIsWeb) {
          wrapped = WebSafeMediaQuery(child: wrapped);
        }
        return wrapped;
      },
    );
  }
}
