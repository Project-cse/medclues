import 'package:flutter/material.dart';

import 'dark_theme.dart';
import 'light_theme.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => buildLightTheme();
  static ThemeData get dark => buildDarkTheme();
}
