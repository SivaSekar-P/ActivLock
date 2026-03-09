import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:io';
import '../models/exercise_type.dart';
import '../services/pose_detection_service.dart';
import '../services/usage_service.dart';
import '../theme/app_theme.dart';
import '../providers/app_providers.dart';

class WorkoutScreen extends ConsumerStatefulWidget {
  final String? lockedPackageName;
  final ExerciseType exerciseType;

  const WorkoutScreen({super.key, this.lockedPackageName, required this.exerciseType});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  CameraController? _controller;
  final PoseDetectionService _poseService = PoseDetectionService();
  bool _isProcessing = false;
  int _reps = 0;
  int _targetReps = 10;
  String _status = "Prepare";
  String _feedback = "";
  CameraLensDirection _cameraDirection = CameraLensDirection.front;

  // For Painting
  Size? _imageSize;
  InputImageRotation _rotation = InputImageRotation.rotation270deg;

  @override
  void initState() {
    super.initState();
    _poseService.setExerciseType(widget.exerciseType);
    _initializeCamera();
    _loadTargetReps();

    // Show Instructions Dialog after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _showInstructions());
  }

  Future<void> _loadTargetReps() async {
    final lockedApps = ref.read(lockedAppsProvider);
    try {
      final app = lockedApps.firstWhere((a) => a.packageName == widget.lockedPackageName);
      if (mounted) {
        setState(() {
          _targetReps = app.targetReps;
        });
      }
    } catch (_) {
      final reps = await ref.read(settingsServiceProvider).getRequiredReps();
      if (mounted) {
        setState(() {
          _targetReps = reps;
        });
      }
    }
  }

