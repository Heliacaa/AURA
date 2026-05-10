import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';

class ScoreboardPodium extends StatelessWidget {
  final List<Map<String, dynamic>> topEntries;
  final String? currentUid;
  final String Function(Map<String, dynamic>) getValue;

  const ScoreboardPodium({
    super.key,
    required this.topEntries,
    required this.currentUid,
    required this.getValue,
  });

  @override
  Widget build(BuildContext context) {
    if (topEntries.isEmpty) return const SizedBox.shrink();

    final first = topEntries.isNotEmpty ? topEntries[0] : null;
    final second = topEntries.length > 1 ? topEntries[1] : null;
    final third = topEntries.length > 2 ? topEntries[2] : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (second != null)
            _buildPodiumItem(second, 2, 80, AppTheme.textSecondary),
          if (second != null) const SizedBox(width: 12),
          if (first != null)
            _buildPodiumItem(first, 1, 110, AppTheme.warningOrange),
          if (third != null) const SizedBox(width: 12),
          if (third != null)
            _buildPodiumItem(third, 3, 60, const Color(0xFFCD7F32)),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
      Map<String, dynamic> entry, int rank, double height, Color rankColor) {
    final displayName = entry['displayName'] as String? ?? 'User';
    final safeName = displayName.isNotEmpty ? displayName : 'User';
    final isMe = entry['uid'] == currentUid || (entry['isMe'] as bool? ?? false);
    final value = getValue(entry);

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          CircleAvatar(
            backgroundColor:
                isMe ? AppTheme.primaryAccent : AppTheme.textSecondary,
            radius: rank == 1 ? 28 : 22,
            child: Text(
              safeName[0].toUpperCase(),
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: rank == 1 ? 24 : 18,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            safeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              color: AppTheme.textWhite,
              fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.poppins(
              color: AppTheme.primaryAccent,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: rankColor.withAlpha(rank == 1 ? 80 : 40),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
              border: Border.all(color: rankColor.withAlpha(100), width: 1),
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: GoogleFonts.poppins(
                  color: rankColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
