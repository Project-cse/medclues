import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../routes/app_router.dart';
import '../services/app_deep_link_service.dart';

/// Starts deep-link handling once [GoRouter] is available.
class DeepLinkListener extends ConsumerStatefulWidget {
  const DeepLinkListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<DeepLinkListener> createState() => _DeepLinkListenerState();
}

class _DeepLinkListenerState extends ConsumerState<DeepLinkListener> {
  bool _started = false;

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppDeepLinkService.instance.start(ref.read(goRouterProvider));
      });
    }
    return widget.child;
  }

  @override
  void dispose() {
    AppDeepLinkService.instance.dispose();
    super.dispose();
  }
}
