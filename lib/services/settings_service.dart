import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static const String _keyUserPin = 'user_pin';

  Future<void> setPin(String pin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserPin, pin);
  }

  Future<bool> verifyPin(String inputPin) async {
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString(_keyUserPin);
    // If no PIN is set, default to "1234" (or handle as error)
    return storedPin == inputPin || (storedPin == null && inputPin == "1234");
  }

  Future<bool> isPinSet() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keyUserPin);
  }

  // --- Dynamic Reps ---
  static const String _keyRequiredReps = 'required_reps';

  Future<void> setRequiredReps(int reps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyRequiredReps, reps);
  }

  Future<int> getRequiredReps() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyRequiredReps) ?? 10;
  }

  // --- Daily Step Goal ---
  static const String _keyDailyStepGoal = 'daily_step_goal';

  Future<void> setDailyStepGoal(int steps) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDailyStepGoal, steps);
  }

  Future<int> getDailyStepGoal() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDailyStepGoal) ?? 1000;
  }

  // --- Onboarding ---
  static const String _keyOnboardingDone = 'onboarding_done';

  Future<void> setOnboardingCompleted(bool done) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingDone, done);
  }

  Future<bool> isOnboardingCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyOnboardingDone) ?? false;
  }
}