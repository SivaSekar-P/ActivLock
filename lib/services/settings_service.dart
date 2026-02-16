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
}