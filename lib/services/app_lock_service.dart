import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/locked_app.dart';

class AppLockService {
  // Channel to talk to MainActivity.kt
  static const MethodChannel _channel = MethodChannel('com.activlock/native');

  /// Checks if the user has enabled the Accessibility Service in Android Settings
  Future<bool> isAccessibilityServiceEnabled() async {
    try {
      final bool result = await _channel.invokeMethod('isAccessibilityServiceEnabled');
      return result;
    } on PlatformException catch (e) {
      debugPrint("Failed to check accessibility service: '${e.message}'.");
      return false;
    }
  }

  /// Opens the specific Android Accessibility Settings page
  Future<void> openAccessibilitySettings() async {
    try {
      await _channel.invokeMethod('openAccessibilitySettings');
    } on PlatformException catch (e) {
      debugPrint("Failed to open settings: '${e.message}'.");
    }
  }

  /// Checks and requests the SYSTEM_ALERT_WINDOW permission
  Future<void> checkOverlayPermission() async {
    final status = await Permission.systemAlertWindow.status;
    if (!status.isGranted) {
      await Permission.systemAlertWindow.request();
    }
  }

  /// Saves the list of locked apps.
  /// It saves TWO lists:
  /// 1. 'native_locked_apps': A simple comma-separated string for the Android Service (efficient).
  /// 2. 'locked_apps_ui_list': A full JSON list for the Flutter UI (includes names, icons, etc).
  Future<void> saveLockedApps(List<LockedApp> apps) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Native List (Package Names only)
    final lockedPackageNames = apps.where((app) => app.isLocked).map((app) => app.packageName).toList();
    final nativeString = lockedPackageNames.join(',');
    await prefs.setString('native_locked_apps', nativeString);

