import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

ThemeData buildLightTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.medcluesTeal,
    primary: AppColors.medcluesTeal,
    secondary: AppColors.logoTeal,
    surface: AppColors.white,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.inputBorder,
    error: AppColors.error,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: colorScheme,
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.white,
      foregroundColor: AppColors.textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.white,
      indicatorColor: AppColors.medcluesTealLight,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selected ? AppColors.medcluesTeal : AppColors.textSecondary,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.medcluesTeal : AppColors.textSecondary,
        );
      }),
    ),
    cardTheme: CardThemeData(
      color: AppColors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.inputBorder),
      ),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.inputBorder, thickness: 1),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.textSecondary,
      textColor: AppColors.textPrimary,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: false,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
      hintStyle: GoogleFonts.poppins(color: AppColors.textHint),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.medcluesTeal, width: 1.5),
      ),
    ),
    textTheme: GoogleFonts.poppinsTextTheme(),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: GoogleFonts.poppins(color: Colors.white),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: AppColors.white),
    datePickerTheme: const DatePickerThemeData(
      backgroundColor: AppColors.white,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.medcluesTealLight,
      selectedColor: AppColors.medcluesTealLight,
      labelStyle: GoogleFonts.poppins(color: AppColors.textPrimary, fontSize: 12),
      side: const BorderSide(color: AppColors.inputBorder),
      checkmarkColor: AppColors.medcluesTeal,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: AppColors.medcluesTeal,
      unselectedLabelColor: AppColors.textSecondary,
      indicatorColor: AppColors.medcluesTeal,
      dividerColor: AppColors.inputBorder,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.medcluesTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.medcluesTeal),
    ),
  );
}
