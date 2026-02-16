import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import '../models/exercise_type.dart';

enum ExerciseState { neutral, down, up }

class PoseDetectionService {
  final PoseDetector _poseDetector = PoseDetector(options: PoseDetectorOptions());

  ExerciseState _state = ExerciseState.neutral;
  int _reps = 0;
  ExerciseType _currentType = ExerciseType.squat;

  // Data for UI
  Pose? _currentPose;
  String _feedbackMessage = "Initializing...";
  bool _isBodyVisible = false;

  Pose? get rawPose => _currentPose;
  int get reps => _reps;
  ExerciseState get state => _state;
  String get feedback => _feedbackMessage;
  bool get isBodyVisible => _isBodyVisible;

  void setExerciseType(ExerciseType type) {
    _currentType = type;
    reset();
  }

  void reset() {
    _reps = 0;
    _state = ExerciseState.neutral;
    _currentPose = null;
    _feedbackMessage = "Stand in frame";
    _isBodyVisible = false;
    _initTime = null;
  }

  DateTime? _initTime;

  Future<void> processImage(InputImage inputImage) async {
    if (_initTime == null) {
      _initTime = DateTime.now();
    }
    
    // Ignore first 2 seconds to let user settle
    if (DateTime.now().difference(_initTime!).inSeconds < 2) {
       _feedbackMessage = "Get Ready...";
       return;
    }

    final poses = await _poseDetector.processImage(inputImage);
    if (poses.isEmpty) {
      _currentPose = null;
      _feedbackMessage = "No person detected";
      _isBodyVisible = false;
      return;
    }

    _currentPose = poses.first;

    // Check Visibility of Critical Joints
    if (!_checkVisibility(_currentPose!)) {
      _isBodyVisible = false;
      _feedbackMessage = "Full body not visible!\nStep back.";
      return;
    }
    _isBodyVisible = true;

    if (_currentType == ExerciseType.squat) {
      _processSquat(_currentPose!);
    } else {
      _processPushup(_currentPose!);
    }
  }

  bool _checkVisibility(Pose pose) {
    // We need Shoulders, Hips, Knees, and Ankles/Wrists depending on exercise
    final landmarks = pose.landmarks;

    // Basic check: Are hips and shoulders visible?
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftHip = landmarks[PoseLandmarkType.leftHip];
    final rightHip = landmarks[PoseLandmarkType.rightHip];

    if (!_isValid(leftShoulder) || !_isValid(rightShoulder) ||
        !_isValid(leftHip) || !_isValid(rightHip)) {
      return false;
    }

    // Specific Checks
    if (_currentType == ExerciseType.squat) {
      // Need Knees
      final leftKnee = landmarks[PoseLandmarkType.leftKnee];
      final rightKnee = landmarks[PoseLandmarkType.rightKnee];
      if (!_isValid(leftKnee) || !_isValid(rightKnee)) return false;
    } else {
      // Pushup: Need Elbows/Wrists
      final leftElbow = landmarks[PoseLandmarkType.leftElbow];
      final rightElbow = landmarks[PoseLandmarkType.rightElbow];
      if (!_isValid(leftElbow) || !_isValid(rightElbow)) return false;
    }

    return true;
  }

  bool _isValid(PoseLandmark? l) {
    return l != null && l.likelihood > 0.5;
  }

  // State Management for Debouncing
  DateTime? _stateStartTime;
  bool _isHoldingDown = false;
  DateTime _lastRepTime = DateTime.fromMillisecondsSinceEpoch(0);
  final Duration _cooldown = const Duration(seconds: 1); // Min time between reps
  final Duration _dwellTime = const Duration(milliseconds: 300); // Time to hold pose

  void _processSquat(Pose pose) {
    final leftHip = pose.landmarks[PoseLandmarkType.leftHip];
    final leftKnee = pose.landmarks[PoseLandmarkType.leftKnee];
    final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];

    // Angle: Hip-Knee-Ankle
    final angle = _calculateAngle(leftHip!, leftKnee!, leftAnkle!);

    // LOGIC:
    // Stand: ~170-180
    // Squat Down: < 100

    final now = DateTime.now();

    if (_state == ExerciseState.neutral || _state == ExerciseState.up) {
      if (angle < 100) {
        // Candidate for DOWN
        if (_stateStartTime == null) {
          _stateStartTime = now;
          _feedbackMessage = "HOLD...";
        } else if (now.difference(_stateStartTime!) > _dwellTime) {
          // Confirmed DOWN
          _state = ExerciseState.down;
          _isHoldingDown = true;
          _feedbackMessage = "HOLD";
        }
      } else {
        // Reset if they stood back up before dwelling
        _stateStartTime = null;
        _feedbackMessage = "GO DOWN";
      }
    } else if (_state == ExerciseState.down) {
      if (angle > 160) {
        // Candidate for UP
        if (_isHoldingDown) {
           if (now.difference(_lastRepTime) > _cooldown) {
             _state = ExerciseState.up;
             _reps++;
             _lastRepTime = now;
             _feedbackMessage = "GOOD!";
             _isHoldingDown = false;
             _stateStartTime = null; // Reset for next cycle
           }
        }
      } else {
         _feedbackMessage = "UP!";
      }
    }
  }

  void _processPushup(Pose pose) {
    // Side view Pushup
    final leftShoulder = pose.landmarks[PoseLandmarkType.leftShoulder];
    final leftElbow = pose.landmarks[PoseLandmarkType.leftElbow];
    final leftWrist = pose.landmarks[PoseLandmarkType.leftWrist];

    // Angle: Shoulder-Elbow-Wrist
    final elbowAngle = _calculateAngle(leftShoulder!, leftElbow!, leftWrist!);
    final now = DateTime.now();

    if (_state == ExerciseState.neutral || _state == ExerciseState.up) {
      if (elbowAngle < 90) {
          // Candidate for DOWN
        if (_stateStartTime == null) {
          _stateStartTime = now;
          _feedbackMessage = "HOLD...";
        } else if (now.difference(_stateStartTime!) > _dwellTime) {
          // Confirmed DOWN
          _state = ExerciseState.down;
          _isHoldingDown = true;
          _feedbackMessage = "HOLD";
        }
      } else {
        _stateStartTime = null;
        _feedbackMessage = "PUSH DOWN";
      }
    } else if (_state == ExerciseState.down) {
      if (elbowAngle > 160) {
         if (_isHoldingDown) {
            if (now.difference(_lastRepTime) > _cooldown) {
              _state = ExerciseState.up;
              _reps++;
              _lastRepTime = now;
              _feedbackMessage = "GOOD!";
              _isHoldingDown = false;
              _stateStartTime = null;
            }
         }
      } else {
        _feedbackMessage = "PUSH UP";
      }
    }
  }

  double _calculateAngle(PoseLandmark first, PoseLandmark mid, PoseLandmark last) {
    final double result = math.atan2(last.y - mid.y, last.x - mid.x) -
        math.atan2(first.y - mid.y, first.x - mid.x);
    double angle = result * (180 / math.pi);
    angle = angle.abs();
    if (angle > 180) {
      angle = 360.0 - angle;
    }
    return angle;
  }

  void close() {
    _poseDetector.close();
  }
}