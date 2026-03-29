import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const bg = Color(0xFF0A0A0F);
  static const bgCard = Color(0xFF13131A);
  static const bgElevated = Color(0xFF1C1C26);
  static const bgInput = Color(0xFF1A1A24);

  // Accents
  static const primary = Color(0xFF6C63FF);
  static const primaryMuted = Color(0x226C63FF);
  static const green = Color(0xFF39D98A);
  static const greenMuted = Color(0x1839D98A);
  static const amber = Color(0xFFFFB800);
  static const amberMuted = Color(0x18FFB800);
  static const coral = Color(0xFFFF6B6B);
  static const coralMuted = Color(0x18FF6B6B);
  static const blue = Color(0xFF4DA6FF);
  static const blueMuted = Color(0x184DA6FF);

  // Text
  static const textPrimary = Color(0xFFF0F0F8);
  static const textSecondary = Color(0xFF8888AA);
  static const textMuted = Color(0xFF44445A);

  // Border
  static const border = Color(0xFF1E1E2E);
  static const borderStrong = Color(0xFF2E2E44);

  // Macros
  static const protein = Color(0xFF6C63FF);
  static const fat = Color(0xFFFFB800);
  static const carbs = Color(0xFF39D98A);
  static const calories = Color(0xFFFF6B6B);
}

class AppTheme {
  static ThemeData get dark {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        surface: AppColors.bgCard,
        background: AppColors.bg,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(color: AppColors.textPrimary, fontSize: 28, fontWeight: FontWeight.w800),
        headlineMedium: TextStyle(color: AppColors.textPrimary, fontSize: 22, fontWeight: FontWeight.w700),
        headlineSmall: TextStyle(color: AppColors.textPrimary, fontSize: 17, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: AppColors.textPrimary, fontSize: 15),
        bodyMedium: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        bodySmall: TextStyle(color: AppColors.textMuted, fontSize: 11),
        labelLarge: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w600),
      ),
    );
  }
}

// Meal info
class MealInfo {
  final String key;
  final String label;
  final IconData icon;
  final Color color;

  const MealInfo({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
  });
}

const meals = [
  MealInfo(key: 'breakfast', label: 'Завтрак',  icon: Icons.wb_sunny_outlined,    color: AppColors.amber),
  MealInfo(key: 'lunch',     label: 'Обед',     icon: Icons.light_mode_outlined,  color: AppColors.green),
  MealInfo(key: 'dinner',    label: 'Ужин',     icon: Icons.nights_stay_outlined, color: AppColors.primary),
  MealInfo(key: 'snacks',    label: 'Перекусы', icon: Icons.restaurant_outlined,  color: AppColors.coral),
];

MealInfo getMealInfo(String key) =>
    meals.firstWhere((m) => m.key == key, orElse: () => meals[1]);
