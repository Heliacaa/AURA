import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/public_profile_model.dart';
import '../../social/providers/friends_provider.dart';

class PublicProfileScreen extends ConsumerStatefulWidget {
  final String uid;

  const PublicProfileScreen({super.key, required this.uid});

  @override
  ConsumerState<PublicProfileScreen> createState() =>
      _PublicProfileScreenState();
}

class _PublicProfileScreenState extends ConsumerState<PublicProfileScreen> {
  bool _busy = false;

  Future<void> _runAction(
    Future<void> Function() action, {
    required String successMessage,
  }) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(publicProfileProvider(widget.uid));
      ref.invalidate(friendshipsProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('İşlem başarısız: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(publicProfileProvider(widget.uid));

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: const Text('Profil')),
      body: profileAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryAccent),
        ),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Profil yüklenemedi: $e',
              style: GoogleFonts.poppins(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (profile) => SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _Header(profile: profile),
              const SizedBox(height: 20),
              _StatsCard(profile: profile),
              if (profile.isFriend || profile.isSelf) ...[
                const SizedBox(height: 12),
                _FriendVisibleCard(profile: profile),
              ],
              const SizedBox(height: 20),
              _actionArea(profile),
            ],
          ),
        ),
      ),
    );
  }

  Widget _actionArea(PublicProfileModel profile) {
    final service = ref.read(friendServiceProvider);

    if (profile.isSelf) {
      return FilledButton.icon(
        onPressed: () => context.push('/profile/edit'),
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Profili Düzenle'),
        style: _primaryButtonStyle(),
      );
    }

    if (profile.isIncomingRequest) {
      return Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: _busy
                  ? null
                  : () => _runAction(
                      () => service.acceptFriendRequest(profile.uid),
                      successMessage: 'Arkadaşlık isteği kabul edildi.',
                    ),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Kabul Et'),
              style: _primaryButtonStyle(),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _busy
                  ? null
                  : () => _runAction(
                      () => service.declineFriendRequest(profile.uid),
                      successMessage: 'Arkadaşlık isteği reddedildi.',
                    ),
              icon: const Icon(Icons.close_rounded),
              label: const Text('Reddet'),
              style: _dangerOutlineStyle(),
            ),
          ),
        ],
      );
    }

    if (profile.isOutgoingRequest) {
      return OutlinedButton.icon(
        onPressed: _busy
            ? null
            : () => _runAction(
                () => service.declineFriendRequest(profile.uid),
                successMessage: 'Arkadaşlık isteği iptal edildi.',
              ),
        icon: const Icon(Icons.schedule_rounded),
        label: const Text('İstek Gönderildi'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTheme.warningOrange,
          side: BorderSide(color: AppTheme.warningOrange.withAlpha(150)),
          minimumSize: const Size.fromHeight(52),
        ),
      );
    }

    if (profile.isFriend) {
      return OutlinedButton.icon(
        onPressed: _busy
            ? null
            : () => _runAction(
                () => service.removeFriend(profile.uid),
                successMessage: 'Arkadaş kaldırıldı.',
              ),
        icon: const Icon(Icons.person_remove_rounded),
        label: const Text('Arkadaşı Kaldır'),
        style: _dangerOutlineStyle(),
      );
    }

    return FilledButton.icon(
      onPressed: _busy
          ? null
          : () => _runAction(
              () => service.sendFriendRequest(profile.uid),
              successMessage: 'Arkadaşlık isteği gönderildi.',
            ),
      icon: const Icon(Icons.person_add_rounded),
      label: const Text('Arkadaş Ekle'),
      style: _primaryButtonStyle(),
    );
  }

  ButtonStyle _primaryButtonStyle() {
    return FilledButton.styleFrom(
      backgroundColor: AppTheme.primaryAccent,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
    );
  }

  ButtonStyle _dangerOutlineStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppTheme.statRed,
      side: BorderSide(color: AppTheme.statRed.withAlpha(150)),
      minimumSize: const Size.fromHeight(52),
    );
  }
}

class _Header extends StatelessWidget {
  final PublicProfileModel profile;

  const _Header({required this.profile});

  @override
  Widget build(BuildContext context) {
    final safeName = profile.displayName.isNotEmpty
        ? profile.displayName
        : 'AURA User';

    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppTheme.primaryAccent.withAlpha(40),
          backgroundImage: profile.avatarUrl.isNotEmpty
              ? NetworkImage(profile.avatarUrl)
              : null,
          child: profile.avatarUrl.isEmpty
              ? Text(
                  safeName[0].toUpperCase(),
                  style: GoogleFonts.poppins(
                    color: AppTheme.primaryAccent,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 14),
        Text(
          safeName,
          style: GoogleFonts.poppins(
            color: AppTheme.textWhite,
            fontSize: 24,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: AppTheme.primaryAccent.withAlpha(30),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${profile.classIcon} Level ${profile.currentLevel} ${profile.currentClass}',
            style: GoogleFonts.poppins(
              color: AppTheme.primaryAccent,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  final PublicProfileModel profile;

  const _StatsCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    return _InfoCard(
      title: 'Herkese Açık İstatistikler',
      rows: [
        _InfoItem('XP', '${profile.xp}'),
        _InfoItem('Seri', '${profile.streakDays} gün'),
        _InfoItem('Haftalık XP', '${profile.weeklyXp}'),
      ],
    );
  }
}

class _FriendVisibleCard extends StatelessWidget {
  final PublicProfileModel profile;

  const _FriendVisibleCard({required this.profile});

  @override
  Widget build(BuildContext context) {
    final goals = profile.dailyGoals;
    return _InfoCard(
      title: profile.isSelf ? 'Profil Detayları' : 'Arkadaş Detayları',
      rows: [
        _InfoItem('Yaş', profile.age == null ? 'Eklenmedi' : '${profile.age}'),
        if (goals != null) _InfoItem('Adım Hedefi', '${goals.steps}'),
        if (goals != null) _InfoItem('Kalori Hedefi', '${goals.calories} kcal'),
        if (goals != null) _InfoItem('Su Hedefi', '${goals.waterGlasses}'),
        _InfoItem('Sosyal Enerji', profile.socialEnergyLevel ?? 'Orta'),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final List<_InfoItem> rows;

  const _InfoCard({required this.title, required this.rows});

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
            ),
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    row.value,
                    style: GoogleFonts.poppins(
                      color: AppTheme.textWhite,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoItem {
  final String label;
  final String value;

  const _InfoItem(this.label, this.value);
}
