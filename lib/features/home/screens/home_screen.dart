import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/aura_card.dart';
import '../../../shared/widgets/circular_progress_painter.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/home_provider.dart';
import '../../../services/firestore_service.dart';
import '../../../services/health_service.dart';
import '../widgets/weekly_chart.dart';
import '../widgets/macro_summary_card.dart';
import '../widgets/sleep_card.dart';
import '../widgets/daily_quests_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;
  StreamSubscription<int>? _stepSyncSubscription;
  DateTime? _lastStepWriteAt;
  int? _lastWrittenSteps;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    // Ensure today's log and update streak on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initializeDay();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (mounted) _initializeDay();
    }
  }

  Future<void> _initializeDay() async {
    if (!mounted) return;
    try {
      final authUser = ref.read(authStateProvider).valueOrNull;
      if (authUser == null) return;

      // Ensure user document exists in Firestore
      await FirestoreService.instance.ensureUserDoc(
        uid: authUser.uid,
        displayName: authUser.displayName ?? '',
        email: authUser.email ?? '',
      );
      if (!mounted) return;

      await FirestoreService.instance.ensureTodayLog(authUser.uid);
      if (!mounted) return;
      await FirestoreService.instance.updateStreak(authUser.uid);
      if (!mounted) return;
      await HealthService.instance.syncTodayHealthLog(authUser.uid);
      if (!mounted) return;

      final motionGranted = await HealthService.instance.requestPermissions();
      if (motionGranted && mounted) {
        final syncedSteps = HealthService.instance.todaySteps;
        final logSteps = ref.read(todayLogProvider).valueOrNull?.stepCount ?? 0;
        HealthService.instance.startLiveStepTracking(
          seedDailySteps: syncedSteps > 0 ? syncedSteps : logSteps,
        );
        _startStepSync(authUser.uid);
      }
    } catch (e) {
      debugPrint('HomeScreen _initializeDay error: $e');
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stepSyncSubscription?.cancel();
    HealthService.instance.stopListening();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final logAsync = ref.watch(todayLogProvider);
    final dailyScore = ref.watch(dailyScoreProvider);
    final weeklyLogs = ref.watch(weeklyLogsProvider);
    final todayMeals = ref.watch(todayMealsProvider);

    return SafeArea(
      child: RefreshIndicator(
        color: AppTheme.primaryAccent,
        backgroundColor: AppTheme.cardBackground,
        onRefresh: _initializeDay,
        child: userAsync.when(
          loading: () => _buildShimmer(),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.cloud_off,
                    color: AppTheme.textSecondary,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Sunucuya bağlanılamadı',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Firebase Firestore veritabanının oluşturulduğundan emin olun.',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          data: (user) {
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            final log = logAsync.valueOrNull;
            final score = dailyScore;
            final progress = score / 100.0;

            // Trigger animation when score updates
            _progressController.forward(from: 0);

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  Text(
                    '${AppDateUtils.greeting()},',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  Text(
                    '${user.displayName}! 👋',
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryAccent,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Circular progress
                  Center(
                    child: AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return SizedBox(
                          width: 180,
                          height: 180,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CustomPaint(
                                size: const Size(180, 180),
                                painter: CircularProgressPainter(
                                  progress: progress * _progressAnimation.value,
                                  progressColor: AppTheme.primaryAccent,
                                  strokeWidth: 14,
                                ),
                              ),
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${(score * _progressAnimation.value).toInt()}%',
                                    style: GoogleFonts.poppins(
                                      fontSize: 40,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textWhite,
                                    ),
                                  ),
                                  Text(
                                    'Günlük Skor',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 32),

                  DailyQuestsCard(
                    uid: user.uid,
                    log: log,
                    goals: user.dailyGoals,
                  ),
                  const SizedBox(height: 24),

                  // Weekly trends chart
                  Text(
                    'Weekly Trends',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  weeklyLogs.when(
                    loading: () => const SizedBox(height: 180),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (logs) => WeeklyChart(logs: logs),
                  ),
                  const SizedBox(height: 16),

                  // Macro summary card
                  todayMeals.when(
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                    data: (meals) => meals.isNotEmpty
                        ? MacroSummaryCard(
                            meals: meals,
                            calorieGoal: user.dailyGoals.calories,
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 12),

                  // Sleep card
                  SleepCard(
                    sleepHours: log?.sleepHours ?? 0,
                    sleepQuality: log?.sleepQuality ?? '',
                    onTap: () => _showSleepDialog(context),
                  ),

                  // Step card
                  AuraCard(
                    emoji: '👟',
                    title: '${log?.stepCount ?? 0} Adım',
                    subtitle: _stepSubtitle(
                      log?.stepCount ?? 0,
                      user.dailyGoals.steps,
                    ),
                    borderColor: AppTheme.primaryAccent,
                    onTap: () => _showStepDialog(context, log?.stepCount ?? 0),
                  ),

                  // Social energy card
                  AuraCard(
                    emoji: '🔋',
                    title: 'Sosyal Enerji: ${user.socialEnergyLevel}',
                    subtitle: _energySubtitle(user.socialEnergyLevel),
                    borderColor: AppTheme.warningOrange,
                  ),

                  // Streak card
                  AuraCard(
                    emoji: '🔥',
                    title: '${user.streakDays} Günlük Seri',
                    borderColor: AppTheme.primaryAccent,
                  ),

                  // Water tracking card
                  AuraCard(
                    emoji: '💧',
                    title:
                        '${log?.waterGlasses ?? 0} / ${user.dailyGoals.waterGlasses} Bardak Su',
                    subtitle:
                        (log?.waterGlasses ?? 0) >= user.dailyGoals.waterGlasses
                        ? 'Hedefe ulaştın! 🎉'
                        : 'Daha fazla su iç!',
                    borderColor: AppTheme.secondaryAccent,
                    onTap: () =>
                        _incrementWater(context, log?.waterGlasses ?? 0),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  String _stepSubtitle(int steps, int goal) {
    if (steps >= goal) return 'Hedefe ulaştın! 🎉';
    if (steps >= goal * 0.8) return 'Hedefe az kaldı!';
    if (steps >= goal * 0.5) return 'İyi gidiyorsun!';
    return 'Haydi harekete geç! 💪';
  }

  String _energySubtitle(String level) {
    switch (level) {
      case 'Yüksek':
        return 'Enerjin harika! Sosyalleş!';
      case 'Orta':
        return 'Dengeli bir gün.';
      case 'Düşük':
        return 'Biraz dinlenmelisin.';
      default:
        return '';
    }
  }

  void _startStepSync(String uid) {
    _stepSyncSubscription?.cancel();
    _lastStepWriteAt = null;
    _lastWrittenSteps = null;
    _stepSyncSubscription = HealthService.instance.stepStream.listen(
      (steps) => _persistLiveSteps(uid, steps),
      onError: (error) => debugPrint('Step sync stream error: $error'),
    );
  }

  Future<void> _persistLiveSteps(String uid, int steps) async {
    if (steps <= 0) return;

    final now = DateTime.now();
    final previous = _lastWrittenSteps;
    if (previous != null && steps <= previous) return;

    final hasMeaningfulDelta = previous == null || steps - previous >= 25;
    final hasWaited =
        _lastStepWriteAt == null ||
        now.difference(_lastStepWriteAt!) >= const Duration(minutes: 1);

    if (!hasMeaningfulDelta && !hasWaited) return;

    _lastWrittenSteps = steps;
    _lastStepWriteAt = now;

    try {
      await FirestoreService.instance.updateDailyLog(
        uid,
        AppDateUtils.todayKey(),
        {'stepCount': steps},
      );
    } catch (e) {
      debugPrint('Live step Firestore sync error: $e');
    }
  }

  Future<void> _showStepDialog(BuildContext context, int currentSteps) async {
    final controller = TextEditingController(
      text: currentSteps > 0 ? '$currentSteps' : '',
    );
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text(
          'Adım Güncelle',
          style: GoogleFonts.poppins(color: AppTheme.textWhite),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.poppins(color: AppTheme.textWhite),
          decoration: AppTheme.inputDecoration(hintText: 'Adım sayısı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'İptal',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null) Navigator.pop(ctx, val);
            },
            child: Text(
              'Kaydet',
              style: GoogleFonts.poppins(color: AppTheme.primaryAccent),
            ),
          ),
        ],
      ),
    );

    if (result != null) {
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid == null) return;
      final today = AppDateUtils.todayKey();
      await FirestoreService.instance.updateDailyLog(uid, today, {
        'stepCount': result,
      });
    }
  }

  Future<void> _incrementWater(BuildContext context, int current) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    final today = AppDateUtils.todayKey();
    await FirestoreService.instance.updateDailyLog(uid, today, {
      'waterGlasses': current + 1,
    });

    final user = ref.read(currentUserProvider).valueOrNull;
    if (user != null && current + 1 >= user.dailyGoals.waterGlasses) {
      await FirestoreService.instance.updateUserXP(
        uid: uid,
        xpDelta: 15,
        statDeltas: {'vitality': 2},
        taskDescription: '+2 Vitalite (Su hedefine ulaşıldı)',
      );
    }
  }

  Future<void> _showSleepDialog(BuildContext context) async {
    final hoursController = TextEditingController();
    String selectedQuality = 'good';

    final currentSleepHours =
        ref.read(todayLogProvider).valueOrNull?.sleepHours ?? 0;
    if (currentSleepHours > 0) {
      hoursController.text = currentSleepHours.toStringAsFixed(1);
    } else {
      try {
        final syncedHours = await HealthService.instance
            .fetchLastNightSleepHours(DateTime.now());
        if (!mounted) return;
        if (syncedHours != null && syncedHours > 0) {
          hoursController.text = syncedHours.toStringAsFixed(1);
        }
      } catch (e) {
        debugPrint('Sleep prefill error: $e');
      }
    }

    if (!context.mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          title: Text(
            'Log Sleep',
            style: GoogleFonts.poppins(color: AppTheme.textWhite),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hoursController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                style: GoogleFonts.poppins(color: AppTheme.textWhite),
                decoration: AppTheme.inputDecoration(
                  hintText: 'Hours slept (e.g. 7.5)',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: ['good', 'fair', 'poor'].map((q) {
                  final isSelected = selectedQuality == q;
                  return GestureDetector(
                    onTap: () => setDialogState(() => selectedQuality = q),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.statBlue
                            : AppTheme.background,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        q[0].toUpperCase() + q.substring(1),
                        style: GoogleFonts.poppins(
                          color: isSelected
                              ? Colors.white
                              : AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'Cancel',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: () {
                final hours = double.tryParse(hoursController.text);
                if (hours != null && hours > 0) {
                  Navigator.pop(ctx, {
                    'hours': hours,
                    'quality': selectedQuality,
                  });
                }
              },
              child: Text(
                'Save',
                style: GoogleFonts.poppins(color: AppTheme.primaryAccent),
              ),
            ),
          ],
        ),
      ),
    );

    if (result != null) {
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid == null) return;
      final today = AppDateUtils.todayKey();
      await FirestoreService.instance.updateSleepData(
        uid,
        today,
        result['hours'] as double,
        result['quality'] as String,
      );
    }
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppTheme.cardBackground,
      highlightColor: const Color(0xFF2A2A2A),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 16,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 200,
              height: 28,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 32),
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 32),
            ...List.generate(
              3,
              (_) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
