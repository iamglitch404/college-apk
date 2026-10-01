import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color crimson = Color(0xFF8C1515);
  static const Color gold = Color(0xFFFCC200);
  static const Color darkBg = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color surfaceLight = Color(0xFFF8F9FA);

  static ThemeData createTheme(Brightness brightness, Color accent) {
    bool isDark = brightness == Brightness.dark;
    
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      primaryColor: accent,
      scaffoldBackgroundColor: isDark ? darkBg : Colors.white,
      
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: accent,
        secondary: gold,
        surface: isDark ? surfaceDark : surfaceLight,
        onSurface: isDark ? Colors.white70 : Colors.black87,
      ),
      
      textTheme: GoogleFonts.outfitTextTheme(isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accent, width: 1.5),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
      ),
      
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.outfit(
          fontSize: 18, 
          fontWeight: FontWeight.bold, 
          color: isDark ? Colors.white : Colors.black87
        ),
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black87),
      ),
    );
  }

  // Fallback defaults
  static ThemeData get lightTheme => createTheme(Brightness.light, crimson);
  static ThemeData get darkTheme => createTheme(Brightness.dark, crimson);
}
