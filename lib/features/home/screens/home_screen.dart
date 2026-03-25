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

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    // Ensure today's log and update streak on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDay();
    });
  }

  Future<void> _initializeDay() async {
    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null) return;
    await FirestoreService.instance.ensureTodayLog(authUser.uid);
    await FirestoreService.instance.updateStreak(authUser.uid);
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final logAsync = ref.watch(todayLogProvider);
    final dailyScore = ref.watch(dailyScoreProvider);

    return SafeArea(
      child: RefreshIndicator(
        color: AppTheme.primaryAccent,
        backgroundColor: AppTheme.cardBackground,
        onRefresh: _initializeDay,
        child: userAsync.when(
          loading: () => _buildShimmer(),
          error: (e, _) => Center(
            child: Text('Hata: $e',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          data: (user) {
            if (user == null) return const SizedBox.shrink();

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
                                  progress:
                                      progress * _progressAnimation.value,
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

                  // Step card
                  AuraCard(
                    emoji: '👟',
                    title: '${log?.stepCount ?? 0} Adım',
                    subtitle: _stepSubtitle(
                        log?.stepCount ?? 0, user.dailyGoals.steps),
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
                    subtitle: (log?.waterGlasses ?? 0) >=
                            user.dailyGoals.waterGlasses
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

  Future<void> _showStepDialog(BuildContext context, int currentSteps) async {
    final controller = TextEditingController();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.cardBackground,
        title: Text('Adım Güncelle',
            style: GoogleFonts.poppins(color: AppTheme.textWhite)),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: GoogleFonts.poppins(color: AppTheme.textWhite),
          decoration: AppTheme.inputDecoration(hintText: 'Adım sayısı'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('İptal',
                style: GoogleFonts.poppins(color: AppTheme.textSecondary)),
          ),
          TextButton(
            onPressed: () {
              final val = int.tryParse(controller.text);
              if (val != null) Navigator.pop(ctx, val);
            },
            child: Text('Kaydet',
                style: GoogleFonts.poppins(color: AppTheme.primaryAccent)),
          ),
        ],
      ),
    );

    if (result != null) {
      final uid = ref.read(authStateProvider).valueOrNull?.uid;
      if (uid == null) return;
      final today = AppDateUtils.todayKey();
      await FirestoreService.instance.updateDailyLog(
        uid,
        today,
        {'stepCount': result},
      );

      // Check if step goal reached
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null && result >= user.dailyGoals.steps) {
        await FirestoreService.instance.updateUserXP(
          uid: uid,
          xpDelta: 50,
          statDeltas: {'strength': 5},
          taskDescription: '+5 Güç (Adım hedefine ulaşıldı)',
        );
      }
    }
  }

  Future<void> _incrementWater(BuildContext context, int current) async {
    final uid = ref.read(authStateProvider).valueOrNull?.uid;
    if (uid == null) return;
    final today = AppDateUtils.todayKey();
    await FirestoreService.instance.updateDailyLog(
      uid,
      today,
      {'waterGlasses': current + 1},
    );

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
