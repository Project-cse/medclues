import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/route_names.dart';
import '../emergency_constants.dart';

enum EmergencyHelpButtonStyle { fullWidth, compact, floating }

/// Reusable entry point into the emergency module — no login required.
class EmergencyHelpButton extends StatelessWidget {
  const EmergencyHelpButton({
    super.key,
    this.style = EmergencyHelpButtonStyle.fullWidth,
    this.margin,
    /// Use on splash/opening so the video screen is removed and cannot redirect in background.
    this.replaceRoute = false,
    this.showIcon = true,
  });

  final EmergencyHelpButtonStyle style;
  final EdgeInsetsGeometry? margin;
  final bool replaceRoute;
  final bool showIcon;

  void _open(BuildContext context) {
    if (replaceRoute) {
      context.go(RouteNames.emergency);
    } else {
      context.push(RouteNames.emergency);
    }
  }

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case EmergencyHelpButtonStyle.floating:
        return Positioned(
          right: 16,
          bottom: 24,
          child: _FloatingButton(onTap: () => _open(context)),
        );
      case EmergencyHelpButtonStyle.compact:
        return Padding(
          padding: margin ?? EdgeInsets.zero,
          child: _CompactButton(onTap: () => _open(context)),
        );
      case EmergencyHelpButtonStyle.fullWidth:
        return Padding(
          padding: margin ?? const EdgeInsets.symmetric(horizontal: 16),
          child: _FullWidthButton(onTap: () => _open(context), showIcon: showIcon),
        );
    }
  }
}

class _FullWidthButton extends StatelessWidget {
  const _FullWidthButton({required this.onTap, this.showIcon = true});

  final VoidCallback onTap;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EmergencyConstants.emergencyRed,
      borderRadius: BorderRadius.circular(16),
      elevation: 4,
      shadowColor: EmergencyConstants.emergencyRed.withValues(alpha: 0.4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (showIcon) ...[
                const Icon(Icons.emergency, color: Colors.white, size: 28),
                const SizedBox(width: 12),
              ],
              Text(
                'Emergency Help',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactButton extends StatelessWidget {
  const _CompactButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EmergencyConstants.emergencyRed,
      borderRadius: BorderRadius.circular(24),
      elevation: 6,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emergency, color: Colors.white, size: 20),
              const SizedBox(width: 6),
              Text(
                'SOS',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatingButton extends StatelessWidget {
  const _FloatingButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: EmergencyConstants.emergencyRed,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: EmergencyConstants.emergencyRed.withValues(alpha: 0.5),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 64,
          height: 64,
          child: Icon(Icons.emergency, color: Colors.white, size: 32),
        ),
      ),
    );
  }
}
