import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../common/language_selector.dart';
import '../common/force_light_theme.dart';
import 'login_blobs.dart';
import 'premium_login_theme.dart';

/// Login, signup, and forgot-password always use light theme (ignores app dark mode).
class LoginScreenShell extends StatelessWidget {
  const LoginScreenShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ForceLightTheme(
      child: Scaffold(
        backgroundColor: PremiumLoginTheme.background,
        resizeToAvoidBottomInset: !kIsWeb,
        body: SafeArea(
          child: Stack(
            children: [
              const LoginBlobs(),
              const Align(
                alignment: Alignment.topRight,
                child: LanguageSelectorCompact(),
              ),
              SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: child,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
