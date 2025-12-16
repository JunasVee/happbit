import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores small, non-sensitive app preferences.
///
/// Currently used for:
/// - Light/Dark theme toggle
class AppSettings extends ChangeNotifier {
  static const String _kDarkModeKey = 'happbit_dark_mode';

  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Load saved preferences.
  ///
  /// Call this once before runApp so your UI starts in the correct mode.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_kDarkModeKey) ?? false;
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  /// Change dark mode and persist it.
  Future<void> setDarkMode(bool isDark) async {
    final newMode = isDark ? ThemeMode.dark : ThemeMode.light;
    if (_themeMode == newMode) return;

    _themeMode = newMode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDarkModeKey, isDark);
  }
}
