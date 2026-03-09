import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  static const _themeKey = 'app_theme_mode';

  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey);
    
    if (themeIndex != null) {
      if (themeIndex == 0) state = ThemeMode.system;
      else if (themeIndex == 1) state = ThemeMode.light;
      else if (themeIndex == 2) state = ThemeMode.dark;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    
    int index = 0;
    if (mode == ThemeMode.light) index = 1;
    else if (mode == ThemeMode.dark) index = 2;
    
    await prefs.setInt(_themeKey, index);
  }
}
