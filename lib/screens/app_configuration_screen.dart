import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/locked_app.dart';
import '../models/exercise_type.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

enum EditMode { none, pin, workout, limits }

class AppConfigurationScreen extends ConsumerStatefulWidget {
  final String packageName;
  final String appName;
  final int initialStep;
  final bool isEditing; 
  final EditMode editMode;

  const AppConfigurationScreen({
    super.key,
    required this.packageName,
    required this.appName,
    this.initialStep = 0,
    this.isEditing = false,
    this.editMode = EditMode.none,
  });

  @override
  ConsumerState<AppConfigurationScreen> createState() => _AppConfigurationScreenState();
}

class _AppConfigurationScreenState extends ConsumerState<AppConfigurationScreen> {
  late int _currentStep;
  
  // PIN Config
  final TextEditingController _oldPinController = TextEditingController();
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmPinController = TextEditingController();
  bool _isOldPinVerified = false;
  String _storedPin = "";
  
  // Exercise Config
  ExerciseType _selectedExercise = ExerciseType.squat;
  int _targetReps = 15;
  
  // Usage Constraints Config
  int _usageTimeLimit = 15;
  int _maxExceptions = 3;
  int _dailyUnlockLimit = 10;

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
      _storedPin = app.pinCode ?? "";
      if (!widget.isEditing) {
        _pinController.text = _storedPin;
        _confirmPinController.text = _storedPin;
      }
      _selectedExercise = app.exerciseType;
      _targetReps = app.targetReps;
      _usageTimeLimit = app.usageTimeLimit;
      _maxExceptions = app.dailyExceptions;
      _dailyUnlockLimit = app.dailyUnlockLimit;
    } catch (e) {
      // Defaults already set
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_pinController.text.length < 4) {
         _showError("PIN must be at least 4 digits");
         return;
      }
    }
    if (_currentStep == 1) {
      if (_pinController.text != _confirmPinController.text) {
         _showError("PINs do not match!");
         return;
      }
    }
    setState(() => _currentStep++);
  }

  void _prevStep() {
    setState(() => _currentStep--);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.mySystemRed,
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _verifyOldPin() {
    if (_oldPinController.text == _storedPin) {
      setState(() {
        _isOldPinVerified = true;
      });
    } else {
      _showError("Incorrect Old PIN!");
    }
  }

  void _finishSetup() {
    // Validation for PIN editing
    if (widget.isEditing && widget.editMode == EditMode.pin) {
      if (!_isOldPinVerified) {
        _showError("Please verify old PIN first");
        return;
      }
      if (_pinController.text != _confirmPinController.text) {
        _showError("PINs do not match!");
        return;
      }
      if (_pinController.text.length < 4) {
        _showError("New PIN must be at least 4 digits");
        return;
      }
    }

    // Preserve existing counters if editing
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
      pinCode: (widget.isEditing && widget.editMode == EditMode.pin) ? _pinController.text : _storedPin,
      exerciseType: _selectedExercise,
      targetReps: _targetReps,
      dailyExceptions: _maxExceptions,
      usedExceptions: existingUsedEx,
      dailyUnlockLimit: _dailyUnlockLimit,
      usedUnlocks: existingUsedUnlocks,
      usageTimeLimit: _usageTimeLimit,
      lastResetDate: existingReset,
    );

    ref.read(lockedAppsProvider.notifier).addApp(app);
    Navigator.of(context).pop();
  }

  Widget _buildSectionHeader(String title, IconData icon, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppTheme.mySystemBlue),
          const SizedBox(width: 10),
          Text(title, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildPinFields(Color textColor, Color subTextColor, Color inputFillColor, bool isDark) {
    if (widget.isEditing && !_isOldPinVerified) {
      return Column(
        children: [
          _buildSectionHeader("VERIFY IDENTITY", Icons.lock_outline, textColor),
          Text("Enter your current PIN to continue", style: TextStyle(color: subTextColor, fontSize: 13)),
          const SizedBox(height: 20),
          TextField(
            controller: _oldPinController,
            keyboardType: TextInputType.number,
            obscureText: true,
            style: TextStyle(color: textColor, letterSpacing: 8),
            decoration: InputDecoration(
              labelText: "Current PIN",
              labelStyle: TextStyle(color: subTextColor, letterSpacing: 0),
              filled: true,
              fillColor: inputFillColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              prefixIcon: const Icon(Icons.password, color: AppTheme.mySystemBlue),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.mySystemBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _verifyOldPin,
              child: const Text("VERIFY PIN", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      );
    }

    return Column(
      children: [
        _buildSectionHeader(widget.isEditing ? "SET NEW PIN" : "SECURITY ACCESS", Icons.lock_clock_outlined, textColor),
        TextField(
          controller: _pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          style: TextStyle(color: textColor, letterSpacing: 8),
          decoration: InputDecoration(
            labelText: widget.isEditing ? "New 4-digit PIN" : "Set 4-digit PIN",
            labelStyle: TextStyle(color: subTextColor, letterSpacing: 0),
            filled: true,
            fillColor: inputFillColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.pin, color: AppTheme.mySystemBlue),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _confirmPinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          style: TextStyle(color: textColor, letterSpacing: 8),
          decoration: InputDecoration(
            labelText: "Confirm PIN",
            labelStyle: TextStyle(color: subTextColor, letterSpacing: 0),
            filled: true,
            fillColor: inputFillColor,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            prefixIcon: const Icon(Icons.check_circle_outline, color: AppTheme.mySystemBlue),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseSection(Color textColor, Color subTextColor, Color inputFillColor, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("CHALLENGE TYPE", Icons.fitness_center, textColor),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: inputFillColor, borderRadius: BorderRadius.circular(12)),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ExerciseType>(
              value: _selectedExercise,
              dropdownColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
              isExpanded: true,
              onChanged: (val) {
                setState(() {
                  _selectedExercise = val!;
                  // Adjust target if current is out of range for new type
                  if (_selectedExercise == ExerciseType.steps) {
                    if (_targetReps < 10) _targetReps = 50;
                  } else {
                    if (_targetReps > 50) _targetReps = 15;
                  }
                });
              },
              items: ExerciseType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.name.toUpperCase()))).toList(),
            ),
          ),
        ),
        const SizedBox(height: 20),
        _buildNumericInputRow(
          label: _selectedExercise == ExerciseType.steps ? "Target Steps" : "Target Reps",
          value: _targetReps,
          min: _selectedExercise == ExerciseType.steps ? 10 : 1,
          max: _selectedExercise == ExerciseType.steps ? 500 : 100,
          onChanged: (val) => setState(() => _targetReps = val),
          textColor: textColor,
          inputFillColor: inputFillColor,
          activeColor: AppTheme.mySystemBlue,
        ),
      ],
    );
  }

  Widget _buildConstraintSection(Color textColor, Color subTextColor, Color inputFillColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader("ACCESS LIMITS", Icons.timer_outlined, textColor),
        
        _buildNumericInputRow(label: "Session Limit (min)", value: _usageTimeLimit, min: 1, max: 120, onChanged: (v) => setState(() => _usageTimeLimit = v), textColor: textColor, inputFillColor: inputFillColor, activeColor: AppTheme.mySystemBlue),
        const SizedBox(height: 15),
        _buildNumericInputRow(label: "Daily Emergency", value: _maxExceptions, min: 0, max: 20, onChanged: (v) => setState(() => _maxExceptions = v), textColor: textColor, inputFillColor: inputFillColor, activeColor: AppTheme.mySystemRed),
        const SizedBox(height: 15),
        _buildNumericInputRow(label: "Daily Unlock Limit", value: _dailyUnlockLimit, min: 1, max: 100, onChanged: (v) => setState(() => _dailyUnlockLimit = v), textColor: textColor, inputFillColor: inputFillColor, activeColor: AppTheme.mySystemPurple),
      ],
    );
  }

  Widget _buildNumericInputRow({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
    required Color textColor,
    required Color inputFillColor,
    required Color activeColor,
  }) {
    final controller = TextEditingController(text: "$value");
    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: textColor, fontWeight: FontWeight.w500, fontSize: 13)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                height: 50,
                decoration: BoxDecoration(color: inputFillColor, borderRadius: BorderRadius.circular(12)),
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                  decoration: const InputDecoration(border: OutlineInputBorder(borderSide: BorderSide.none), contentPadding: EdgeInsets.zero),
                  onSubmitted: (text) {
                    int? newVal = int.tryParse(text);
                    if (newVal != null) {
                      newVal = newVal.clamp(min, max);
                      onChanged(newVal);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 12),
            _buildStepButton(Icons.remove, () {
              if (value > min) onChanged(value - 1);
            }, activeColor.withOpacity(0.1), activeColor),
            const SizedBox(width: 8),
            _buildStepButton(Icons.add, () {
              if (value < max) onChanged(value + 1);
            }, activeColor.withOpacity(0.1), activeColor),
          ],
        ),
      ],
    );
  }

  Widget _buildStepButton(IconData icon, VoidCallback onTap, Color bgColor, Color iconColor) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: iconColor),
      ),
    );
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
          style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: AppBackground(
        child: SafeArea(
          child: widget.isEditing
              ? Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Column(
                          children: [
                            if (widget.editMode == EditMode.pin)
                              GlassContainer(child: _buildPinFields(textColor, subTextColor, inputFillColor, isDark)),
                            if (widget.editMode == EditMode.workout)
                              GlassContainer(child: _buildExerciseSection(textColor, subTextColor, inputFillColor, isDark)),
                            if (widget.editMode == EditMode.limits)
                              GlassContainer(child: _buildConstraintSection(textColor, subTextColor, inputFillColor)),
                            const SizedBox(height: 100), 
                          ],
                        ),
                      ),
                    ),
                    if (widget.editMode != EditMode.pin || _isOldPinVerified)
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.mySystemBlue, 
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: AppTheme.mySystemBlue.withOpacity(0.4),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: _finishSetup,
                          child: const Text("SAVE SETTINGS", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.5)),
                        ),
                      ),
                    ),
                  ],
                )
              : Stepper(
                  type: StepperType.vertical,
                  currentStep: _currentStep,
                  onStepContinue: _currentStep < 3 ? _nextStep : _finishSetup,
                  onStepCancel: _currentStep > 0 ? _prevStep : null,
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Row(
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mySystemBlue, foregroundColor: Colors.white),
                            onPressed: details.onStepContinue,
                            child: Text(_currentStep == 3 ? "ACTIVATE" : "NEXT", style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          if (_currentStep > 0) ...[
                            const SizedBox(width: 10),
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: Text("BACK", style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: Text("Set Access PIN", style: TextStyle(color: textColor)),
                      subtitle: Text("Security Level 1", style: TextStyle(color: subTextColor, fontSize: 12)),
                      isActive: _currentStep >= 0,
                      content: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text("Used for emergency bypass", style: TextStyle(color: subTextColor, fontSize: 14)),
                            const SizedBox(height: 15),
                            TextField(
                              controller: _pinController,
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              style: TextStyle(color: textColor, letterSpacing: 5),
                              decoration: InputDecoration(
                                labelText: "Enter 4-digit PIN",
                                labelStyle: TextStyle(color: subTextColor),
                                filled: true,
                                fillColor: inputFillColor,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Step(
                      title: Text("Confirm PIN", style: TextStyle(color: textColor)),
                      subtitle: Text("Verification", style: TextStyle(color: subTextColor, fontSize: 12)),
                      isActive: _currentStep >= 1,
                      content: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _confirmPinController,
                          keyboardType: TextInputType.number,
                          obscureText: true,
                          style: TextStyle(color: textColor, letterSpacing: 5),
                          decoration: InputDecoration(
                            labelText: "Confirm PIN",
                            labelStyle: TextStyle(color: subTextColor),
                            filled: true,
                            fillColor: inputFillColor,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ),
                    Step(
                      title: Text("Challenge Model", style: TextStyle(color: textColor)),
                      subtitle: Text("Activity Rules", style: TextStyle(color: subTextColor, fontSize: 12)),
                      isActive: _currentStep >= 2,
                      content: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: _buildExerciseSection(textColor, subTextColor, inputFillColor, isDark),
                      ),
                    ),
                    Step(
                      title: Text("Access Limits", style: TextStyle(color: textColor)),
                      subtitle: Text("Limit Control", style: TextStyle(color: subTextColor, fontSize: 12)),
                      isActive: _currentStep >= 3,
                      content: GlassContainer(
                        padding: const EdgeInsets.all(16),
                        child: _buildConstraintSection(textColor, subTextColor, inputFillColor),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}


