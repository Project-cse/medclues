import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../routes/route_names.dart';

/// Handles medclues:// (and legacy mediclues/medichain) deep links.
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
    if (scheme != 'medclues' &&
        scheme != 'mediclues' &&
        scheme != 'medichain') {
      return null;
    }

    final host = uri.host.toLowerCase();
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();

    // Checkout return: {scheme}://payment?cancelled=1|failed=1
    if (host == 'payment') {
      final cancelled = uri.queryParameters['cancelled'] == '1';
      final failed = uri.queryParameters['failed'] == '1';
      if (cancelled) {
        return '${RouteNames.appointments}?payment=cancelled';
      }
      if (failed) {
        return '${RouteNames.appointments}?payment=failed';
      }
      return '${RouteNames.appointments}?payment=success';
    }

    if (host == 'open' && segments.isNotEmpty) {
      if (segments.first == 'appointments') {
        if (segments.length >= 2) {
          return '/appointments/${segments[1]}';
        }
        return RouteNames.appointments;
      }
      switch (segments.first) {
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

    if (host == 'dashboard' || host == 'home') {
      return RouteNames.dashboard;
    }

    return RouteNames.dashboard;
  }
}
