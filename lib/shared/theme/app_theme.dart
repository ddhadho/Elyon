import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ════════════════════════════════════════════════════════════════════════════
//  AppColors — static class, same member names your screens already use.
//  Values are light theme. No changes needed in any existing screen.
// ════════════════════════════════════════════════════════════════════════════
class AppColors {
  // Backgrounds
  static const bg         = Color(0xFFF7F6F3);
  static const surface    = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFF0EEE9);

  // Accents
  static const blue   = Color(0xFF3B7FD4);  // info / links
  static const orange = Color(0xFFFF6B35);  // active / on state
  static const green  = Color(0xFF3B9E6B);  // success / ok
  static const red    = Color(0xFFD64545);  // error / danger
  static const yellow = Color(0xFFD4870A);  // warning

  // Text
  static const textPrimary   = Color(0xFF1A1916);
  static const textSecondary = Color(0xFF6B6860);
  static const textMuted     = Color(0xFFA8A69E);

  // State colours — same API your screens already call
  static Color stateColor(String value) => switch (value.toLowerCase()) {
    'on' || 'locked' || 'kplc'      => orange,
    'off' || 'unlocked' || 'outage' => textMuted,
    _                               => textSecondary,
  };

  // Confidence dot colours — same API
  static Color confidenceColor(double v) {
    if (v >= 0.8) return green;
    if (v >= 0.5) return yellow;
    if (v >= 0.2) return orange;
    return red;
  }
}

// ════════════════════════════════════════════════════════════════════════════
//  Dark palette — only used by buildDarkTheme(), not referenced by screens
// ════════════════════════════════════════════════════════════════════════════
abstract final class _Dark {
  static const bg           = Color(0xFF111827);
  static const surface      = Color(0xFF1C2136);
  static const surfaceAlt   = Color(0xFF243044);
  static const blue         = Color(0xFF03A9F4);
  static const orange       = Color(0xFFFF9800);
  static const green        = Color(0xFF4CAF50);
  static const red          = Color(0xFFF44336);
  static const yellow       = Color(0xFFFFEB3B);
  static const textPrimary  = Color(0xFFE8EAF0);
  static const textSecondary= Color(0xFF8B9EC7);
  static const textMuted    = Color(0xFF4D5E82);
  static const border       = Color(0xFF2A3A5C);
}

// ════════════════════════════════════════════════════════════════════════════
//  Shared design tokens
// ════════════════════════════════════════════════════════════════════════════
abstract final class AppRadius {
  static const sm = Radius.circular(10);
  static const md = Radius.circular(16);
  static const lg = Radius.circular(22);

  static const borderSm = BorderRadius.all(sm);
  static const borderMd = BorderRadius.all(md);
  static const borderLg = BorderRadius.all(lg);
}

abstract final class AppText {
  static const _base = TextStyle(
    fontFamily: '.SF Pro Display',
    letterSpacing: -0.2,
  );

  static final displayMd = _base.copyWith(fontSize: 28, fontWeight: FontWeight.w600, letterSpacing: -0.8);
  static final titleMd   = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w600, letterSpacing: -0.4);
  static final titleSm   = _base.copyWith(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: -0.2);
  static final bodyMd    = _base.copyWith(fontSize: 14, fontWeight: FontWeight.w400);
  static final bodySm    = _base.copyWith(fontSize: 12, fontWeight: FontWeight.w400);
  static final label     = _base.copyWith(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.6);
  static final caption   = _base.copyWith(fontSize: 10, fontWeight: FontWeight.w500);
}

// ════════════════════════════════════════════════════════════════════════════
//  Light theme — premium warm Apple-like style
// ════════════════════════════════════════════════════════════════════════════
ThemeData buildLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.light(
      primary: AppColors.orange,
      onPrimary: Colors.white,
      secondary: AppColors.textSecondary,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      surfaceContainerHighest: AppColors.surfaceAlt,
      outline: const Color(0x12000000),
      error: AppColors.red,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      titleTextStyle: AppText.titleMd.copyWith(color: AppColors.textPrimary),
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: AppColors.orange.withAlpha(30),
      iconTheme: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? const IconThemeData(color: AppColors.orange, size: 22)
              : const IconThemeData(color: AppColors.textMuted, size: 22)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppText.caption.copyWith(color: AppColors.orange, fontWeight: FontWeight.w700)
              : AppText.caption.copyWith(color: AppColors.textMuted)),
      height: 64,
      elevation: 0,
      shadowColor: Colors.transparent,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderLg,
        side: const BorderSide(color: Color(0x12000000), width: 0.5),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? AppColors.orange : Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? AppColors.orange.withAlpha(200)
              : const Color(0xFFE8E6E0)),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0x12000000),
      thickness: 0.5,
      space: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceAlt,
      hintStyle: AppText.bodyMd.copyWith(color: AppColors.textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
          borderRadius: AppRadius.borderMd, borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.borderMd,
        borderSide: const BorderSide(color: AppColors.orange, width: 1.5),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.textPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: AppText.titleSm,
        shape: const StadiumBorder(),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: AppText.titleSm,
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: AppColors.orange),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      titleTextStyle: AppText.bodyMd.copyWith(
          color: AppColors.textPrimary, fontWeight: FontWeight.w500),
      subtitleTextStyle: AppText.bodySm.copyWith(color: AppColors.textMuted),
      iconColor: AppColors.textMuted,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: AppText.bodyMd.copyWith(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.orange,
      linearTrackColor: Color(0xFFE8E6E0),
    ),
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: AppColors.textPrimary),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
      bodySmall:  TextStyle(color: AppColors.textMuted),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux:   FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
