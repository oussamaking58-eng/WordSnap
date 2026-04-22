import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color bg = Color(0xFF07071A);
  static const Color surface = Color(0xFF0D0D1F);
  static const Color surface2 = Color(0xFF13132A);
  static const Color cardBg = Color(0xFF1E1E3F);

  // Accents
  static const Color purple = Color(0xFFA855F7);
  static const Color cyan = Color(0xFF22D3EE);
  static const Color pink = Color(0xFFE879F9);
  static const Color green = Color(0xFF4ADE80);
  static const Color orange = Color(0xFFFB923C);
  static const Color yellow = Color(0xFFFACC15);
  static const Color red = Color(0xFFF43F5E);

  // Text
  static const Color textPrimary = Color(0xFFF0EFF8);
  static const Color textSecondary = Color(0x66FFFFFF);

  // Border
  static const Color border = Color(0x12FFFFFF);
}

class AppTheme {
  static ThemeData get theme {
    return ThemeData(
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.purple,
        secondary: AppColors.cyan,
        surface: AppColors.surface,
      ),
      fontFamily: 'DM Sans',
      useMaterial3: true,
    );
  }
}
