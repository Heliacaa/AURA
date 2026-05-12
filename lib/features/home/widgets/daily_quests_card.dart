import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/models/daily_log_model.dart';
import '../../../shared/models/user_model.dart';
import '../models/daily_quest.dart';

enum DailyQuestStatus { locked, ready, claimed }

class DailyQuestsCard extends StatefulWidget {
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
  State<DailyQuestsCard> createState() => _DailyQuestsCardState();
}

class _DailyQuestsCardState extends State<DailyQuestsCard> {
  String? _claimingQuestId;

  @override
  Widget build(BuildContext context) {
    final completedCount = widget.log == null
        ? 0
        : DailyQuestCatalog.all
              .where((quest) => widget.log!.claimedQuestIds.contains(quest.id))
              .length;

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
                      'Günlük Görevler',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textWhite,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$completedCount / ${DailyQuestCatalog.all.length} ödül alındı',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.secondaryAccent.withAlpha(28),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Daily Quests',
                  style: GoogleFonts.poppins(
                    color: AppTheme.secondaryAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...DailyQuestCatalog.all.map((quest) {
            final status = _statusFor(quest);
            final isClaiming = _claimingQuestId == quest.id;
            
            // Dinamik olarak hedef sayılarını subtitle içerisine gömelim
            String questSubtitle = quest.subtitle;
            if (quest.id == DailyQuestIds.water) {
              questSubtitle = 'Günlük su hedefini (${widget.goals.waterGlasses} bardak) tamamla';
            } else if (quest.id == DailyQuestIds.steps) {
              questSubtitle = 'Günlük adım hedefini (${widget.goals.steps}) tamamla';
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _QuestRow(
                quest: quest,
                dynamicSubtitle: questSubtitle,
                status: status,
                isClaiming: isClaiming,
                onClaim: status == DailyQuestStatus.ready && !isClaiming
                    ? () => _claimQuest(quest)
                    : null,
              ),
            );
          }),
        ],
      ),
    );
  }

  DailyQuestStatus _statusFor(DailyQuest quest) {
    final log = widget.log;
    if (log == null) return DailyQuestStatus.locked;
    if (log.claimedQuestIds.contains(quest.id)) {
      return DailyQuestStatus.claimed;
    }
    if (quest.isComplete(log, widget.goals)) {
      return DailyQuestStatus.ready;
    }
    return DailyQuestStatus.locked;
  }

  Future<void> _claimQuest(DailyQuest quest) async {
    setState(() => _claimingQuestId = quest.id);
    try {
      final claimed = await FirestoreService.instance.claimDailyQuest(
        uid: widget.uid,
        questId: quest.id,
        xpDelta: quest.xpReward,
        statDeltas: quest.statDeltas,
        taskDescription: quest.taskDescription,
      );

      if (!mounted) return;
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

class _QuestRow extends StatelessWidget {
  final DailyQuest quest;
  final String dynamicSubtitle;
  final DailyQuestStatus status;
  final bool isClaiming;
  final VoidCallback? onClaim;

  const _QuestRow({
    required this.quest,
    required this.dynamicSubtitle,
    required this.status,
    required this.isClaiming,
    required this.onClaim,
  });

  @override
  Widget build(BuildContext context) {
    final ready = status == DailyQuestStatus.ready;
    final claimed = status == DailyQuestStatus.claimed;
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
                Text(
                  quest.title,
                  style: GoogleFonts.poppins(
                    color: AppTheme.textWhite,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$dynamicSubtitle · +${quest.xpReward} XP',
                  style: GoogleFonts.poppins(
                    color: AppTheme.textSecondary,
                    fontSize: 11,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
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
                          fontSize: 11,
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
      case DailyQuestStatus.ready:
        return AppTheme.primaryAccent;
      case DailyQuestStatus.claimed:
        return AppTheme.secondaryAccent;
      case DailyQuestStatus.locked:
        return AppTheme.cardBackground;
    }
  }

  String _buttonLabel() {
    switch (status) {
      case DailyQuestStatus.ready:
        return 'Al';
      case DailyQuestStatus.claimed:
        return 'Alındı';
      case DailyQuestStatus.locked:
        return 'Kilitli';
    }
  }
}
