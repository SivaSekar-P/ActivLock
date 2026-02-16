import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/locked_app.dart';
import '../services/app_lock_service.dart';
import '../services/usage_service.dart';
import '../services/settings_service.dart'; // Import SettingsService

import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart'; // Needed for ThemeMode

final appLockServiceProvider = Provider((ref) => AppLockService());
final usageServiceProvider = Provider((ref) => UsageService());
final settingsServiceProvider = Provider((ref) => SettingsService()); // New Provider

final lockedAppsProvider = StateNotifierProvider<LockedAppsNotifier, List<LockedApp>>((ref) {
  final service = ref.watch(appLockServiceProvider);
  return LockedAppsNotifier(service);
});

class LockedAppsNotifier extends StateNotifier<List<LockedApp>> {
  final AppLockService _service;

  LockedAppsNotifier(this._service) : super([]) {
    _loadApps();
  }

  Future<void> _loadApps() async {
    state = await _service.getLockedApps();
  }

  Future<void> addApp(LockedApp app) async {
    if (!state.any((a) => a.packageName == app.packageName)) {
      state = [...state, app];
      await _service.saveLockedApps(state);
    }
  }

  Future<void> removeApp(String packageName) async {
    state = state.where((a) => a.packageName != packageName).toList();
    await _service.saveLockedApps(state);
  }
}

final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.dark) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('is_dark_theme') ?? true;
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme(bool isDark) async {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_dark_theme', isDark);
  }
}