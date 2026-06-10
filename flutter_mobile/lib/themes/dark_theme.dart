import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';

ThemeData buildDarkTheme() {
  const bg = Color(0xFF000000);
  const surface = Color(0xFF1A1A1A);
  const surfaceHigh = Color(0xFF2A2A2A);
  const onSurface = Color(0xFFF5F5F5);
  const onVariant = Color(0xFFB0B0B0);
  const outline = Color(0xFF2E2E2E);

  final colorScheme = const ColorScheme.dark(
    primary: Color(0xFF38BDF8),
    onPrimary: Color(0xFF000000),
    secondary: AppColors.brandCyan,
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: onVariant,
    outline: outline,
    error: AppColors.error,
  );

  final baseText = GoogleFonts.poppinsTextTheme(
    ThemeData(brightness: Brightness.dark).textTheme,
  ).apply(bodyColor: onSurface, displayColor: onSurface);

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: colorScheme,
    textTheme: baseText,
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: onSurface,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: onSurface,
      ),
      iconTheme: const IconThemeData(color: onSurface),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surface,
      indicatorColor: const Color(0xFF1E3A5F),
      elevation: 0,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.poppins(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: selected ? colorScheme.primary : onVariant,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(color: selected ? colorScheme.primary : onVariant);
      }),
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: outline),
      ),
    ),
    dividerTheme: const DividerThemeData(color: outline, thickness: 1),
    listTileTheme: ListTileThemeData(
      iconColor: onVariant,
      textColor: onSurface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surfaceHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: GoogleFonts.poppins(color: onVariant),
      hintStyle: GoogleFonts.poppins(color: onVariant),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      textStyle: GoogleFonts.poppins(color: onSurface),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) return colorScheme.primary;
        return onVariant;
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: surfaceHigh,
      contentTextStyle: GoogleFonts.poppins(color: onSurface),
    ),
    dialogTheme: DialogThemeData(backgroundColor: surface),
    bottomSheetTheme: const BottomSheetThemeData(backgroundColor: surface),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: surface,
      headerBackgroundColor: surfaceHigh,
      headerForegroundColor: onSurface,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: surfaceHigh,
      selectedColor: const Color(0xFF1E3A5F),
      disabledColor: surface,
      labelStyle: GoogleFonts.poppins(color: onSurface, fontSize: 12),
      secondaryLabelStyle: GoogleFonts.poppins(color: onSurface, fontSize: 12),
      side: const BorderSide(color: outline),
      checkmarkColor: colorScheme.primary,
    ),
    tabBarTheme: TabBarThemeData(
      labelColor: colorScheme.primary,
      unselectedLabelColor: onVariant,
      indicatorColor: colorScheme.primary,
      dividerColor: outline,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    ),
  );
}
