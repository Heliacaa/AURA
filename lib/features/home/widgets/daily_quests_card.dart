import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/models/daily_log_model.dart';
import '../../../shared/models/user_model.dart';
import '../models/daily_quest.dart';
import '../providers/home_provider.dart';

class DailyQuestsCard extends ConsumerStatefulWidget {
  final String uid;
  final DailyLogModel? log;
  final DailyGoals goals;

  const DailyQuestsCard({
    super.key,
    required this.uid,
    required this.log,
    required this.goals,
  });

  @override
  ConsumerState<DailyQuestsCard> createState() => _DailyQuestsCardState();
}

class _DailyQuestsCardState extends ConsumerState<DailyQuestsCard> {
  QuestCadence _selectedCadence = QuestCadence.daily;
  String? _claimingQuestId;

  @override
  Widget build(BuildContext context) {
    final dailyRotation = DailyQuestCatalog.forDate(DateTime.now());
    final dailyQuests = [...dailyRotation, DailyQuestCatalog.combo];
    final dailyClaimedCount = widget.log == null
        ? 0
        : dailyQuests
              .where((quest) => widget.log!.claimedQuestIds.contains(quest.id))
              .length;
    final subtitle = _selectedCadence == QuestCadence.daily
        ? 'Bugün $dailyClaimedCount / ${dailyQuests.length} ödül alındı'
        : 'Haftalık görev ödüllerini takip et';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(
        borderColor: AppTheme.secondaryAccent,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Görev Panosu',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              _QuestTab(
                label: 'Günlük',
                selected: _selectedCadence == QuestCadence.daily,
                onTap: () =>
                    setState(() => _selectedCadence = QuestCadence.daily),
              ),
              const SizedBox(width: 8),
              _QuestTab(
                label: 'Haftalık',
                selected: _selectedCadence == QuestCadence.weekly,
                onTap: () =>
                    setState(() => _selectedCadence = QuestCadence.weekly),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_selectedCadence == QuestCadence.daily)
            _buildDailyQuests(dailyRotation, dailyQuests)
          else
            _buildWeeklyQuests(),
        ],
      ),
    );
  }

  Widget _buildDailyQuests(
    List<QuestDefinition> dailyRotation,
    List<QuestDefinition> dailyQuests,
  ) {
    final claimedQuestIds = widget.log?.claimedQuestIds ?? const <String>[];

    return Column(
      children: dailyQuests.map((quest) {
        final progress = QuestEvaluator.progressFor(
          quest: quest,
          todayLog: widget.log,
          goals: widget.goals,
          claimedQuestIds: claimedQuestIds,
          dailyRotation: dailyRotation,
        );
        final status = QuestEvaluator.statusFor(
          quest: quest,
          progress: progress,
          claimedQuestIds: claimedQuestIds,
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _QuestRow(
            quest: quest,
            progress: progress,
            status: status,
            isClaiming: _claimingQuestId == quest.id,
            onClaim: status == QuestStatus.ready && _claimingQuestId == null
                ? () => _claimQuest(quest)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildWeeklyQuests() {
    final weekLogsAsync = ref.watch(currentWeekLogsProvider);
    final weeklyLogAsync = ref.watch(weeklyQuestLogProvider);
    final claimedQuestIds =
        weeklyLogAsync.valueOrNull?.claimedQuestIds ?? const <String>[];
    final fallbackLogs = [if (widget.log != null) widget.log!];

    return weekLogsAsync.when(
      loading: () => const _QuestLoading(),
      error: (_, _) => _WeeklyQuestList(
        weekLogs: fallbackLogs,
        todayLog: widget.log,
        goals: widget.goals,
        claimedQuestIds: claimedQuestIds,
        claimingQuestId: _claimingQuestId,
        onClaim: _claimQuest,
        showSyncWarning: true,
      ),
      data: (weekLogs) => _WeeklyQuestList(
        weekLogs: weekLogs,
        todayLog: widget.log,
        goals: widget.goals,
        claimedQuestIds: claimedQuestIds,
        claimingQuestId: _claimingQuestId,
        onClaim: _claimQuest,
        showSyncWarning: weeklyLogAsync.hasError,
      ),
    );
  }

  Future<void> _claimQuest(QuestDefinition quest) async {
    setState(() => _claimingQuestId = quest.id);
    try {
      final claimed = switch (quest.cadence) {
        QuestCadence.daily => await FirestoreService.instance.claimDailyQuest(
          uid: widget.uid,
          questId: quest.id,
          xpDelta: quest.xpReward,
          statDeltas: quest.statDeltas,
          taskDescription: quest.taskDescription,
        ),
        QuestCadence.weekly => await FirestoreService.instance.claimWeeklyQuest(
          uid: widget.uid,
          questId: quest.id,
          xpDelta: quest.xpReward,
          statDeltas: quest.statDeltas,
          taskDescription: quest.taskDescription,
        ),
      };

      if (!mounted) return;
      if (quest.cadence == QuestCadence.weekly) {
        ref.invalidate(weeklyQuestLogProvider);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            claimed ? 'Görev ödülü alındı!' : 'Bu görev zaten alındı.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Görev alınamadı: $e')));
    } finally {
      if (mounted) setState(() => _claimingQuestId = null);
    }
  }
}

class _QuestTab extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuestTab({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.secondaryAccent
              : AppTheme.secondaryAccent.withAlpha(24),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: selected ? Colors.white : AppTheme.secondaryAccent,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _WeeklyQuestList extends StatelessWidget {
  final List<DailyLogModel> weekLogs;
  final DailyLogModel? todayLog;
  final DailyGoals goals;
  final List<String> claimedQuestIds;
  final String? claimingQuestId;
  final ValueChanged<QuestDefinition> onClaim;
  final bool showSyncWarning;

  const _WeeklyQuestList({
    required this.weekLogs,
    required this.todayLog,
    required this.goals,
    required this.claimedQuestIds,
    required this.claimingQuestId,
    required this.onClaim,
    required this.showSyncWarning,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showSyncWarning) const _QuestSyncWarning(),
        ...WeeklyQuestCatalog.all.map((quest) {
          final progress = QuestEvaluator.progressFor(
            quest: quest,
            todayLog: todayLog,
            goals: goals,
            weekLogs: weekLogs,
            claimedQuestIds: claimedQuestIds,
          );
          final status = QuestEvaluator.statusFor(
            quest: quest,
            progress: progress,
            claimedQuestIds: claimedQuestIds,
          );

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _QuestRow(
              quest: quest,
              progress: progress,
              status: status,
              isClaiming: claimingQuestId == quest.id,
              onClaim: status == QuestStatus.ready && claimingQuestId == null
                  ? () => onClaim(quest)
                  : null,
            ),
          );
        }),
      ],
    );
  }
}

class _QuestRow extends StatelessWidget {
  final QuestDefinition quest;
  final QuestProgress progress;
  final QuestStatus status;
  final bool isClaiming;
  final VoidCallback? onClaim;

  const _QuestRow({
    required this.quest,
    required this.progress,
    required this.status,
    required this.isClaiming,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final ready = status == QuestStatus.ready;
    final claimed = status == QuestStatus.claimed;
    final borderColor = claimed
        ? AppTheme.secondaryAccent
        : ready
        ? AppTheme.primaryAccent
        : AppTheme.textSecondary.withAlpha(50);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor.withAlpha(130)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              quest.emoji,
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        quest.title,
                        style: GoogleFonts.poppins(
                          color: AppTheme.textWhite,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '+${quest.xpReward} XP',
                      style: GoogleFonts.poppins(
                        color: AppTheme.primaryAccent,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${quest.subtitle} · ${progress.label}',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress.ratio,
                    minHeight: 5,
                    backgroundColor: AppTheme.cardBackground,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      claimed
                          ? AppTheme.secondaryAccent
                          : ready
                          ? AppTheme.primaryAccent
                          : AppTheme.textSecondary.withAlpha(90),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: onClaim,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 78,
              height: 32,
              decoration: BoxDecoration(
                color: _buttonColor(),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: isClaiming
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _buttonLabel(),
                        style: GoogleFonts.poppins(
                          color: ready || claimed
                              ? Colors.white
                              : AppTheme.textSecondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _buttonColor() {
    switch (status) {
      case QuestStatus.claimed:
        return AppTheme.secondaryAccent;
      case QuestStatus.ready:
        return AppTheme.primaryAccent;
      case QuestStatus.locked:
        return AppTheme.cardBackground;
    }
  }

  String _buttonLabel() {
    switch (status) {
      case QuestStatus.claimed:
        return 'Alındı';
      case QuestStatus.ready:
        return 'Al';
      case QuestStatus.locked:
        return 'Kilitli';
    }
  }
}

class _QuestLoading extends StatelessWidget {
  const _QuestLoading();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: CircularProgressIndicator(color: AppTheme.primaryAccent),
      ),
    );
  }
}

class _QuestSyncWarning extends StatelessWidget {
  const _QuestSyncWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.warningOrange.withAlpha(22),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.warningOrange.withAlpha(80)),
      ),
      child: Text(
        'Haftalık ödül durumu senkronize edilemedi; görev ilerlemesi gösteriliyor.',
        style: GoogleFonts.poppins(color: AppTheme.textSecondary, fontSize: 11),
      ),
    );
  }
}
