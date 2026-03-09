import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

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

  // Limit & Goal Values
  int _dailyUnlockLimit = 3;
  int _emergencyLimit = 1;
  int _requiredReps = 10;
  int _dailyStepGoal = 1000;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final hasPin = await ref.read(settingsServiceProvider).isPinSet();
    final settings = ref.read(settingsServiceProvider);
    final rReps = await settings.getRequiredReps();
    final dSteps = await settings.getDailyStepGoal();

    if (mounted) {
      setState(() {
        _isPinSet = hasPin;
        _requiredReps = rReps;
        _dailyStepGoal = dSteps;
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
    final settings = ref.read(settingsServiceProvider);
    await settings.setRequiredReps(_requiredReps);
    await settings.setDailyStepGoal(_dailyStepGoal);

    _showSnack("Exercise Goals Updated!");
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppTheme.mySystemRed : AppTheme.mySystemBlue,
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
          style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 12, letterSpacing: 1.2),
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
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppTheme.mySystemBlue)),
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

  Widget _buildLimitSlider(String label, int value, int min, int max, ValueChanged<int> onChanged, bool isDark, {int? divisions}) {
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    final subTextColor = AppTheme.mySystemBlue;

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
          divisions: divisions ?? (max - min),
          activeColor: AppTheme.mySystemBlue,
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

    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text("SETTINGS", style: TextStyle(color: textColor)),
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: AppBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(top: 100, left: 16, right: 16, bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- SECTION 1: APPEARANCE ---
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: Text(
                  "VISUAL INTERFACE",
                  style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              GlassContainer(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text("App Theme", style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(value: ThemeMode.system, label: Text("System"), icon: Icon(Icons.brightness_auto)),
                        ButtonSegment(value: ThemeMode.light, label: Text("Light"), icon: Icon(Icons.light_mode)),
                        ButtonSegment(value: ThemeMode.dark, label: Text("Dark"), icon: Icon(Icons.dark_mode)),
                      ],
                      selected: {themeMode},
                      onSelectionChanged: (Set<ThemeMode> newSelection) {
                        ref.read(themeProvider.notifier).setTheme(newSelection.first);
                        _showSnack("Theme updated to ${newSelection.first.name.toUpperCase()}");
                      },
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith((states) {
                          if (states.contains(MaterialState.selected)) {
                            return AppTheme.mySystemBlue.withOpacity(0.2);
                          }
                          return Colors.transparent;
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 24),

              // --- SECTION 2: EXERCISE GOALS ---
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 8),
                child: Text(
                  "EXERCISE GOALS",
                  style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              GlassContainer(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLimitSlider("Required Exercise Reps", _requiredReps, 1, 50, (val) {
                      setState(() => _requiredReps = val);
                    }, isDark),
                    
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _handleSaveLimits,
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.mySystemBlue,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text("SAVE GOALS", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
