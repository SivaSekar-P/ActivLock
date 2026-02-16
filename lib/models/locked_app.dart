import 'exercise_type.dart';

class LockedApp {
  final String packageName;
  final String appName;
  final bool isLocked;
  final String? pinCode;
  final ExerciseType exerciseType;
  final int targetReps;
  final int dailyExceptions;
  final int usedExceptions;
  final int dailyUnlockLimit; // New
  final int usedUnlocks;      // New
  final DateTime? lastResetDate;

  LockedApp({
    required this.packageName,
    required this.appName,
    this.isLocked = true,
    this.pinCode,
    this.exerciseType = ExerciseType.squat,
    this.targetReps = 10,
    this.dailyExceptions = 3,
    this.usedExceptions = 0,
    this.dailyUnlockLimit = 10,
    this.usedUnlocks = 0,
    this.lastResetDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'packageName': packageName,
      'appName': appName,
      'isLocked': isLocked,
      'pinCode': pinCode,
      'exerciseType': exerciseType.index,
      'targetReps': targetReps,
      'dailyExceptions': dailyExceptions,
      'usedExceptions': usedExceptions,
      'dailyUnlockLimit': dailyUnlockLimit,
      'usedUnlocks': usedUnlocks,
      'lastResetDate': lastResetDate?.toIso8601String(),
    };
  }

  factory LockedApp.fromJson(Map<String, dynamic> json) {
    return LockedApp(
      packageName: json['packageName'],
      appName: json['appName'],
      isLocked: json['isLocked'] ?? true,
      pinCode: json['pinCode'],
      exerciseType: json['exerciseType'] != null
          ? ExerciseType.values[json['exerciseType']]
          : ExerciseType.squat,
      targetReps: json['targetReps'] ?? 10,
      dailyExceptions: json['dailyExceptions'] ?? 3,
      usedExceptions: json['usedExceptions'] ?? 0,
      dailyUnlockLimit: json['dailyUnlockLimit'] ?? 10,
      usedUnlocks: json['usedUnlocks'] ?? 0,
      lastResetDate: json['lastResetDate'] != null
          ? DateTime.parse(json['lastResetDate'])
          : null,
    );
  }
}