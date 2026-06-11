import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../routes/route_names.dart';

/// Handles mediclues:// deep links from Telegram bot and other sources.
class AppDeepLinkService {
  AppDeepLinkService._();

  static final AppDeepLinkService instance = AppDeepLinkService._();

  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;
  bool _started = false;

  Future<void> start(GoRouter router) async {
    if (_started || kIsWeb) return;
    _started = true;

    void go(Uri uri) {
      final path = _routeForUri(uri);
      if (path == null) return;
      try {
        router.go(path);
      } catch (e) {
        if (kDebugMode) debugPrint('Deep link navigation failed: $e');
      }
    }

    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        Future.delayed(const Duration(milliseconds: 400), () => go(initial));
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Deep link initial: $e');
    }

    _sub = _appLinks.uriLinkStream.listen(go, onError: (Object e) {
      if (kDebugMode) debugPrint('Deep link stream: $e');
    });
  }

  void dispose() {
    _sub?.cancel();
    _sub = null;
    _started = false;
  }

  static String? _routeForUri(Uri uri) {
    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'mediclues' && scheme != 'medichain') return null;

    final host = uri.host.toLowerCase();
    if (host == 'dashboard' || host == 'home') {
      return RouteNames.dashboard;
    }

    if (host == 'open') {
      final segment = uri.pathSegments.isNotEmpty ? uri.pathSegments.first : '';
      switch (segment) {
        case 'dashboard':
        case 'home':
          return RouteNames.dashboard;
        case 'appointments':
          return RouteNames.appointments;
        case 'records':
          return '/records';
        case 'profile':
          return RouteNames.profile;
        case 'doctors':
          return RouteNames.doctors;
        case 'settings':
          return RouteNames.settings;
        default:
          return RouteNames.dashboard;
      }
    }

    return RouteNames.dashboard;
  }
}
