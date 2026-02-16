import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'dart:io';
import '../models/exercise_type.dart';
import '../services/pose_detection_service.dart';
import '../services/usage_service.dart';
import '../theme/wakanda_theme.dart';
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
  String _status = "Prepare";
  String _feedback = "";

  // For Painting
  Size? _imageSize;
  InputImageRotation _rotation = InputImageRotation.rotation270deg;

  @override
  void initState() {
    super.initState();
    _poseService.setExerciseType(widget.exerciseType);
    _initializeCamera();

    // Show Instructions Dialog after build
    WidgetsBinding.instance.addPostFrameCallback((_) => _showInstructions());
  }

  void _showInstructions() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: WakandaTheme.blackMetal,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: const BorderSide(color: WakandaTheme.herbPurple)),
        title: Row(
          children: [
            const Icon(Icons.info_outline, color: WakandaTheme.herbPurple),
            const SizedBox(width: 10),
            Text("${widget.exerciseType.name.toUpperCase()} SETUP", style: const TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _instructionStep("1. Place phone on the floor, leaning against a wall."),
            const SizedBox(height: 10),
            _instructionStep("2. Ensure the front camera faces you."),
            const SizedBox(height: 10),
            _instructionStep("3. Step back until your WHOLE body is visible (Head to Toe)."),
            const SizedBox(height: 10),
            _instructionStep("4. Wait for the skeleton lines to appear."),
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

  Widget _instructionStep(String text) {
    return Text(text, style: const TextStyle(color: WakandaTheme.vibranium, fontSize: 14));
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final frontCamera = cameras.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _controller = CameraController(
      frontCamera,
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

        if (_reps >= 10) {
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

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: WakandaTheme.blackMetal,
        title: const Text("UNLOCKED!", style: TextStyle(color: WakandaTheme.herbLight, fontWeight: FontWeight.bold)),
        content: const Text("Protocol complete. Access granted for 15 minutes.", style: TextStyle(color: Colors.white)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            child: const Text("OPEN APP", style: TextStyle(color: WakandaTheme.vibranium)),
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

          // 2. SKELETON PAINTER
          if (_poseService.rawPose != null && _imageSize != null)
            SizedBox(
              width: size.width,
              height: size.height,
              child: CustomPaint(
                painter: PosePainter(
                  _imageSize!,
                  _poseService.rawPose!,
                  _rotation,
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
                            WakandaTheme.blackMetal.withOpacity(0.9)
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
                      color: isVisible ? WakandaTheme.herbLight : Colors.red,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.0
                  ),
                  textAlign: TextAlign.center,
                ),

                Text(
                  'REPS: $_reps / 10',
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: WakandaTheme.vibranium,
                    shadows: [Shadow(blurRadius: 10, color: WakandaTheme.herbPurple)],
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
        ],
      ),
    );
  }
}

// ---- CUSTOM PAINTER (NO HEAD, ONLY BODY) ----
class PosePainter extends CustomPainter {
  final Size imageSize;
  final Pose pose;
  final InputImageRotation rotation;

  PosePainter(this.imageSize, this.pose, this.rotation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = WakandaTheme.herbPurple;

    final jointPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = WakandaTheme.vibranium;

    // Connections (EXCLUDING HEAD/FACE)
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
      final start = pose.landmarks[connection[0]]!;
      final end = pose.landmarks[connection[1]]!;

      // Draw line only if both points are likely visible
      if (start.likelihood > 0.5 && end.likelihood > 0.5) {
        canvas.drawLine(
            _translatePoint(start.x, start.y, size),
            _translatePoint(end.x, end.y, size),
            paint
        );
      }
    }

    // Draw Joints (Filter out index 0-10 which are face landmarks)
    for (final landmark in pose.landmarks.values) {
      if (landmark.type.index > 10 && landmark.likelihood > 0.5) {
        final point = _translatePoint(landmark.x, landmark.y, size);
        canvas.drawCircle(point, 5, jointPaint);
      }
    }
  }

  Offset _translatePoint(double x, double y, Size screenSize) {
    // Android Front Camera is usually Rotated 270deg.
    // So Width -> Height, Height -> Width
    final double imageW = imageSize.height;
    final double imageH = imageSize.width;

    final double scaleX = screenSize.width / imageW;
    final double scaleY = screenSize.height / imageH;

    // Map Coordinates
    final double screenX = x * scaleX;
    final double screenY = y * scaleY;

    // Mirror for selfie view
    return Offset(screenSize.width - screenX, screenY);
  }

  @override
  bool shouldRepaint(covariant PosePainter oldDelegate) {
    return oldDelegate.pose != pose || oldDelegate.imageSize != imageSize;
  }
}