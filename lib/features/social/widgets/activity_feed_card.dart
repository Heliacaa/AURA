import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/haptics.dart';

class ActivityFeedCard extends StatelessWidget {
  final String userName;
  final String userAvatarUrl;
  final String actionTitle;
  final String actionDescription;
  final String timeAgo;
  final bool isSpecialAchievement; // Animasyonlu stili tetikler
  final bool isLikedByMe;
  final VoidCallback? onLikePressed;
  final VoidCallback? onUserTap;

  const ActivityFeedCard({
    super.key,
    required this.userName,
    required this.userAvatarUrl,
    required this.actionTitle,
    required this.actionDescription,
    required this.timeAgo,
    this.isSpecialAchievement = false,
    this.isLikedByMe = false,
    this.onLikePressed,
    this.onUserTap,
  });

  void _onLikePressed() {
    if (onLikePressed == null) return;
    AppHaptics.lightImpact();
    onLikePressed!();
  }

  @override
  Widget build(BuildContext context) {
    final safeUserName = userName.isNotEmpty ? userName : 'AURA User';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: isSpecialAchievement
            ? Border.all(color: Colors.amberAccent, width: 1.5)
            : null,
        boxShadow: isSpecialAchievement
            ? [
                BoxShadow(
                  color: Colors.amberAccent.withAlpha(26),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: onUserTap,
            child: CircleAvatar(
              backgroundColor: AppTheme.primaryAccent,
              radius: 20,
              child: Text(
                safeUserName[0].toUpperCase(),
                style: GoogleFonts.poppins(
                  color: AppTheme.background,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: onUserTap,
                      child: Text(
                        safeUserName,
                        style: GoogleFonts.poppins(
                          color: AppTheme.textWhite,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    Text(
                      timeAgo,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  actionTitle,
                  style: GoogleFonts.poppins(
                    color: isSpecialAchievement
                        ? Colors.amberAccent
                        : AppTheme.textWhite,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                if (actionDescription.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    actionDescription,
                    style: GoogleFonts.poppins(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (onLikePressed != null) ...[
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _onLikePressed,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isLikedByMe ? Icons.favorite : Icons.favorite_border,
                          size: 16,
                          color: isLikedByMe
                              ? Colors.redAccent
                              : AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isLikedByMe ? "Tebrik Ettin" : "Tebrik Et",
                          style: GoogleFonts.poppins(
                            color: isLikedByMe
                                ? Colors.redAccent
                                : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: isLikedByMe
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
