import 'package:flutter/material.dart';

import 'parakh_colors.dart';

abstract final class ParakhTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: ParakhColors.forestGreen,
      brightness: Brightness.light,
      surface: ParakhColors.surface,
      error: ParakhColors.danger,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ParakhColors.background,
      fontFamily: 'sans-serif',
      appBarTheme: const AppBarTheme(
        backgroundColor: ParakhColors.background,
        foregroundColor: ParakhColors.primaryText,
        elevation: 0,
        centerTitle: false,
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          color: ParakhColors.primaryText,
          fontSize: 36,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
        headlineSmall: TextStyle(
          color: ParakhColors.primaryText,
          fontSize: 24,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(
          color: ParakhColors.secondaryText,
          fontSize: 16,
          height: 1.5,
        ),
      ),
    );
  }
}
