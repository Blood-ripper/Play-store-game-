import 'package:flutter/material.dart';

/// Bright, chunky "farm arcade" look matching the reference screenshots:
/// grass greens, sunflower yellows, tomato reds, soil browns.
class FarmColors {
  static const Color grass = Color(0xFF7CB342);
  static const Color grassDark = Color(0xFF558B2F);
  static const Color soil = Color(0xFF8D6E63);
  static const Color soilDark = Color(0xFF5D4037);
  static const Color sunflower = Color(0xFFFFC107);
  static const Color sunflowerDeep = Color(0xFFFF8F00);
  static const Color tomato = Color(0xFFE53935);
  static const Color sky = Color(0xFF4FC3F7);
  static const Color coin = Color(0xFFFFD54F);
  static const Color gem = Color(0xFF40C4FF);
  static const Color panel = Color(0xFFFFF8E1);
  static const Color ink = Color(0xFF3E2723);
}

class AppTheme {
  static ThemeData light() {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: FarmColors.grass,
      primary: FarmColors.grass,
      secondary: FarmColors.sunflowerDeep,
      surface: Colors.white,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: const Color(0xFFEFF7E2),
      fontFamily: 'Baloo', // falls back to default if font not bundled
      appBarTheme: const AppBarTheme(
        backgroundColor: FarmColors.grassDark,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FarmColors.sunflowerDeep,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
              fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.5),
          padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18)),
          elevation: 4,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 3,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FarmColors.panel,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  static const TextStyle title = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: 1.0,
    shadows: <Shadow>[
      Shadow(color: Colors.black26, offset: Offset(0, 3), blurRadius: 4),
    ],
  );
}
