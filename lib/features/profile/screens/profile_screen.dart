import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/firestore_service.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _stepsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _waterController = TextEditingController();

  String? _loadedUid;
  String _socialEnergyLevel = 'Orta';
  bool _leaderboardOptIn = false;
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _stepsController.dispose();
    _caloriesController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  void _loadUser(UserModel user) {
    if (_loadedUid == user.uid) return;
    _loadedUid = user.uid;
    _nameController.text = user.displayName;
    _stepsController.text = user.dailyGoals.steps.toString();
    _caloriesController.text = user.dailyGoals.calories.toString();
    _waterController.text = user.dailyGoals.waterGlasses.toString();
    _socialEnergyLevel = user.socialEnergyLevel;
    _leaderboardOptIn = user.leaderboardOptIn;
  }

  Future<void> _save(UserModel user) async {
    if (!_formKey.currentState!.validate()) return;

    final displayName = _nameController.text.trim();
    final goals = DailyGoals(
      steps: int.parse(_stepsController.text.trim()),
      calories: int.parse(_caloriesController.text.trim()),
      waterGlasses: int.parse(_waterController.text.trim()),
    );

    setState(() => _saving = true);
    try {
      await ref.read(authServiceProvider).updateDisplayName(displayName);
      await FirestoreService.instance.updateUserProfile(
        uid: user.uid,
        displayName: displayName,
        avatarUrl: user.avatarUrl,
        dailyGoals: goals,
        socialEnergyLevel: _socialEnergyLevel,
        leaderboardOptIn: _leaderboardOptIn,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil güncellendi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profil güncellenemedi: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _signOut() async {
    await ref.read(authServiceProvider).signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          'Profil',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w700,
            color: AppTheme.textWhite,
          ),
        ),
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
            _loadUser(user);

            return Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  _ProfileHeader(user: user),
                  const SizedBox(height: 24),
                  _SectionTitle('Hesap'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    style: GoogleFonts.poppins(color: AppTheme.textWhite),
                    decoration: AppTheme.inputDecoration(
                      hintText: 'Ad Soyad',
                      prefixIcon: Icons.person_outline,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Ad soyad giriniz';
                      }
                      if (value.trim().length < 2) {
                        return 'En az 2 karakter giriniz';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  _ReadOnlyInfoRow(
                    icon: Icons.email_outlined,
                    label: user.email.isNotEmpty ? user.email : 'E-posta yok',
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle('Günlük Hedefler'),
                  const SizedBox(height: 8),
                  _NumberField(
                    controller: _stepsController,
                    hintText: 'Adım hedefi',
                    icon: Icons.directions_walk_rounded,
                    min: 100,
                    max: 100000,
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    controller: _caloriesController,
                    hintText: 'Kalori hedefi',
                    icon: Icons.local_fire_department_outlined,
                    min: 500,
                    max: 10000,
                  ),
                  const SizedBox(height: 12),
                  _NumberField(
                    controller: _waterController,
                    hintText: 'Su bardağı hedefi',
                    icon: Icons.water_drop_outlined,
                    min: 1,
                    max: 30,
                  ),
                  const SizedBox(height: 24),
                  _SectionTitle('Sosyal'),
                  const SizedBox(height: 8),
                  _EnergyPicker(
                    value: _socialEnergyLevel,
                    onChanged: (value) {
                      setState(() => _socialEnergyLevel = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    value: _leaderboardOptIn,
                    activeThumbColor: AppTheme.secondaryAccent,
                    title: Text(
                      'Weekly League görünürlüğü',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      _leaderboardOptIn
                          ? 'Haftalık sıralamada görünürsün.'
                          : 'Haftalık sıralamada görünmezsin.',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _leaderboardOptIn = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  _PrimaryActionButton(
                    label: 'Kaydet',
                    loading: _saving,
                    onTap: _saving ? null : () => _save(user),
                  ),
                  const SizedBox(height: 12),
                  _SignOutButton(onTap: _saving ? null : _signOut),
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
  final UserModel user;

  const _ProfileHeader({required this.user});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: AppTheme.primaryAccent.withAlpha(40),
          backgroundImage: user.avatarUrl.isNotEmpty
              ? NetworkImage(user.avatarUrl)
              : null,
          child: user.avatarUrl.isEmpty
              ? Text(
                  user.displayName.isNotEmpty
                      ? user.displayName[0].toUpperCase()
                      : '?',
                  style: GoogleFonts.poppins(
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryAccent,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),
        Text(
          '${user.classIcon} Level ${user.currentLevel} ${user.currentClass}',
          style: GoogleFonts.poppins(
            color: AppTheme.primaryAccent,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;

  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.poppins(
        color: AppTheme.textSecondary,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _ReadOnlyInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ReadOnlyInfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 52),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppTheme.cardDecoration(),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.textSecondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.poppins(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final int min;
  final int max;

  const _NumberField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: GoogleFonts.poppins(color: AppTheme.textWhite),
      decoration: AppTheme.inputDecoration(
        hintText: hintText,
        prefixIcon: icon,
      ),
      validator: (value) {
        final number = int.tryParse(value?.trim() ?? '');
        if (number == null) return 'Sayı giriniz';
        if (number < min || number > max) {
          return '$min - $max arası olmalı';
        }
        return null;
      },
    );
  }
}

class _EnergyPicker extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _EnergyPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    const options = ['Düşük', 'Orta', 'Yüksek'];
    return Row(
      children: options.map((option) {
        final selected = option == value;
        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(option),
            child: Container(
              height: 44,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: selected
                    ? AppTheme.primaryAccent
                    : AppTheme.cardBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected
                      ? AppTheme.primaryAccent
                      : Colors.white.withAlpha(20),
                ),
              ),
              child: Center(
                child: Text(
                  option,
                  style: GoogleFonts.poppins(
                    color: selected ? Colors.white : AppTheme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback? onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.loading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: AppTheme.gradientButton(radius: 12),
        child: Center(
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  final VoidCallback? onTap;

  const _SignOutButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.statRed.withAlpha(60)),
        ),
        child: Center(
          child: Text(
            'Çıkış Yap',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.statRed,
            ),
          ),
        ),
      ),
    );
  }
}