//  Dark theme — your original HA dark theme, unchanged
// ════════════════════════════════════════════════════════════════════════════
ThemeData buildDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: _Dark.bg,
    colorScheme: const ColorScheme.dark(
      primary: _Dark.blue,
      secondary: _Dark.orange,
      surface: _Dark.surface,
      onPrimary: Colors.white,
      onSurface: _Dark.textPrimary,
      error: _Dark.red,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: _Dark.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      titleTextStyle: AppText.titleMd.copyWith(
          color: _Dark.textPrimary, letterSpacing: 0.2),
      iconTheme: const IconThemeData(color: _Dark.textSecondary),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: _Dark.surface,
      surfaceTintColor: Colors.transparent,
      indicatorColor: const Color(0x2603A9F4),
      iconTheme: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? const IconThemeData(color: _Dark.blue, size: 22)
              : const IconThemeData(color: _Dark.textMuted, size: 22)),
      labelTextStyle: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? const TextStyle(color: _Dark.blue, fontSize: 11, fontWeight: FontWeight.w600)
              : const TextStyle(color: _Dark.textMuted, fontSize: 11)),
      height: 64,
      elevation: 0,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
    ),
    cardTheme: CardThemeData(
      color: _Dark.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.borderLg,
        side: const BorderSide(color: _Dark.border, width: 1),
      ),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected) ? _Dark.orange : Colors.white),
      trackColor: WidgetStateProperty.resolveWith((s) =>
          s.contains(WidgetState.selected)
              ? _Dark.orange.withAlpha(180)
              : _Dark.surfaceAlt),
      trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF1E2D4A),
      thickness: 1,
      space: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _Dark.surfaceAlt,
      border: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: _Dark.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: _Dark.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.borderMd,
          borderSide: const BorderSide(color: _Dark.blue, width: 1.5)),
      hintStyle: const TextStyle(color: _Dark.textMuted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _Dark.blue,
        foregroundColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: AppText.titleSm,
        shape: const StadiumBorder(),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _Dark.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: AppText.titleSm,
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: _Dark.blue),
    ),
    listTileTheme: ListTileThemeData(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      titleTextStyle: AppText.bodyMd.copyWith(
          color: _Dark.textPrimary, fontWeight: FontWeight.w500),
      subtitleTextStyle: AppText.bodySm.copyWith(color: _Dark.textMuted),
      iconColor: _Dark.textSecondary,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _Dark.surfaceAlt,
      contentTextStyle: AppText.bodyMd.copyWith(color: _Dark.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: AppRadius.borderMd),
      behavior: SnackBarBehavior.floating,
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: _Dark.blue,
    ),
    textTheme: const TextTheme(
      bodyLarge:  TextStyle(color: _Dark.textPrimary),
      bodyMedium: TextStyle(color: _Dark.textSecondary),
      bodySmall:  TextStyle(color: _Dark.textMuted),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS:     CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux:   FadeUpwardsPageTransitionsBuilder(),
      },
    ),
  );
}

// ════════════════════════════════════════════════════════════════════════════
//  ThemeNotifier — persists toggle choice to shared_preferences
// ════════════════════════════════════════════════════════════════════════════
const _kThemeKey = 'kaya_dark_mode';

class ThemeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  Future<void> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_kThemeKey) ?? false;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final next = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    state = next;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kThemeKey, next == ThemeMode.dark);
  }

  bool get isDark => state == ThemeMode.dark;
}

final themeModeProvider =
    NotifierProvider<ThemeNotifier, ThemeMode>(ThemeNotifier.new);