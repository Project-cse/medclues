import 'package:flutter/material.dart';

import '../../brand/medclues_palette.dart';

/// Medical ticket unrolls vertically via ClipRect — printer-slot reveal.
class ReceiptUnroll extends StatefulWidget {
  const ReceiptUnroll({
    super.key,
    required this.child,
    this.autoPlay = true,
  });

  final Widget child;
  final bool autoPlay;

  @override
  State<ReceiptUnroll> createState() => _ReceiptUnrollState();
}

class _ReceiptUnrollState extends State<ReceiptUnroll> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _reveal;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _reveal = CurvedAnimation(parent: _ctrl, curve: MedcluesPalette.emphasized);
    if (widget.autoPlay) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _ctrl.forward());
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
      animation: _reveal,
      builder: (_, child) {
        return ClipRect(
          clipper: _ReceiptClipper(progress: _reveal.value),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class _ReceiptClipper extends CustomClipper<Rect> {
  _ReceiptClipper({required this.progress});

  final double progress;

  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width, size.height * progress);

  @override
  bool shouldReclip(covariant _ReceiptClipper old) => old.progress != progress;
}
