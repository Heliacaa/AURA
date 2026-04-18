import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

class HealthService {
  HealthService._();
  static final instance = HealthService._();

  StreamSubscription<StepCount>? _stepSubscription;
  final _stepController = StreamController<int>.broadcast();

  int _todaySteps = 0;
  int get todaySteps => _todaySteps;

  Stream<int> get stepStream => _stepController.stream;

  Future<bool> requestPermissions() async {
    final status = await Permission.activityRecognition.request();
    return status.isGranted;
  }

  void startListening() {
    _stepSubscription?.cancel();
    _stepSubscription =
        Pedometer.stepCountStream.listen(_onStepCount, onError: _onStepError);
  }

  void _onStepCount(StepCount event) {
    _todaySteps = event.steps;
    _stepController.add(_todaySteps);
  }

  void _onStepError(dynamic error) {
    debugPrint('Pedometer error: $error');
  }

  void stopListening() {
    _stepSubscription?.cancel();
    _stepSubscription = null;
  }

  /// Get sleep data from manual input (hours, quality)
  /// In production, integrate with HealthKit / Health Connect via `health` package
  Future<Map<String, dynamic>?> getSleepData() async {
    // Placeholder: returns null, meaning manual input is needed
    // To integrate real sleep data, use the `health` package:
    // final types = [HealthDataType.SLEEP_IN_BED];
    // final permissions = [HealthDataAccess.READ];
    // bool authorized = await Health().requestAuthorization(types, permissions: permissions);
    return null;
  }

  void dispose() {
    _stepSubscription?.cancel();
    _stepController.close();
  }
}
