import 'package:flutter/material.dart';

/// Soft 3-cycle horizontal shake for failed form validation (±6dp).
class ValidationShake extends StatefulWidget {
  const ValidationShake({
    super.key,
    required this.shake,
    required this.child,
    this.onComplete,
  });

  final bool shake;
  final Widget child;
  final VoidCallback? onComplete;

  @override
  State<ValidationShake> createState() => _ValidationShakeState();
}

class _ValidationShakeState extends State<ValidationShake> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _offset;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    _offset = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -6.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: -6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -6.0, end: 6.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 6.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _ctrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) widget.onComplete?.call();
    });
  }

  @override
  void didUpdateWidget(covariant ValidationShake oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shake && !oldWidget.shake) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      builder: (_, child) => Transform.translate(
        offset: Offset(_offset.value, 0),
        child: child,
      ),
      child: widget.child,
    );
  }
}
