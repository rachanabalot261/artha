import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF0A0A14);
  static const surface = Color(0xFF12121F);
  static const card = Color(0xFF1A1A2E);

  static const purple = Color(0xFF7C6FCD);
  static const purpleLight = Color(0xFF9B8FE0);
  static const purpleDark = Color(0xFF5A4FB0);

  static const income = Color(0xFF00D4A0);
  static const expense = Color(0xFFFF6B8A);
  static const saving = Color(0xFF60B4FF);
  static const warning = Color(0xFFFFB74D);

  static const List<Color> categories = [
    Color(0xFFFF6B8A),
    Color(0xFF7C6FCD),
    Color(0xFF00D4A0),
    Color(0xFFFFB74D),
    Color(0xFF60B4FF),
    Color(0xFFFF8C69),
    Color(0xFFB06FCD),
    Color(0xFF4DB6AC),
  ];

  static const textPrimary = Color(0xFFEEEEFF);
  static const textSecondary = Color(0xFF8888AA);
  static const textMuted = Color(0xFF555570);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.purple,
        secondary: AppColors.purpleLight,
        surface: AppColors.surface,
        error: AppColors.expense,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.purple.withValues(alpha: 0.2),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
                color: AppColors.purple, size: 24);
          }
          return const IconThemeData(
              color: AppColors.textMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
                color: AppColors.purple,
                fontSize: 11,
                fontWeight: FontWeight.w600);
          }
          return const TextStyle(
              color: AppColors.textMuted, fontSize: 11);
        }),
        height: 64,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.transparent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: AppColors.purple, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.purple,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(
              horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
              fontWeight: FontWeight.w600, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.purple,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1E1E35),
        thickness: 1,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.purple.withValues(alpha: 0.2),
        labelStyle: const TextStyle(
            color: AppColors.textSecondary, fontSize: 13),
        side: const BorderSide(color: Color(0xFF2A2A45)),
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}