import 'package:flutter/material.dart';

class AppTheme {
  // Brand Palette
  static const Color background = Color(0xFF090D16);
  static const Color surface = Color(0xFF0F172A);
  static const Color surfaceLight = Color(0xFF1E293B);
  static const Color surfaceBorder = Color(0xFF334155);
  
  static const Color primary = Color(0xFF8B5CF6);      // Electric Violet
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryDark = Color(0xFF6D28D9);
  
  static const Color secondary = Color(0xFF06B6D4);    // Cyan
  static const Color accent = Color(0xFFF43F5E);       // Rose (Recording/Live)
  static const Color success = Color(0xFF10B981);      // Emerald (Ready/Loaded)
  static const Color warning = Color(0xFFF59E0B);      // Amber
  
  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    colorScheme: const ColorScheme.dark(
      primary: primary,
      secondary: secondary,
      surface: surface,
      error: accent,
    ),
    fontFamily: 'Segoe UI',
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: surfaceBorder, width: 1),
      ),
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: primary,
      inactiveTrackColor: surfaceBorder,
      thumbColor: primaryLight,
      overlayColor: primary.withValues(alpha: 0.2),
      trackHeight: 4.0,
      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
    ),
  );

  // Reusable BoxDecorations
  static BoxDecoration glassCard({BorderRadius? borderRadius, Color? borderColor}) {
    return BoxDecoration(
      color: surface.withValues(alpha: 0.85),
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      border: Border.all(
        color: borderColor ?? surfaceBorder.withValues(alpha: 0.7),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  static BoxDecoration glowEffect(Color glowColor) {
    return BoxDecoration(
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(
          color: glowColor.withValues(alpha: 0.4),
          blurRadius: 14,
          spreadRadius: 2,
        ),
      ],
    );
  }
}
