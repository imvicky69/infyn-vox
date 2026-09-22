import 'package:flutter/material.dart';

class AppTheme {
  // Theme Mode Notifier for instant toggling
  static final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier(ThemeMode.dark);

  static bool get isDarkMode => themeModeNotifier.value == ThemeMode.dark;

  static void toggleTheme() {
    themeModeNotifier.value = isDarkMode ? ThemeMode.light : ThemeMode.dark;
  }

  // Brand Accent: Clean Electric Blue #3B82F6
  static const Color primary = Color(0xFF3B82F6);       // #3B82F6
  static const Color primaryLight = Color(0xFF60A5FA);  // #60A5FA
  static const Color primaryDark = Color(0xFF2563EB);   // #2563EB
  static const Color accent = Color(0xFF3B82F6);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);       // Emerald
  static const Color warning = Color(0xFFF59E0B);       // Amber
  static const Color error = Color(0xFFEF4444);         // Rose

  // Dark Palette (Sleek Monochrome / Zinc 950)
  static const Color darkBackground = Color(0xFF09090B);
  static const Color darkSurface = Color(0xFF121215);
  static const Color darkSurfaceLight = Color(0xFF18181B);
  static const Color darkSurfaceBorder = Color(0xFF27272A);
  static const Color darkTextPrimary = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextMuted = Color(0xFF71717A);

  // Light Palette (Pure Minimalist White / Slate)
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceLight = Color(0xFFF1F5F9);
  static const Color lightSurfaceBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF94A3B8);

  // Default Dynamic Fallbacks (matching current theme mode)
  static Color get background => isDarkMode ? darkBackground : lightBackground;
  static Color get surface => isDarkMode ? darkSurface : lightSurface;
  static Color get surfaceLight => isDarkMode ? darkSurfaceLight : lightSurfaceLight;
  static Color get surfaceBorder => isDarkMode ? darkSurfaceBorder : lightSurfaceBorder;
  static Color get textPrimary => isDarkMode ? darkTextPrimary : lightTextPrimary;
  static Color get textSecondary => isDarkMode ? darkTextSecondary : lightTextSecondary;
  static Color get textMuted => isDarkMode ? darkTextMuted : lightTextMuted;
  static const Color secondary = primaryLight;

  // Context-aware Helpers
  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;
  static Color bg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkBackground : lightBackground;
  static Color cardBg(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurface : lightSurface;
  static Color cardLight(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurfaceLight : lightSurfaceLight;
  static Color border(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkSurfaceBorder : lightSurfaceBorder;
  static Color text(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextPrimary : lightTextPrimary;
  static Color textSub(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTextSecondary : lightTextSecondary;

  // Dark Theme Definition
  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    fontFamily: 'Geist',
    scaffoldBackgroundColor: darkBackground,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: primaryLight,
      surface: darkSurface,
      error: error,
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      fontFamily: 'Geist',
      bodyColor: darkTextPrimary,
      displayColor: darkTextPrimary,
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: darkSurfaceBorder, width: 1),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: primary,
      inactiveTrackColor: darkSurfaceBorder,
      thumbColor: Colors.white,
      overlayColor: Color(0x333B82F6),
      trackHeight: 3.0,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
  );

  // Light Theme Definition
  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: 'Geist',
    scaffoldBackgroundColor: lightBackground,
    colorScheme: const ColorScheme.light(
      primary: primary,
      secondary: primaryDark,
      surface: lightSurface,
      error: error,
    ),
    textTheme: ThemeData.light().textTheme.apply(
      fontFamily: 'Geist',
      bodyColor: lightTextPrimary,
      displayColor: lightTextPrimary,
    ),
    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: lightSurfaceBorder, width: 1),
      ),
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: primary,
      inactiveTrackColor: lightSurfaceBorder,
      thumbColor: primary,
      overlayColor: Color(0x223B82F6),
      trackHeight: 3.0,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
  );

  // Reusable Clean Minimal BoxDecorations
  static BoxDecoration glassCard({BorderRadius? borderRadius, Color? borderColor, BuildContext? context}) {
    final isDark = context != null
        ? Theme.of(context).brightness == Brightness.dark
        : isDarkMode;
        
    return BoxDecoration(
      color: isDark ? darkSurface : lightSurface,
      borderRadius: borderRadius ?? BorderRadius.circular(10),
      border: Border.all(
        color: borderColor ?? (isDark ? darkSurfaceBorder : lightSurfaceBorder),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
          blurRadius: 10,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  static BoxDecoration glowEffect(Color glowColor) {
    return BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: glowColor.withOpacity(0.2),
          blurRadius: 10,
          spreadRadius: 1,
        ),
      ],
    );
  }
}
