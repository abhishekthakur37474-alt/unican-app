import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1575FD);
  static const secondary = Color(0xFF7C3AED);
  static const accent = Color(0xFF22B8FF);
  static const background = Color(0xFFF5F7FB);

  static const gradient = LinearGradient(
    colors: [secondary, primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.primary);
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
    );
  }
}
