import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class StickyUserRankCard extends StatelessWidget {
  final Map<String, dynamic>? userEntry;
  final int rank;
  final String value;
  final int xpToNext;

  const StickyUserRankCard({
    super.key,
    required this.userEntry,
    required this.rank,
    required this.value,
    this.xpToNext = 0,
  });

  @override
  Widget build(BuildContext context) {
    if (userEntry == null) return const SizedBox.shrink();

    final displayName = userEntry!['displayName'] as String? ?? 'User';
    final safeName = displayName.isNotEmpty ? displayName : 'User';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        border: const Border(
          top: BorderSide(color: AppTheme.primaryAccent, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '#$rank',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: rank <= 3
                      ? AppTheme.warningOrange
                      : AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              backgroundColor: AppTheme.primaryAccent,
              radius: 18,
              child: Text(
                safeName[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$safeName (Sen)',
                    style: GoogleFonts.poppins(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (xpToNext > 0)
                    Text(
                      'Sonraki sıraya: $xpToNext XP',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
