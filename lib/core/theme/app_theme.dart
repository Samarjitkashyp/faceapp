import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Brand Color Tokens
  static const Color background = Color(0xFF080B14);
  static const Color surface = Color(0xFF0F172A);
  static const Color card = Color(0xFF121829);
  static const Color cardHover = Color(0xFF182035);
  static const Color border = Color(0xFF1E293B);
  static const Color borderLight = Color(0xFF334155);

  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryLight = Color(0xFFA78BFA);
  static const Color primaryGradientStart = Color(0xFF7C3AED);
  static const Color primaryGradientEnd = Color(0xFF6366F1);

  static const Color cyan = Color(0xFF06B6D4);
  static const Color emerald = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color rose = Color(0xFFF43F5E);

  static const Color textMain = Color(0xFFF8FAFC);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDark = Color(0xFF64748B);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      primaryColor: primary,
      colorScheme: const ColorScheme.dark(
        primary: primary,
        secondary: cyan,
        surface: card,
        error: rose,
        onPrimary: Colors.white,
        onSurface: textMain,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme.copyWith(
          titleLarge: GoogleFonts.outfit(
            color: textMain,
            fontWeight: FontWeight.w700,
            fontSize: 22,
          ),
          titleMedium: GoogleFonts.outfit(
            color: textMain,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
          titleSmall: GoogleFonts.outfit(
            color: textMain,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          bodyLarge: const TextStyle(color: textMain, fontSize: 16),
          bodyMedium: const TextStyle(color: textMuted, fontSize: 14),
          bodySmall: const TextStyle(color: textDark, fontSize: 12),
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: border, width: 1),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0D1220),
        hintStyle: const TextStyle(color: textDark, fontSize: 14),
        labelStyle: const TextStyle(color: textMuted, fontSize: 14),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: rose),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primary.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.outfit(
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.outfit(
          color: textMain,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: const IconThemeData(color: textMain),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0D1220),
        selectedItemColor: primaryLight,
        unselectedItemColor: textDark,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
    );
  }
}
