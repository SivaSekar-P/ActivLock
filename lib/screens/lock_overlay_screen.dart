import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/app_providers.dart';
import '../services/usage_service.dart';
import '../services/pose_detection_service.dart'; // Keep for other refs if needed, but ExerciseType is now in model
import '../models/locked_app.dart';
import '../models/exercise_type.dart';
import '../theme/wakanda_theme.dart';

class LockOverlayScreen extends ConsumerStatefulWidget {
  final String? lockedPackageName;
  const LockOverlayScreen({super.key, required this.lockedPackageName});

  @override
  ConsumerState<LockOverlayScreen> createState() => _LockOverlayScreenState();
}

class _LockOverlayScreenState extends ConsumerState<LockOverlayScreen> {
  final TextEditingController _pinController = TextEditingController();
  bool _showPin = false;

  // Stats
  Map<String, int> _stats = {'unlocks': 0, 'emergency': 0, 'maxUnlocks': 3, 'maxEmergency': 1};
  bool _canUnlock = false;
  bool _canEmergency = false;
  
  // App Config (defaults)
  String _pinCode = "";
  ExerciseType _exerciseType = ExerciseType.squat;
  int _targetReps = 10;
  int _maxExceptions = 3;

  @override
  void initState() {
    super.initState();
    _loadAppConfig();
    _loadLimits();
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
      _maxExceptions = currentApp.dailyExceptions;
    });
  }

  Future<void> _loadLimits() async {
    // Reload app config to get fresh 'usedExceptions' & 'usedUnlocks'
    final lockedApps = ref.read(lockedAppsProvider);
    final currentApp = lockedApps.firstWhere(
            (app) => app.packageName == widget.lockedPackageName,
        orElse: () => LockedApp(packageName: "", appName: "")
    );
    
    // Check Per-App Daily Unlock Limit
    final int usedU = currentApp.usedUnlocks;
    final int limitU = currentApp.dailyUnlockLimit;
    final canU = usedU < limitU;
    
    // Check Per-App Emergency Limit
    final int usedE = currentApp.usedExceptions;
    final int limitE = currentApp.dailyExceptions;
    final canE = usedE < limitE;

    if (mounted) {
      setState(() {
        _stats['unlocks'] = usedU;
        _stats['maxUnlocks'] = limitU;
        _stats['emergency'] = usedE;
        _stats['maxEmergency'] = limitE;
        _canUnlock = canU;
        _canEmergency = canE;
      });
    }
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
      if (_canEmergency) {
        // Increment Per-App Exception
        if (widget.lockedPackageName != null) {
           await ref.read(appLockServiceProvider).incrementException(widget.lockedPackageName!);
        }
        _performUnlock();
      } else {
        _showSnack('Emergency limit reached for this app!');
      }
    } else {
      _showSnack('Invalid Access Code!');
    }
  }

  void _startActivity(ExerciseType type) async {
    if (!_canUnlock) {
      _showSnack('Daily activity unlock limit reached!');
      return;
    }

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
      backgroundColor: WakandaTheme.beadRed,
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
        backgroundColor: WakandaTheme.onyx.withOpacity(0.98),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [WakandaTheme.blackMetal, WakandaTheme.onyx],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline, size: 60, color: WakandaTheme.vibranium),
                  const SizedBox(height: 20),
                  Text(
                    'RESTRICTED ACCESS',
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 3.0,
                      color: WakandaTheme.vibranium,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Daily Unlocks: ${_stats['unlocks']}/${_stats['maxUnlocks']}',
                    style: TextStyle(color: _canUnlock ? WakandaTheme.herbLight : WakandaTheme.beadRed),
                  ),
                  const SizedBox(height: 40),

                  if (_canUnlock) ...[
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
                  ] else ...[
                    const Text(
                      'DAILY LIMIT REACHED',
                      style: TextStyle(color: WakandaTheme.beadRed, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Text('Come back tomorrow.', style: TextStyle(color: Colors.grey)),
                  ],

                  const SizedBox(height: 40),
                  if (_showPin) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 60),
                      child: TextField(
                        controller: _pinController,
                        obscureText: true,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: WakandaTheme.vibranium, letterSpacing: 5),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: 'PIN',
                          hintStyle: TextStyle(color: Colors.grey),
                          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: WakandaTheme.beadRed),
                      onPressed: _unlockWithPin,
                      child: const Text('UNLOCK'),
                    ),
                  ] else ...[
                    TextButton(
                      onPressed: () {
                        if (_canEmergency) {
                          setState(() { _showPin = true; });
                        } else {
                          _showSnack('No emergency unlocks left!');
                        }
                      },
                      child: Text(
                          'EMERGENCY OVERRIDE (${_stats['emergency']}/${_stats['maxEmergency']})',
                          style: const TextStyle(color: WakandaTheme.vibraniumDark, letterSpacing: 1.2)
                      ),
                    ),
                  ]
                ],
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
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: WakandaTheme.blackMetal,
          border: Border.all(color: WakandaTheme.herbPurple),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, color: WakandaTheme.vibranium, size: 30),
            const SizedBox(height: 5),
            Text(label, style: const TextStyle(color: WakandaTheme.vibranium, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}