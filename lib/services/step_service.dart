import 'dart:async';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class StepService {
  StreamSubscription<StepCount>? _stepCountSubscription;
  int _initialSteps = -1;
  int _currentSteps = 0;
  
  final _stepsController = StreamController<int>.broadcast();
  Stream<int> get stepsStream => _stepsController.stream;

  Future<bool> requestPermission() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  void startTracking() {
    _initialSteps = -1;
    _currentSteps = 0;
    _stepCountSubscription = Pedometer.stepCountStream.listen(
      _onData,
      onError: _onError,
      cancelOnError: true,
    );
  }

  void _onData(StepCount event) {
    if (_initialSteps == -1) {
      _initialSteps = event.steps;
    }
    _currentSteps = event.steps - _initialSteps;
    _stepsController.add(_currentSteps);
  }

  void _onError(error) {
    print('Pedometer error: $error');
  }

  void stopTracking() {
    _stepCountSubscription?.cancel();
    _stepCountSubscription = null;
  }

  int get currentSteps => _currentSteps;

  void dispose() {
    stopTracking();
    _stepsController.close();
  }
}
