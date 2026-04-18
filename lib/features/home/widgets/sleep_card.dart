import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_theme.dart';

class SleepCard extends StatelessWidget {
  final double sleepHours;
  final String sleepQuality;
  final VoidCallback onTap;

  const SleepCard({
    super.key,
    required this.sleepHours,
    required this.sleepQuality,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = sleepHours > 0;
    final qualityEmoji = _qualityEmoji(sleepQuality);
    final qualityColor = _qualityColor(sleepQuality);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: AppTheme.cardDecoration(borderColor: AppTheme.statBlue),
        child: Row(
          children: [
            const Text('😴', style: TextStyle(fontSize: 28)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasData
                        ? '${sleepHours.toStringAsFixed(1)}h sleep'
                        : 'Log Sleep',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textWhite,
                    ),
                  ),
                  if (hasData && sleepQuality.isNotEmpty)
                    Text(
                      '$qualityEmoji $sleepQuality',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: qualityColor,
                      ),
                    ),
                  if (!hasData)
                    Text(
                      'Tap to log last night\'s sleep',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            if (!hasData)
              const Icon(Icons.add_circle_outline,
                  color: AppTheme.statBlue, size: 24),
          ],
        ),
      ),
    );
  }

  String _qualityEmoji(String quality) {
    switch (quality.toLowerCase()) {
      case 'good':
        return '🌟';
      case 'fair':
        return '😐';
      case 'poor':
        return '😴';
      default:
        return '';
    }
  }

  Color _qualityColor(String quality) {
    switch (quality.toLowerCase()) {
      case 'good':
        return AppTheme.secondaryAccent;
      case 'fair':
        return AppTheme.warningOrange;
      case 'poor':
        return AppTheme.statRed;
      default:
        return AppTheme.textSecondary;
    }
  }
}
