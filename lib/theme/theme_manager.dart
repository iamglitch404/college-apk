import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

class ThemeManager with ChangeNotifier {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  ThemeMode _themeMode = ThemeMode.system;
  Color _accentColor = const Color(0xFF8C1515); // Default Crimson

  ThemeMode get themeMode => _themeMode;
  Color get accentColor => _accentColor;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Theme Mode
    final modeStr = prefs.getString('theme_mode') ?? 'system';
    _themeMode = ThemeMode.values.firstWhere((e) => e.name == modeStr, orElse: () => ThemeMode.system);
    
    // Load Accent Color
    final colorVal = prefs.getInt('accent_color');
    if (colorVal != null) {
      _accentColor = Color(colorVal);
    }
    
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', mode.name);
    notifyListeners();
  }

  Future<void> setAccentColor(Color color) async {
    _accentColor = color;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accent_color', color.toARGB32());
    notifyListeners();
  }

  ThemeData get lightTheme => AppTheme.createTheme(Brightness.light, _accentColor);
  ThemeData get darkTheme => AppTheme.createTheme(Brightness.dark, _accentColor);
}
