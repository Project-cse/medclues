import 'package:flutter/material.dart';

/// Clamps negative [MediaQuery] insets on Flutter Web (keyboard dismiss / resize).
class WebSafeMediaQuery extends StatelessWidget {
  const WebSafeMediaQuery({super.key, required this.child});

  final Widget child;

  static EdgeInsets _clamp(EdgeInsets e) => EdgeInsets.fromLTRB(
        e.left.clamp(0, double.infinity),
        e.top.clamp(0, double.infinity),
        e.right.clamp(0, double.infinity),
        e.bottom.clamp(0, double.infinity),
      );

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return MediaQuery(
      data: mq.copyWith(
        viewInsets: _clamp(mq.viewInsets),
        viewPadding: _clamp(mq.viewPadding),
        padding: _clamp(mq.padding),
      ),
      child: child,
    );
  }
}
