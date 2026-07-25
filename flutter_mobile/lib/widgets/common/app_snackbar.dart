import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';

/// Premium floating toast — slides from top, auto dismiss.
class AppSnackbar {
  AppSnackbar._();

  static OverlayEntry? _current;

  static void show(BuildContext context, String message, {bool success = false}) {
    _current?.remove();
    _current = null;

    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _PremiumToast(
        message: message,
        success: success,
        onDismiss: () {
          entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _PremiumToast extends StatefulWidget {
  const _PremiumToast({
    required this.message,
    required this.success,
    required this.onDismiss,
  });

  final String message;
  final bool success;
  final VoidCallback onDismiss;

  @override
  State<_PremiumToast> createState() => _PremiumToastState();
}

class _PremiumToastState extends State<_PremiumToast> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 12;
    final bg = widget.success ? AppColors.success : AppColors.error;

    return Positioned(
      top: top,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: bg.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(
                widget.success ? Icons.check_circle_outline : Icons.info_outline,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  widget.message,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
              ),
              GestureDetector(
                onTap: widget.onDismiss,
                child: const Icon(Icons.close, color: Colors.white70, size: 20),
              ),
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 280.ms)
            .slideY(begin: -0.5, end: 0, duration: 350.ms, curve: Curves.easeOutCubic),
      ),
    );
  }
}
