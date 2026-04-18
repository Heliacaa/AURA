import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/user_model.dart';

class LevelUpDialog extends StatefulWidget {
  final int newLevel;
  final String newClass;

  const LevelUpDialog({
    super.key,
    required this.newLevel,
    required this.newClass,
  });

  /// Show level-up dialog with confetti
  static Future<void> show(BuildContext context,
      {required int level, String? newClass}) async {
    final className = newClass ?? UserModel.classForLevel(level);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LevelUpDialog(newLevel: level, newClass: className),
    );
  }

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  String get _classIcon {
    switch (widget.newClass) {
      case 'Novice':
        return '🌱';
      case 'Warrior':
        return '🛡️';
      case 'Mage':
        return '🧙';
      case 'Champion':
        return '⚔️';
      case 'Legend':
        return '👑';
      default:
        return '🌱';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AlertDialog(
          backgroundColor: AppTheme.cardBackground,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(_classIcon, style: const TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              Text(
                'SEVİYE ATLADI!',
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tebrikler! Seviye ${widget.newLevel}\'e ulaştın!',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: AppTheme.textWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'Sınıf: ${widget.newClass}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: AppTheme.secondaryAccent,
                ),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: double.infinity,
                  height: 48,
                  decoration: AppTheme.gradientButton(radius: 12),
                  child: Center(
                    child: Text(
                      'Harika!',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Confetti
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            colors: const [
              AppTheme.primaryAccent,
              AppTheme.secondaryAccent,
              AppTheme.warningOrange,
              AppTheme.statBlue,
              AppTheme.statPink,
            ],
          ),
        ),
      ],
    );
  }
}
