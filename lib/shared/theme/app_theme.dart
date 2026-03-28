import 'package:flutter/material.dart';

/// Colour palette drawn from Home Assistant's dark UI.
class AppColors {
  // Backgrounds
  static const bg         = Color(0xFF111827); // HA page background
  static const surface    = Color(0xFF1C2136); // HA card background
  static const surfaceAlt = Color(0xFF243044); // slightly lighter card

  // Accents
  static const blue       = Color(0xFF03A9F4); // HA primary blue
  static const orange     = Color(0xFFFF9800); // HA active / on state
  static const green      = Color(0xFF4CAF50); // confirmed / ok
  static const red        = Color(0xFFF44336); // error / off / outage
  static const yellow     = Color(0xFFFFEB3B); // warning / mid confidence

  // Text
  static const textPrimary   = Color(0xFFE8EAF0);
  static const textSecondary = Color(0xFF8B9EC7);
  static const textMuted     = Color(0xFF4D5E82);

  // State colours — mirrors HA's entity state pill colours
  static Color stateColor(String value) => switch (value.toLowerCase()) {
    'on' || 'locked' || 'kplc'       => orange,
    'off' || 'unlocked' || 'outage'  => textMuted,
    _                                => textSecondary,
  };

  // Confidence dot colours — spec: green >=80%, yellow >=50%, orange >=20%, red <20%
  static Color confidenceColor(double v) {
    if (v >= 0.8) return green;
    if (v >= 0.5) return yellow;
    if (v >= 0.2) return orange;
    return red;
  }
}

class AppTheme {
  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.blue,
        secondary: AppColors.orange,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
        error: AppColors.red,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF2A3A5C), width: 1),
        ),
        margin: EdgeInsets.zero,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        iconTheme: IconThemeData(color: AppColors.textSecondary),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: Color(0x2603A9F4),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.blue, size: 22);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 22);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: AppColors.blue, fontSize: 11, fontWeight: FontWeight.w600);
          }
          return const TextStyle(color: AppColors.textMuted, fontSize: 11);
        }),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A3A5C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF2A3A5C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.blue, width: 1.5),
        ),
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1E2D4A),
        thickness: 1,
      ),
      textTheme: const TextTheme(
        bodyLarge:  TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
        bodySmall:  TextStyle(color: AppColors.textMuted),
      ),
    );
  }
}