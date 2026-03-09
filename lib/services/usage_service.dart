import 'package:shared_preferences/shared_preferences.dart';
import '../models/exercise_type.dart';

class UsageService {
  static const String _keyLastResetDate = 'last_reset_date';
  static const String _keyDailyUnlockCount = 'daily_unlock_count';
  static const String _keyDailyEmergencyCount = 'daily_emergency_count';
  static const String _keyDailySquats = 'daily_squats_count';
  static const String _keyDailyPushups = 'daily_pushups_count';
  static const String _keyDailySteps = 'daily_steps_count';

  // New Keys for User Settings
  static const String _keyMaxDailyUnlocks = 'max_daily_unlocks';
  static const String _keyMaxEmergency = 'max_emergency_usage';

  // Default values if not set
  static const int _defaultMaxUnlocks = 3;
  static const int _defaultMaxEmergency = 1;

  Future<void> _checkAndResetDailyCounts() async {
    final prefs = await SharedPreferences.getInstance();
    final lastDateStr = prefs.getString(_keyLastResetDate);
    final todayStr = DateTime.now().toIso8601String().split('T').first;

    if (lastDateStr != todayStr) {
      // It's a new day, reset counters
      await prefs.setString(_keyLastResetDate, todayStr);
      await prefs.setInt(_keyDailyUnlockCount, 0);
      await prefs.setInt(_keyDailyEmergencyCount, 0);
      await prefs.setInt(_keyDailySquats, 0);
      await prefs.setInt(_keyDailyPushups, 0);
      await prefs.setInt(_keyDailySteps, 0);
    }
  }

  // --- GETTERS (WITH USER SETTINGS) ---

  Future<int> getMaxDailyUnlocks() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMaxDailyUnlocks) ?? _defaultMaxUnlocks;
  }

  Future<int> getMaxEmergencyUsage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyMaxEmergency) ?? _defaultMaxEmergency;
  }

  // --- SETTERS ---

  Future<void> setMaxDailyUnlocks(int limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaxDailyUnlocks, limit);
  }

  Future<void> setMaxEmergencyUsage(int limit) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaxEmergency, limit);
  }

  // --- LOGIC ---

  Future<bool> canUnlock() async {
    await _checkAndResetDailyCounts();
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyDailyUnlockCount) ?? 0;
    final limit = await getMaxDailyUnlocks();
    return count < limit;
  }

  Future<bool> canUseEmergency() async {
    await _checkAndResetDailyCounts();
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyDailyEmergencyCount) ?? 0;
    final limit = await getMaxEmergencyUsage();
    return count < limit;
  }

  Future<void> incrementUnlockCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyDailyUnlockCount) ?? 0;
    await prefs.setInt(_keyDailyUnlockCount, count + 1);
  }

  Future<void> incrementEmergencyCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_keyDailyEmergencyCount) ?? 0;
    await prefs.setInt(_keyDailyEmergencyCount, count + 1);
  }

  Future<void> addExerciseCount(ExerciseType type, int amount) async {
    final prefs = await SharedPreferences.getInstance();
    String key = ''; // Initialize to avoid build error
    switch (type) {
      case ExerciseType.squat:
        key = _keyDailySquats;
        break;
      case ExerciseType.pushup:
        key = _keyDailyPushups;
        break;
      case ExerciseType.steps:
        key = _keyDailySteps;
        break;
    }
    final current = prefs.getInt(key) ?? 0;
    await prefs.setInt(key, current + amount);
  }

  Future<Map<String, int>> getStats() async {
    await _checkAndResetDailyCounts();
    final prefs = await SharedPreferences.getInstance();
    return {
      'unlocks': prefs.getInt(_keyDailyUnlockCount) ?? 0,
      'emergency': prefs.getInt(_keyDailyEmergencyCount) ?? 0,
      'maxUnlocks': await getMaxDailyUnlocks(),
      'maxEmergency': await getMaxEmergencyUsage(),
      'squats': prefs.getInt(_keyDailySquats) ?? 0,
      'pushups': prefs.getInt(_keyDailyPushups) ?? 0,
      'steps': prefs.getInt(_keyDailySteps) ?? 0,
    };
  }
}