  void _showInstructions() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: AppTheme.mySystemBlue)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: AppTheme.mySystemBlue),
            const SizedBox(width: 10),
            Text("${widget.exerciseType.name.toUpperCase()} SETUP", style: TextStyle(color: textColor, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _instructionStep("1. Place phone on the floor, leaning against a wall.", isDark),
            const SizedBox(height: 10),
            _instructionStep("2. Ensure the front camera faces you.", isDark),
            const SizedBox(height: 10),
            _instructionStep("3. Step back until your WHOLE body is visible (Head to Toe).", isDark),
            const SizedBox(height: 10),
            _instructionStep("4. Wait for the skeleton lines to appear.", isDark),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("I'M READY"),
          )
        ],
      ),
    );
  }

  Widget _instructionStep(String text, bool isDark) {
    return Text(text, style: TextStyle(color: isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary, fontSize: 14));
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final selectedCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == _cameraDirection,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.nv21
          : ImageFormatGroup.bgra8888,
    );

    await _controller!.initialize();
    if (!mounted) return;

    _rotation = InputImageRotation.rotation270deg;
    _controller!.startImageStream(_processCameraImage);
    setState(() {});
  }

  void _toggleCamera() {
    setState(() {
      _cameraDirection = _cameraDirection == CameraLensDirection.front
          ? CameraLensDirection.back
          : CameraLensDirection.front;
    });
    _controller?.dispose();
    _controller = null;
    _initializeCamera();
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    if (_imageSize == null) {
      _imageSize = Size(image.width.toDouble(), image.height.toDouble());
    }

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      await _poseService.processImage(inputImage);

      if (mounted) {
        setState(() {
          _reps = _poseService.reps;
          _status = _poseService.state == ExerciseState.down ? "DOWN" : "UP";
          _feedback = _poseService.feedback;
        });

        if (_reps >= _targetReps) {
          _handleSuccess();
        }
      }
    } catch (e) {
      debugPrint("Error processing image: $e");
    } finally {
      _isProcessing = false;
    }
  }

  void _handleSuccess() async {
    await _controller?.stopImageStream();
    await ref.read(usageServiceProvider).incrementUnlockCount();

    if (!mounted) return;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppTheme.darkSurface : AppTheme.lightSurface,
        title: const Text("UNLOCKED!", style: TextStyle(color: AppTheme.mySystemBlue, fontWeight: FontWeight.bold)),
        content: Text("Protocol complete. Access granted for 15 minutes.", style: TextStyle(color: isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text("OPEN APP", style: TextStyle(color: AppTheme.mySystemBlue, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;
    final InputImageRotation rotation = InputImageRotation.rotation270deg;
    final format = Platform.isAndroid ? InputImageFormat.nv21 : InputImageFormat.bgra8888;

    return InputImage.fromBytes(
      bytes: image.planes.first.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    _poseService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final size = MediaQuery.of(context).size;
    // Check if body is fully visible
    final isVisible = _poseService.isBodyVisible;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. FULL SCREEN CAMERA
          SizedBox(
            width: size.width,
            height: size.height,
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _controller!.value.previewSize!.height,
                height: _controller!.value.previewSize!.width,
                child: CameraPreview(_controller!),
              ),
            ),
          ),

          // 2. MINI CHARACTER (BOTTOM RIGHT)
          if (_poseService.rawPose != null && _imageSize != null)
            Positioned(
              bottom: 160,
              right: 20,
              child: GlassContainer(
                blur: 30,
                padding: const EdgeInsets.all(10),
                borderRadius: 15,
                child: SizedBox(
                  width: 100,
                  height: 140,
                  child: CustomPaint(
                    painter: MiniCharacterPainter(
                      _imageSize!,
                      _poseService.rawPose!,
                      _cameraDirection,
                    ),
                  ),
                ),
              ),
            ),

          // 3. DARK GRADIENT & TEXT OVERLAY
          Positioned.fill(
              child: Container(
                  decoration: BoxDecoration(
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                            Colors.black.withOpacity(0.9)
                          ],
                          stops: const [0.0, 0.6, 1.0]
                      )
                  )
              )
          ),

          // 4. MAIN STATS
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Column(
              children: [
                if (!isVisible)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    color: Colors.red.withOpacity(0.8),
                    child: const Text(
                        "FULL BODY NOT VISIBLE!",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)
                    ),
                  ),

                const SizedBox(height: 10),

                Text(
                  _feedback.toUpperCase(),
                  style: TextStyle(
                      fontSize: 24,
                      color: isVisible ? AppTheme.mySystemBlue : AppTheme.mySystemRed,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0
                  ),
                  textAlign: TextAlign.center,
                ),

                Text(
                  'REPS: $_reps / $_targetReps',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [Shadow(blurRadius: 10, color: AppTheme.mySystemBlue)],
                    fontFamily: 'Roboto',
                  ),
                ),
              ],
            ),
          ),

          // 5. CLOSE BUTTON
          Positioned(
            top: 40,
            left: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context, false),
              ),
            ),
          ),

          // 6. FLIP CAMERA BUTTON
          Positioned(
            top: 40,
            right: 20,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                onPressed: _toggleCamera,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---- CUSTOM PAINTER (MINI CHARACTER) ----
class MiniCharacterPainter extends CustomPainter {
  final Size imageSize;
  final Pose pose;
  final CameraLensDirection cameraDirection;

  MiniCharacterPainter(this.imageSize, this.pose, this.cameraDirection);

  @override
  void paint(Canvas canvas, Size size) {
    if (pose.landmarks.isEmpty) return;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..color = AppTheme.mySystemBlue;

    final jointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.white;

    // For portrait Android, image width/height are swapped compared to sensor.
    final double imageW = imageSize.height;

    // Translate a raw landmark into a normalized base coordinate space first.
    Offset getBasePoint(PoseLandmark landmark) {
      if (cameraDirection == CameraLensDirection.front) {
         return Offset(landmark.x, landmark.y);
      } else {
         return Offset(imageW - landmark.x, landmark.y);
      }
    }

    // Now find bounding box in the base coordinate space
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;
    bool hasValid = false;

    // Filter out face nodes (index < 11)
    final validPoints = <PoseLandmarkType, Offset>{};
    for (final entry in pose.landmarks.entries) {
      final landmark = entry.value;
      if (landmark.type.index > 10 && landmark.likelihood > 0.5) {
        final pt = getBasePoint(landmark);
        validPoints[entry.key] = pt;
        if (pt.dx < minX) minX = pt.dx;
        if (pt.dy < minY) minY = pt.dy;
        if (pt.dx > maxX) maxX = pt.dx;
        if (pt.dy > maxY) maxY = pt.dy;
        hasValid = true;
      }
    }

    // Include head calculation in bounding box
    final leftS = pose.landmarks[PoseLandmarkType.leftShoulder];
    final rightS = pose.landmarks[PoseLandmarkType.rightShoulder];
    Offset? headBasePoint;
    if (leftS != null && rightS != null && leftS.likelihood > 0.5 && rightS.likelihood > 0.5) {
       final ptL = getBasePoint(leftS);
       final ptR = getBasePoint(rightS);
       final midX = (ptL.dx + ptR.dx) / 2;
       final midY = (ptL.dy + ptR.dy) / 2;
       final headLength = (ptL.dx - ptR.dx).abs() * 0.8;
       headBasePoint = Offset(midX, midY - headLength - 10);
       
       if (headBasePoint.dx < minX) minX = headBasePoint.dx;
       if (headBasePoint.dy < minY) minY = headBasePoint.dy;
       if (headBasePoint.dx > maxX) maxX = headBasePoint.dx;
       if (headBasePoint.dy > maxY) maxY = headBasePoint.dy;
       hasValid = true;
    }

    if (!hasValid) return;

    final boxW = maxX - minX;
    final boxH = maxY - minY;
    if (boxW <= 0 || boxH <= 0) return;

    final padding = 16.0;
    final scaleX = (size.width - padding) / boxW;
    final scaleY = (size.height - padding) / boxH;
    final scale = scaleX < scaleY ? scaleX : scaleY;

    final offsetX = (size.width - boxW * scale) / 2 - minX * scale;
    final offsetY = (size.height - boxH * scale) / 2 - minY * scale;

    Offset translate(Offset basePt) {
      return Offset(basePt.dx * scale + offsetX, basePt.dy * scale + offsetY);
    }

    final connections = [
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
      [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
      [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
      [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
    ];

    for (final connection in connections) {
      final p1 = validPoints[connection[0]];
      final p2 = validPoints[connection[1]];
      if (p1 != null && p2 != null) {
         canvas.drawLine(translate(p1), translate(p2), paint);
      }
    }

    if (headBasePoint != null) {
       canvas.drawCircle(translate(headBasePoint), 8 * scale.clamp(0.5, 2.0), paint);
    }

    for (final pt in validPoints.values) {
       canvas.drawCircle(translate(pt), 3 * scale.clamp(0.5, 2.0), jointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MiniCharacterPainter oldDelegate) {
    return oldDelegate.pose != pose;
  }
}