import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/usage_service.dart';
import '../services/pose_detection_service.dart'; // Keep for other refs if needed, but ExerciseType is now in model
import '../models/locked_app.dart';
import '../models/exercise_type.dart';
import '../theme/app_theme.dart';

class LockOverlayScreen extends ConsumerStatefulWidget {
  final String? lockedPackageName;
  const LockOverlayScreen({super.key, required this.lockedPackageName});

  @override
  ConsumerState<LockOverlayScreen> createState() => _LockOverlayScreenState();
}

class _LockOverlayScreenState extends ConsumerState<LockOverlayScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _showPin = false;

  // Stats and Status
  bool _isLoading = true;
  
  // App Config (defaults)
  String _pinCode = "";
  ExerciseType _exerciseType = ExerciseType.squat;
  int _targetReps = 10;
  int _maxExceptions = 3;

  void initState() {
    super.initState();
    _loadAppConfig();
  }

  void _loadAppConfig() {
    final lockedApps = ref.read(lockedAppsProvider);
    final currentApp = lockedApps.firstWhere(
            (app) => app.packageName == widget.lockedPackageName,
        orElse: () => LockedApp(packageName: "", appName: "") // Fallback
    );

    setState(() {
      _pinCode = currentApp.pinCode ?? "";
      _exerciseType = currentApp.exerciseType;
      _targetReps = currentApp.targetReps;
      _isLoading = false;
    });
  }

  void _unlockWithPin() async {
    final inputPin = _pinController.text;
    
    // Verify against App Specific PIN if set, else Global Setting (fallback)
    bool isValid = false;
    if (_pinCode.isNotEmpty) {
      isValid = inputPin == _pinCode;
    } else {
       // Fallback to legacy global verify
       isValid = await ref.read(settingsServiceProvider).verifyPin(inputPin);
    }

    if (isValid) {
      // Increment Per-App Exception Counter (for tracking only)
      if (widget.lockedPackageName != null) {
         await ref.read(appLockServiceProvider).incrementException(widget.lockedPackageName!);
      }
      _performUnlock();
    } else {
      _showSnack('Invalid Access Code!');
    }
  }

  void _startActivity(ExerciseType type) async {

    final result = await Navigator.pushNamed(
        context,
        '/workout',
        arguments: {'package': widget.lockedPackageName, 'type': type}
    );

    if (result == true) {
      // Increment Per-App Unlock Count
      if (widget.lockedPackageName != null) {
          await ref.read(appLockServiceProvider).incrementUnlock(widget.lockedPackageName!);
      }
      _performUnlock();
    }
  }

  void _performUnlock() {
    if (widget.lockedPackageName != null) {
      ref.read(appLockServiceProvider).unlockAppTemporary(
          widget.lockedPackageName!,
          duration: const Duration(minutes: 15)
      );
    }
    SystemNavigator.pop();
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: AppTheme.mySystemRed,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      },
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.transparent,
        body: AppBackground(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: GlassContainer(
                blur: 30,
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_outline, size: 64, color: AppTheme.mySystemBlue),
                    const SizedBox(height: 24),
                    Text(
                      'RESTRICTED ACCESS',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (_isLoading)
                      const CircularProgressIndicator()
                    else
                      Column(
                        children: [
                          Text('CHOOSE CHALLENGE ($_targetReps REPS)', style: const TextStyle(color: Colors.grey, letterSpacing: 1.5)),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_exerciseType == ExerciseType.squat)
                                _ActivityButton(
                                    icon: Icons.accessibility_new,
                                    label: "SQUATS",
                                    onTap: () => _startActivity(ExerciseType.squat)
                                ),
                              if (_exerciseType == ExerciseType.pushup)
                                 _ActivityButton(
                                    icon: Icons.fitness_center,
                                    label: "PUSHUPS",
                                    onTap: () => _startActivity(ExerciseType.pushup)
                                ),
                            ],
                          ),
                        ],
                      ),

                  const SizedBox(height: 40),
                  if (_showPin) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: TextField(
                        controller: _pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, letterSpacing: 5),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: 'PIN',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: AppTheme.mySystemBlue, width: 2)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.mySystemBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _unlockWithPin,
                      child: const Text('UNLOCK', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: () {
                        setState(() { _showPin = true; });
                      },
                      child: const Text('EMERGENCY OVERRIDE (PIN)',
                          style: TextStyle(color: AppTheme.mySystemRed, fontWeight: FontWeight.w600)
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _ActivityButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActivityButton({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkSurface : AppTheme.lightSurface,
          border: Border.all(color: AppTheme.mySystemBlue.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppTheme.mySystemBlue, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary, 
              fontWeight: FontWeight.bold
            )),
          ],
        ),
      ),
    );
  }
}