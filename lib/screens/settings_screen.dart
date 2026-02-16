import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/wakanda_theme.dart';
import '../theme/wakanda_background.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // Logic Flags
  bool _isPinSet = false;
  bool _isLoading = true;

  // Controllers
  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _newPinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();

  // Visibility Toggles
  bool _hideOld = true;
  bool _hideNew = true;
  bool _hideConfirm = true;

  // Limit Values
  int _dailyUnlockLimit = 3;
  int _emergencyLimit = 1;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final hasPin = await ref.read(settingsServiceProvider).isPinSet();
    final usage = ref.read(usageServiceProvider);
    final dLimit = await usage.getMaxDailyUnlocks();
    final eLimit = await usage.getMaxEmergencyUsage();

    if (mounted) {
      setState(() {
        _isPinSet = hasPin;
        _dailyUnlockLimit = dLimit;
        _emergencyLimit = eLimit;
        _isLoading = false;
      });
    }
  }

  void _handleSavePin() async {
    final settings = ref.read(settingsServiceProvider);

    // Validation
    if (_newPinController.text != _confirmPinController.text) {
      _showSnack("New PINs do not match", isError: true);
      return;
    }
    if (_newPinController.text.length < 4) {
      _showSnack("PIN must be at least 4 digits", isError: true);
      return;
    }
    if (_isPinSet) {
      final isOldCorrect = await settings.verifyPin(_oldPinController.text);
      if (!isOldCorrect) {
        _showSnack("Old PIN is incorrect", isError: true);
        return;
      }
    }

    // Save
    await settings.setPin(_newPinController.text);
    _showSnack("Security Protocol Updated Successfully");

    if (mounted) {
      setState(() {
        _isPinSet = true;
        _oldPinController.clear();
        _newPinController.clear();
        _confirmPinController.clear();
      });
    }
  }

  void _handleSaveLimits() async {
    final usage = ref.read(usageServiceProvider);
    await usage.setMaxDailyUnlocks(_dailyUnlockLimit);
    await usage.setMaxEmergencyUsage(_emergencyLimit);
    _showSnack("Usage Limits Updated!");
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? WakandaTheme.beadRed : WakandaTheme.herbPurple,
      ),
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required bool isDark,
  }) {
    final textColor = isDark ? Colors.white : Colors.black87;
    final fillColor = isDark ? Colors.grey[900] : Colors.grey[200];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: WakandaTheme.vibraniumDark, fontSize: 12, letterSpacing: 1.2),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          keyboardType: TextInputType.number,
          style: TextStyle(color: textColor, letterSpacing: 5),
          decoration: InputDecoration(
            filled: true,
            fillColor: fillColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: WakandaTheme.herbPurple)),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
              onPressed: onToggle,
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildLimitSlider(String label, int value, int min, int max, ValueChanged<int> onChanged, bool isDark) {
    final textColor = isDark ? WakandaTheme.vibranium : Colors.black87;
    final subTextColor = isDark ? WakandaTheme.herbPurple : WakandaTheme.herbPurple; // Keep purple

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            Text("$value", style: TextStyle(color: subTextColor, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: max - min,
          activeColor: WakandaTheme.herbPurple,
          inactiveColor: isDark ? Colors.grey[800] : Colors.grey[300],
          onChanged: (val) => onChanged(val.toInt()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final textColor = isDark ? WakandaTheme.vibranium : Colors.black87;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("SETTINGS PROTOCOL", style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent, // WakandaTheme handles it based on theme
        iconTheme: IconThemeData(color: textColor),
      ),
      body: WakandaBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 100, left: 20, right: 20, bottom: 20), // Added top padding
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION 1: APPEARANCE ---
              const Text(
                "VISUAL INTERFACE",
                style: TextStyle(color: WakandaTheme.herbPurple, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 18),
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                title: Text("Dark Mode", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                subtitle: Text("Toggle Wakanda interface theme", style: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade600)),
                value: isDark,
                activeColor: WakandaTheme.herbPurple,
                onChanged: (val) {
                  ref.read(themeProvider.notifier).toggleTheme(val);
                },
              ),
              
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: Colors.grey),
              ),

              // --- SECTION 2: LIMITS ---
              const Text(
                "ACTIVITY LIMITS",
                style: TextStyle(color: WakandaTheme.herbPurple, fontWeight: FontWeight.bold, letterSpacing: 1.2, fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                "Define your daily discipline restrictions.",
                style: TextStyle(color: textColor),
              ),
              const SizedBox(height: 20),

              _buildLimitSlider("Max Activity Unlocks / Day", _dailyUnlockLimit, 1, 10, (val) {
                setState(() => _dailyUnlockLimit = val);
              }, isDark),
              const SizedBox(height: 10),
              _buildLimitSlider("Max Emergency Bypasses / Day", _emergencyLimit, 0, 5, (val) {
                setState(() => _emergencyLimit = val);
              }, isDark),

              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _handleSaveLimits,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: WakandaTheme.herbPurple),
                    foregroundColor: WakandaTheme.herbPurple,
                  ),
                  child: const Text("SAVE LIMITS"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
