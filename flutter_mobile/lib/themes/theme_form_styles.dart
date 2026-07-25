import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Single-outline input style (no filled inner box).
InputDecoration profileInputDecoration(
  BuildContext context, {
  String? hint,
  String? label,
}) {
  final cs = Theme.of(context).colorScheme;
  final outline = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: cs.outline),
  );
  final focused = OutlineInputBorder(
    borderRadius: BorderRadius.circular(12),
    borderSide: BorderSide(color: cs.primary, width: 1.5),
  );
  return InputDecoration(
    labelText: label,
    hintText: hint,
    filled: false,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    labelStyle: GoogleFonts.poppins(fontSize: 13, color: cs.onSurfaceVariant),
    hintStyle: GoogleFonts.poppins(fontSize: 14, color: cs.onSurfaceVariant),
    border: outline,
    enabledBorder: outline,
    focusedBorder: focused,
  );
}

TextStyle profileLabelStyle(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return GoogleFonts.poppins(fontSize: 13, color: cs.onSurfaceVariant);
}

TextStyle profileFieldTextStyle(BuildContext context) {
  final cs = Theme.of(context).colorScheme;
  return GoogleFonts.poppins(fontSize: 15, color: cs.onSurface);
}
