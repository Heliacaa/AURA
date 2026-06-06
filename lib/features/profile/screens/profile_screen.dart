import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_utils.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Profil',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppTheme.textWhite,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Düzenle',
            icon: const Icon(Icons.edit_rounded),
            onPressed: () => context.push('/profile/edit'),
          ),
        ],
      ),
      body: SafeArea(
        child: userAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppTheme.primaryAccent),
          ),
          error: (e, _) => Center(
            child: Text(
              'Hata: $e',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
            ),
          ),
          data: (user) {
            if (user == null) return const SizedBox.shrink();

            final currentWeek = AppDateUtils.weekKey();
            final currentWeeklyXp = user.weeklyXpWeek == currentWeek
                ? user.weeklyXp
                : 0;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(
                    displayName: user.displayName,
                    email: user.email,
                    avatarUrl: user.avatarUrl,
                    badge:
                        '${user.classIcon} Level ${user.currentLevel} ${user.currentClass}',
                  ),
                  const SizedBox(height: 20),
                  _SectionCard(
                    title: 'Hesap Bilgileri',
                    children: [
                      _InfoRow(label: 'Ad', value: user.displayName),
                      _InfoRow(label: 'E-posta', value: user.email),
                      _InfoRow(
                        label: 'Google Fotoğrafı',
                        value: user.avatarUrl.isEmpty ? 'Yok' : 'Bağlı',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Özel Profil',
                    children: [
                      _InfoRow(
                        label: 'Yaş',
                        value: user.age == null ? 'Eklenmedi' : '${user.age}',
                      ),
                      _InfoRow(
                        label: 'Boy',
                        value: user.heightCm == null
                            ? 'Gizli'
                            : '${user.heightCm} cm',
                      ),
                      _InfoRow(
                        label: 'Kilo',
                        value: user.weightKg == null
                            ? 'Gizli'
                            : '${user.weightKg!.toStringAsFixed(1)} kg',
                      ),
                      _InfoRow(
                        label: 'Sosyal Enerji',
                        value: user.socialEnergyLevel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Günlük Hedefler',
                    children: [
                      _InfoRow(
                        label: 'Adım',
                        value: '${user.dailyGoals.steps}',
                      ),
                      _InfoRow(
                        label: 'Kalori',
                        value: '${user.dailyGoals.calories} kcal',
                      ),
                      _InfoRow(
                        label: 'Su',
                        value: '${user.dailyGoals.waterGlasses} bardak',
                      ),
                      _InfoRow(
                        label: 'Weekly League',
                        value: user.leaderboardOptIn ? 'Açık' : 'Kapalı',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Oyun İstatistikleri',
                    children: [
                      _InfoRow(label: 'XP', value: '${user.xp}'),
                      _InfoRow(label: 'Seri', value: '${user.streakDays} gün'),
                      _InfoRow(label: 'Haftalık XP', value: '$currentWeeklyXp'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _SectionCard(
                    title: 'Sosyal',
                    children: [
                      _InfoRow(
                        label: 'Başarı paylaşımı',
                        value: user.shareMilestones ? 'Açık' : 'Kapalı',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context.push('/profile/edit'),
                    icon: const Icon(Icons.edit_rounded),
                    label: const Text('Profili Düzenle'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/login');
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Çıkış Yap'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.statRed,
                      side: BorderSide(color: AppTheme.statRed.withAlpha(120)),
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final String avatarUrl;
  final String badge;

  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.avatarUrl,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final safeName = displayName.isNotEmpty ? displayName : 'AURA User';

    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppTheme.primaryAccent.withAlpha(40),
          backgroundImage: avatarUrl.isNotEmpty
              ? NetworkImage(avatarUrl)
              : null,
          child: avatarUrl.isEmpty
              ? Text(
                  safeName[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryAccent,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 16),
        Text(
          safeName,
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.textWhite,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          email,
          style: GoogleFonts.poppins(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primaryAccent.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            badge,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryAccent,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.poppins(
              color: AppTheme.textWhite,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(
                color: AppTheme.textWhite,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
