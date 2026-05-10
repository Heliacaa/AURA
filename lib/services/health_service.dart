import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:pedometer/pedometer.dart';
import 'package:permission_handler/permission_handler.dart';

import '../core/utils/date_utils.dart';
import 'firestore_service.dart';

@immutable
class HealthInterval {
  const HealthInterval(this.start, this.end);

  final DateTime start;
  final DateTime end;
}

class HealthService {
  HealthService._();
  static final instance = HealthService._();

  static const _healthReadTypes = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
    HealthDataType.SLEEP_IN_BED,
  ];

  static const _asleepTypes = {
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_REM,
  };

  final Health _health = Health();
  StreamSubscription<StepCount>? _stepSubscription;
  final _stepController = StreamController<int>.broadcast();

  int _todaySteps = 0;
  int _liveSeedDailySteps = 0;
  int? _pedometerBaselineSteps;
  bool _healthConfigured = false;
  int get todaySteps => _todaySteps;

  Stream<int> get stepStream => _stepController.stream;

  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _requestHealthReadAuthorization();
      final status = await Permission.sensors.request();
      return status.isGranted;
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.activityRecognition.request();
      return status.isGranted;
    }

    return false;
  }

  void startListening() => startLiveStepTracking(seedDailySteps: _todaySteps);

  void startLiveStepTracking({required int seedDailySteps}) {
    _stepSubscription?.cancel();
    _liveSeedDailySteps = seedDailySteps.clamp(0, 1 << 31).toInt();
    _todaySteps = _liveSeedDailySteps;
    _pedometerBaselineSteps = null;
    _stepController.add(_todaySteps);
    _stepSubscription = Pedometer.stepCountStream.listen(
      _onStepCount,
      onError: _onStepError,
    );
  }

  void _onStepCount(StepCount event) {
    final baseline = _pedometerBaselineSteps ?? event.steps;
    _pedometerBaselineSteps = baseline;
    _todaySteps = normalizeLiveSteps(
      seedDailySteps: _liveSeedDailySteps,
      baselineBootSteps: baseline,
      currentBootSteps: event.steps,
    );
    _stepController.add(_todaySteps);
  }

  void _onStepError(dynamic error) {
    debugPrint('Pedometer error: $error');
  }

  void stopListening() {
    _stepSubscription?.cancel();
    _stepSubscription = null;
  }

  Future<int?> fetchTodaySteps({bool includeManualEntry = false}) async {
    if (!_supportsAppleHealth) return null;
    final authorized = await _requestHealthReadAuthorization();
    if (!authorized) return null;

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);

    try {
      final steps = await _health.getTotalStepsInInterval(
        start,
        now,
        includeManualEntry: includeManualEntry,
      );
      if (steps != null) {
        _todaySteps = steps;
      }
      return steps;
    } catch (e) {
      debugPrint('HealthKit step fetch error: $e');
      return null;
    }
  }

  Future<double?> fetchLastNightSleepHours(DateTime date) async {
    if (!_supportsAppleHealth) return null;
    final authorized = await _requestHealthReadAuthorization();
    if (!authorized) return null;

    final start = DateTime(
      date.year,
      date.month,
      date.day,
    ).subtract(const Duration(hours: 6));
    final end = DateTime(date.year, date.month, date.day, 12);

    try {
      final points = await _health.getHealthDataFromTypes(
        types: _healthReadTypes
            .where((type) => type != HealthDataType.STEPS)
            .toList(),
        startTime: start,
        endTime: end,
      );

      final asleepIntervals = <HealthInterval>[];
      final inBedIntervals = <HealthInterval>[];

      for (final point in points) {
        final interval = _clippedInterval(point, start, end);
        if (interval == null) continue;

        if (_asleepTypes.contains(point.type)) {
          asleepIntervals.add(interval);
        } else if (point.type == HealthDataType.SLEEP_IN_BED) {
          inBedIntervals.add(interval);
        }
      }

      return sleepHoursFromIntervals(
        asleepIntervals: asleepIntervals,
        inBedIntervals: inBedIntervals,
      );
    } catch (e) {
      debugPrint('HealthKit sleep fetch error: $e');
      return null;
    }
  }

  Future<void> syncTodayHealthLog(String uid) async {
    if (!_supportsAppleHealth) return;

    final updates = <String, dynamic>{};
    final steps = await fetchTodaySteps(includeManualEntry: false);
    if (steps != null && steps > 0) {
      updates['stepCount'] = steps;
    }

    final sleepHours = await fetchLastNightSleepHours(DateTime.now());
    if (sleepHours != null && sleepHours > 0) {
      updates['sleepHours'] = sleepHours;
    }

    if (updates.isEmpty) return;

    try {
      await FirestoreService.instance.updateDailyLog(
        uid,
        AppDateUtils.todayKey(),
        updates,
      );
    } catch (e) {
      debugPrint('HealthKit daily log sync error: $e');
    }
  }

  Future<Map<String, dynamic>?> getSleepData() async {
    final hours = await fetchLastNightSleepHours(DateTime.now());
    if (hours == null || hours <= 0) return null;
    return {'hours': hours};
  }

  bool get _supportsAppleHealth =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<bool> _requestHealthReadAuthorization() async {
    if (!_supportsAppleHealth) return false;

    try {
      if (!_healthConfigured) {
        await _health.configure();
        _healthConfigured = true;
      }

      return _health.requestAuthorization(
        _healthReadTypes,
        permissions: List.filled(
          _healthReadTypes.length,
          HealthDataAccess.READ,
        ),
      );
    } catch (e) {
      debugPrint('HealthKit authorization error: $e');
      return false;
    }
  }

  static HealthInterval? _clippedInterval(
    HealthDataPoint point,
    DateTime windowStart,
    DateTime windowEnd,
  ) {
    final start = point.dateFrom.isBefore(windowStart)
        ? windowStart
        : point.dateFrom;
    final end = point.dateTo.isAfter(windowEnd) ? windowEnd : point.dateTo;
    if (!end.isAfter(start)) return null;
    return HealthInterval(start, end);
  }

  @visibleForTesting
  static int normalizeLiveSteps({
    required int seedDailySteps,
    required int baselineBootSteps,
    required int currentBootSteps,
  }) {
    final delta = currentBootSteps - baselineBootSteps;
    return seedDailySteps + (delta > 0 ? delta : 0);
  }

  @visibleForTesting
  static double? sleepHoursFromIntervals({
    required Iterable<HealthInterval> asleepIntervals,
    required Iterable<HealthInterval> inBedIntervals,
  }) {
    final asleepDuration = sumNonOverlappingIntervals(asleepIntervals);
    final duration = asleepDuration > Duration.zero
        ? asleepDuration
        : sumNonOverlappingIntervals(inBedIntervals);

    if (duration <= Duration.zero) return null;
    return duration.inMinutes / 60.0;
  }

  @visibleForTesting
  static Duration sumNonOverlappingIntervals(
    Iterable<HealthInterval> intervals,
  ) {
    final sorted =
        intervals
            .where((interval) => interval.end.isAfter(interval.start))
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));

    if (sorted.isEmpty) return Duration.zero;

    var mergedStart = sorted.first.start;
    var mergedEnd = sorted.first.end;
    var total = Duration.zero;

    for (final interval in sorted.skip(1)) {
      if (!interval.start.isAfter(mergedEnd)) {
        if (interval.end.isAfter(mergedEnd)) {
          mergedEnd = interval.end;
        }
        continue;
      }

      total += mergedEnd.difference(mergedStart);
      mergedStart = interval.start;
      mergedEnd = interval.end;
    }

    return total + mergedEnd.difference(mergedStart);
  }

  void dispose() {
    _stepSubscription?.cancel();
    _stepController.close();
  }
}
