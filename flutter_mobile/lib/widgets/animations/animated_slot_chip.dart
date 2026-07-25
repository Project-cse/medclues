import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../brand/medclues_palette.dart';
import '../../utils/theme_context.dart';

/// Expandable appointment slot — Deep Navy fill + check drops from top edge.
class AnimatedSlotChip extends StatelessWidget {
  const AnimatedSlotChip({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.width,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        curve: MedcluesPalette.emphasized,
        width: width,
        padding: EdgeInsets.symmetric(
          vertical: selected ? 14 : 12,
          horizontal: selected ? 10 : 8,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: !enabled
              ? (context.isDark ? const Color(0xFF334155) : MedcluesPalette.slate100)
              : selected
                  ? (context.isDark ? const Color(0xFF0C4A6E) : MedcluesPalette.deepNavy)
                  : context.cardColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? (context.isDark ? const Color(0xFF38BDF8) : MedcluesPalette.deepNavy)
                : context.borderColor,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: MedcluesPalette.deepNavy.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (selected)
              Positioned(
                top: -6,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: -12, end: 0),
                  duration: const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  builder: (_, y, child) => Transform.translate(offset: Offset(0, y), child: child),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: MedcluesPalette.medicalTeal,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, size: 12, color: Colors.white),
                  ),
                ),
              ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: !enabled
                    ? context.secondaryText
                    : selected
                        ? Colors.white
                        : context.primaryText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