    // 2. UI List (Full JSON)
    final appsJson = apps.map((app) => jsonEncode(app.toJson())).toList();
    await prefs.setStringList('locked_apps_ui_list', appsJson);
  }

  /// Removes an app from the locked_apps_ui_list and updates the native service.
  Future<void> removeApp(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final appsJson = prefs.getStringList('locked_apps_ui_list') ?? [];

    final updatedList = appsJson.where((str) {
      final app = LockedApp.fromJson(jsonDecode(str));
      return app.packageName != packageName;
    }).toList();

    await prefs.setStringList('locked_apps_ui_list', updatedList);
    
    // Notify native
    try {
      final List<String> packageNames = updatedList
          .map((str) => LockedApp.fromJson(jsonDecode(str)).packageName)
          .toList();
      await _channel.invokeMethod('updateLockedApps', {'packages': packageNames});
    } on PlatformException catch (e) {
      debugPrint("Failed to update native service: '${e.message}'.");
    }
  }

  /// Increments the used exceptions count for a specific app
  Future<void> incrementException(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final appsJson = prefs.getStringList('locked_apps_ui_list') ?? [];
    List<LockedApp> apps = appsJson.map((str) => LockedApp.fromJson(jsonDecode(str))).toList();

    int index = apps.indexWhere((a) => a.packageName == packageName);
    if (index != -1) {
      final old = apps[index];
      apps[index] = LockedApp(
        packageName: old.packageName,
        appName: old.appName,
        isLocked: old.isLocked,
        pinCode: old.pinCode,
        exerciseType: old.exerciseType,
        targetReps: old.targetReps,
        dailyExceptions: old.dailyExceptions,
        usedExceptions: old.usedExceptions + 1,
        dailyUnlockLimit: old.dailyUnlockLimit,
        usedUnlocks: old.usedUnlocks,
        lastResetDate: DateTime.now(), // update date to today ensures no weird resets
      );
      await saveLockedApps(apps);
    }
  }

  /// Increments the regular unlock count for a specific app
  Future<void> incrementUnlock(String packageName) async {
    final prefs = await SharedPreferences.getInstance();
    final appsJson = prefs.getStringList('locked_apps_ui_list') ?? [];
    List<LockedApp> apps = appsJson.map((str) => LockedApp.fromJson(jsonDecode(str))).toList();

    int index = apps.indexWhere((a) => a.packageName == packageName);
    if (index != -1) {
      final old = apps[index];
      apps[index] = LockedApp(
        packageName: old.packageName,
        appName: old.appName,
        isLocked: old.isLocked,
        pinCode: old.pinCode,
        exerciseType: old.exerciseType,
        targetReps: old.targetReps,
        dailyExceptions: old.dailyExceptions,
        usedExceptions: old.usedExceptions,
        dailyUnlockLimit: old.dailyUnlockLimit,
        usedUnlocks: old.usedUnlocks + 1, // Increment
        lastResetDate: DateTime.now(),
      );
      await saveLockedApps(apps);
    }
  }

  /// Retrieves the list of locked apps for the UI, handling daily resets
  Future<List<LockedApp>> getLockedApps() async {
    final prefs = await SharedPreferences.getInstance();
    final appsJson = prefs.getStringList('locked_apps_ui_list') ?? [];

    List<LockedApp> apps = appsJson.map((str) => LockedApp.fromJson(jsonDecode(str))).toList();

    // Check for Daily Reset
    final now = DateTime.now();
    bool needsSave = false;

    List<LockedApp> updatedApps = [];
    for (var app in apps) {
      if (app.lastResetDate == null || !_isSameDay(app.lastResetDate!, now)) {
        // Reset counters for a new day
        updatedApps.add(LockedApp(
          packageName: app.packageName,
          appName: app.appName,
          isLocked: app.isLocked,
          pinCode: app.pinCode,
          exerciseType: app.exerciseType,
          targetReps: app.targetReps,
          dailyExceptions: app.dailyExceptions,
          usedExceptions: 0, // RESET
          dailyUnlockLimit: app.dailyUnlockLimit,
          usedUnlocks: 0,    // RESET
          lastResetDate: now,
        ));
        needsSave = true;
      } else {
        updatedApps.add(app);
      }
    }

    if (needsSave) {
      await saveLockedApps(updatedApps);
      return updatedApps;
    }

    return apps;
  }

  bool _isSameDay(DateTime d1, DateTime d2) {
    return d1.year == d2.year && d1.month == d2.month && d1.day == d2.day;
  }

  /// Adds a new app to the lock list
  Future<void> addLockedApp(LockedApp app) async {
    final currentApps = await getLockedApps();
    // Prevent duplicates
    if (!currentApps.any((a) => a.packageName == app.packageName)) {
      currentApps.add(app);
      await saveLockedApps(currentApps);
    }
  }

  /// Removes an app from the lock list
  Future<void> removeLockedApp(String packageName) async {
    final currentApps = await getLockedApps();
    currentApps.removeWhere((a) => a.packageName == packageName);
    await saveLockedApps(currentApps);
  }

  /// Temporarily unlocks an app by removing it from the 'native_locked_apps' list
  /// but keeping it in the 'UI list'. It automatically re-locks after [duration].
  Future<void> unlockAppTemporary(String packageName, {Duration duration = const Duration(minutes: 15)}) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Get current Locked Apps
    final currentApps = await getLockedApps();

    // 2. Filter out the app we want to unlock temporarily
    final lockedPackageNames = currentApps
        .where((app) => app.isLocked && app.packageName != packageName)
        .map((app) => app.packageName)
        .toList();

    // 3. Update Native String so accessibility service ignores this app
    await prefs.setString('native_locked_apps', lockedPackageNames.join(','));

    // 4. Schedule re-lock
    Future.delayed(duration, () async {
      // Fetch fresh list (in case user added more apps while waiting)
      final freshApps = await getLockedApps();

      // If the app is still in our list, re-add it to the native lock string
      if (freshApps.any((a) => a.packageName == packageName && a.isLocked)) {
        final freshNames = freshApps.where((a) => a.isLocked).map((a) => a.packageName).toList();
        await prefs.setString('native_locked_apps', freshNames.join(','));
      }
    });
  }
}