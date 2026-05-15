import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/models/daily_log_model.dart';
import '../../../shared/models/meal_model.dart';
import '../../../shared/models/weekly_quest_log_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/health_service.dart';

/// Today's daily log stream
final todayLogProvider = StreamProvider<DailyLogModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();
  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return FirestoreService.instance.dailyLogStream(user.uid, today);
});

/// Daily score derived from today's log + user goals
final dailyScoreProvider = Provider<int>((ref) {
  final log = ref.watch(todayLogProvider).valueOrNull;
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (log == null || user == null) return 0;

  final stepGoal = user.dailyGoals.steps;
  final waterGoal = user.dailyGoals.waterGlasses;

  final stepsScore = (log.stepCount / stepGoal * 40).clamp(0, 40).toInt();
  final mealsScore = (log.mealsLogged * 20).clamp(0, 20);
  final waterScore = (log.waterGlasses / waterGoal * 20).clamp(0, 20).toInt();
  final streakBonus = user.streakDays > 0 ? 20 : 0;

  return (stepsScore + mealsScore + waterScore + streakBonus).clamp(0, 100);
});

/// Real-time step count from pedometer
final stepStreamProvider = StreamProvider<int>((ref) {
  return HealthService.instance.stepStream;
});

/// Weekly logs for chart (last 7 days)
final weeklyLogsProvider = FutureProvider<List<DailyLogModel>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return [];
  return FirestoreService.instance.getWeeklyLogs(user.uid);
});

/// Logs for the current ISO week, used by weekly quests.
final currentWeekLogsProvider = FutureProvider<List<DailyLogModel>>((
  ref,
) async {
  ref.watch(todayLogProvider);
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return [];
  return FirestoreService.instance.getCurrentWeekLogs(user.uid);
});

/// Current ISO week's quest reward state.
final weeklyQuestLogProvider = StreamProvider<WeeklyQuestLogModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();
  return FirestoreService.instance.weeklyQuestLogStream(
    user.uid,
    AppDateUtils.weekKey(),
  );
});

/// Today's meals stream for macro tracking
final todayMealsProvider = StreamProvider<List<MealModel>>((ref) {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return const Stream.empty();
  return FirestoreService.instance.todayMealsStream(user.uid);
});
