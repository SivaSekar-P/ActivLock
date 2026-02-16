import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:typed_data';
import '../models/locked_app.dart';
import '../models/exercise_type.dart';
import '../providers/app_providers.dart';
import '../theme/wakanda_theme.dart';
import '../theme/wakanda_background.dart';

class AppConfigurationScreen extends ConsumerStatefulWidget {
  final String packageName;
  final String appName;
  final int initialStep;
  final bool isEditing; // New: If true, shows single step with Save button

  const AppConfigurationScreen({
    super.key,
    required this.packageName,
    required this.appName,
    this.initialStep = 0,
    this.isEditing = false,
  });

  @override
  ConsumerState<AppConfigurationScreen> createState() => _AppConfigurationScreenState();
}

class _AppConfigurationScreenState extends ConsumerState<AppConfigurationScreen> {
  late int _currentStep;
  
  // PIN Config
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  
  // Exercise Config
  ExerciseType _selectedExercise = ExerciseType.squat;
  int _targetReps = 15;
  
  // Limits Config
  int _maxExceptions = 3;
  int _dailyUnlockLimit = 10; // New

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep;
    _loadExistingSettings();
  }

  void _loadExistingSettings() {
    final apps = ref.read(lockedAppsProvider);
    try {
      final app = apps.firstWhere((a) => a.packageName == widget.packageName);
      _pinController.text = app.pinCode ?? "";
      _confirmPinController.text = app.pinCode ?? "";
      _selectedExercise = app.exerciseType;
      _targetReps = app.targetReps;
      _maxExceptions = app.dailyExceptions;
      _dailyUnlockLimit = app.dailyUnlockLimit;
    } catch (e) {
      // Defaults
    }
  }

  void _nextStep() {
    setState(() => _currentStep++);
  }

  void _prevStep() {
    setState(() => _currentStep--);
  }

  void _finishSetup() {
    // Validation
    if (_currentStep == 0 || widget.isEditing) {
       if (_pinController.text != _confirmPinController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PINs do not match!"), backgroundColor: Colors.red));
        return;
      }
      if (_pinController.text.length < 4) {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("PIN must be at least 4 digits"), backgroundColor: Colors.red));
        return;
      }
    }

    // Preserve existing counters
    final existingApps = ref.read(lockedAppsProvider);
    int existingUsedEx = 0;
    int existingUsedUnlocks = 0;
    DateTime? existingReset;
    try {
       final oldApp = existingApps.firstWhere((a) => a.packageName == widget.packageName);
       existingUsedEx = oldApp.usedExceptions;
       existingUsedUnlocks = oldApp.usedUnlocks;
       existingReset = oldApp.lastResetDate;
    } catch (_) {}

    final app = LockedApp(
      packageName: widget.packageName,
      appName: widget.appName,
      isLocked: true,
      pinCode: _pinController.text,
      exerciseType: _selectedExercise,
      targetReps: _targetReps,
      dailyExceptions: _maxExceptions,
      usedExceptions: existingUsedEx,
      dailyUnlockLimit: _dailyUnlockLimit,
      usedUnlocks: existingUsedUnlocks,
      lastResetDate: existingReset,
    );

    ref.read(lockedAppsProvider.notifier).addApp(app);
    Navigator.of(context).pop();
  }

  Widget _buildStepContent(int stepIndex, Color textColor, Color subTextColor, Color inputFillColor, bool isDark) {
    switch (stepIndex) {
      case 0: // PIN
        return Column(
          children: [
            Text("Set Access PIN", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Used for emergency overrides", style: TextStyle(color: subTextColor)),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              style: TextStyle(color: textColor, letterSpacing: 5),
              decoration: InputDecoration(
                labelText: "Enter 4-digit PIN",
                labelStyle: const TextStyle(color: WakandaTheme.herbLight),
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _confirmPinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              style: TextStyle(color: textColor, letterSpacing: 5),
              decoration: InputDecoration(
                labelText: "Confirm PIN",
                labelStyle: const TextStyle(color: WakandaTheme.herbLight),
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
            ),
          ],
        );
      case 1: // EXERCISE
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Scanning Protocol", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Required activity to unlock", style: TextStyle(color: subTextColor)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(color: inputFillColor, borderRadius: BorderRadius.circular(8)),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<ExerciseType>(
                  value: _selectedExercise,
                  dropdownColor: isDark ? WakandaTheme.onyx : Colors.white,
                  style: TextStyle(color: textColor),
                  isExpanded: true,
                  onChanged: (val) => setState(() => _selectedExercise = val!),
                  items: ExerciseType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.name.toUpperCase()))).toList(),
                ),
              ),
            ),
            const SizedBox(height: 15),
            Text("Target Reps: $_targetReps", style: TextStyle(color: textColor)),
            Slider(
              value: _targetReps.toDouble(),
              min: 5, max: 50, divisions: 9,
              activeColor: WakandaTheme.herbPurple,
              label: _targetReps.toString(),
              onChanged: (val) => setState(() => _targetReps = val.round()),
            ),
          ],
        );
      case 2: // LIMITS
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Usage Restrictions", style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)),
            Text("Define daily allowances", style: TextStyle(color: subTextColor)),
            const SizedBox(height: 20),
            
            Text("Max Unlocks per Day: $_dailyUnlockLimit", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            Slider(
              value: _dailyUnlockLimit.toDouble(),
              min: 1, max: 50, divisions: 49,
              activeColor: WakandaTheme.vibranium,
              label: _dailyUnlockLimit.toString(),
              onChanged: (val) => setState(() => _dailyUnlockLimit = val.round()),
            ),
            const SizedBox(height: 15),
            
            Text("Emergency Bypasses: $_maxExceptions", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
            Slider(
              value: _maxExceptions.toDouble(),
              min: 0, max: 10, divisions: 10,
              activeColor: WakandaTheme.beadRed,
              label: _maxExceptions.toString(),
              onChanged: (val) => setState(() => _maxExceptions = val.round()),
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final subTextColor = isDark ? Colors.white54 : Colors.black54;
    final inputFillColor = isDark ? (Colors.grey[900] ?? Colors.black) : (Colors.grey[200] ?? Colors.white);

    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        title: Text(widget.isEditing ? "EDIT SETTINGS" : "SECURE ${widget.appName.toUpperCase()}", 
          style: TextStyle(fontSize: 16, color: textColor)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: WakandaBackground(
        child: SafeArea(
          child: widget.isEditing
              ? Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildStepContent(_currentStep, textColor, subTextColor, inputFillColor, isDark),
                      const Spacer(),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: WakandaTheme.herbPurple, foregroundColor: Colors.white),
                          onPressed: _finishSetup,
                          child: const Text("SAVE CHANGES"),
                        ),
                      ),
                    ],
                  ),
                )
              : Stepper(
                  type: StepperType.vertical,
                  currentStep: _currentStep,
                  onStepContinue: _currentStep < 2 ? _nextStep : _finishSetup,
                  onStepCancel: _currentStep > 0 ? _prevStep : null,
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: WakandaTheme.herbPurple, foregroundColor: Colors.white),
                            onPressed: details.onStepContinue,
                            child: Text(_currentStep == 2 ? "ACTIVATE" : "NEXT"),
                          ),
                          if (_currentStep > 0) ...[
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: Text("BACK", style: TextStyle(color: subTextColor)),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: Text("Set Access PIN", style: TextStyle(color: textColor)),
                      subtitle: Text("Security Code", style: TextStyle(color: subTextColor)),
                      isActive: _currentStep >= 0,
                      content: _buildStepContent(0, textColor, subTextColor, inputFillColor, isDark),
                    ),
                    Step(
                      title: Text("Scanning Protocol", style: TextStyle(color: textColor)),
                      subtitle: Text("Activity Rules", style: TextStyle(color: subTextColor)),
                      isActive: _currentStep >= 1,
                      content: _buildStepContent(1, textColor, subTextColor, inputFillColor, isDark),
                    ),
                    Step(
                      title: Text("Usage Restrictions", style: TextStyle(color: textColor)),
                      subtitle: Text("Limits & Bypasses", style: TextStyle(color: subTextColor)),
                      isActive: _currentStep >= 2,
                      content: _buildStepContent(2, textColor, subTextColor, inputFillColor, isDark),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
