import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_theme.dart';
import '../../../services/firestore_service.dart';
import '../../../services/notification_service.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/providers/auth_provider.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  final _stepsController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _waterController = TextEditingController();

  bool _seeded = false;
  bool _saving = false;
  bool _leaderboardOptIn = false;
  bool _shareMilestones = true;
  bool _waterReminders = false;
  bool _dailyGoalReminder = false;
  String _socialEnergyLevel = 'Orta';

  static const _energyLevels = ['Düşük', 'Orta', 'Yüksek'];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _stepsController.dispose();
    _caloriesController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  void _seed(UserModel user) {
    if (_seeded) return;
    _seeded = true;
    _nameController.text = user.displayName;
    _ageController.text = user.age?.toString() ?? '';
    _heightController.text = user.heightCm?.toString() ?? '';
    _weightController.text = user.weightKg?.toStringAsFixed(1) ?? '';
    _stepsController.text = user.dailyGoals.steps.toString();
    _caloriesController.text = user.dailyGoals.calories.toString();
    _waterController.text = user.dailyGoals.waterGlasses.toString();
    _leaderboardOptIn = user.leaderboardOptIn;
    _shareMilestones = user.shareMilestones;
    _waterReminders = user.notificationPreferences.waterReminders;
    _dailyGoalReminder = user.notificationPreferences.dailyGoalReminder;
    _socialEnergyLevel = _energyLevels.contains(user.socialEnergyLevel)
        ? user.socialEnergyLevel
        : 'Orta';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final authUser = ref.read(authStateProvider).valueOrNull;
    if (authUser == null) return;

    setState(() => _saving = true);
    final displayName = _nameController.text.trim();

    try {
      await FirebaseAuth.instance.currentUser?.updateDisplayName(displayName);
      await FirestoreService.instance.updateProfileSettings(
        uid: authUser.uid,
        displayName: displayName,
        age: _optionalInt(_ageController.text),
        heightCm: _optionalInt(_heightController.text),
        weightKg: _optionalDouble(_weightController.text),
        dailyGoals: DailyGoals(
          steps: int.parse(_stepsController.text.trim()),
          calories: int.parse(_caloriesController.text.trim()),
          waterGlasses: int.parse(_waterController.text.trim()),
        ),
        socialEnergyLevel: _socialEnergyLevel,
        leaderboardOptIn: _leaderboardOptIn,
        shareMilestones: _shareMilestones,
        notificationPreferences: NotificationPreferences(
          waterReminders: _waterReminders,
          dailyGoalReminder: _dailyGoalReminder,
        ),
      );
      await NotificationService.instance.applyPreferences(
        preferences: NotificationPreferences(
          waterReminders: _waterReminders,
          dailyGoalReminder: _dailyGoalReminder,
        ),
        dailyGoals: DailyGoals(
          steps: int.parse(_stepsController.text.trim()),
          calories: int.parse(_caloriesController.text.trim()),
          waterGlasses: int.parse(_waterController.text.trim()),
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil güncellendi.')));
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Profil kaydedilemedi: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateReminderPreference({
    required bool value,
    required bool water,
  }) async {
    if (value) {
      final granted = await NotificationService.instance
          .requestLocalPermission();
      if (!granted && mounted) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: AppTheme.cardBackground,
            title: const Text('Bildirim izni gerekli'),
            content: const Text(
              'Yerel hatırlatmaları açmak için iOS Ayarları üzerinden AURA bildirimlerine izin ver.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Daha Sonra'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  NotificationService.instance.openSystemSettings();
                },
                child: const Text('Ayarları Aç'),
              ),
            ],
          ),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      if (water) {
        _waterReminders = value;
      } else {
        _dailyGoalReminder = value;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          'Profili Düzenle',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w700),
        ),
      ),
      body: userAsync.when(
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
          _seed(user);

          return SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                children: [
                  _sectionTitle('Hesap'),
                  _field(
                    controller: _nameController,
                    label: 'Ad',
                    icon: Icons.person_rounded,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return 'Ad gerekli';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 18),
                  _sectionTitle('Özel Bilgiler'),
                  _field(
                    controller: _ageController,
                    label: 'Yaş',
                    icon: Icons.cake_rounded,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        _optionalIntValidator(value, min: 1, max: 120),
                  ),
                  _field(
                    controller: _heightController,
                    label: 'Boy (cm)',
                    icon: Icons.height_rounded,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        _optionalIntValidator(value, min: 50, max: 250),
                  ),
                  _field(
                    controller: _weightController,
                    label: 'Kilo (kg)',
                    icon: Icons.monitor_weight_rounded,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) =>
                        _optionalDoubleValidator(value, min: 20, max: 350),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: _socialEnergyLevel,
                    dropdownColor: AppTheme.cardBackground,
                    decoration: AppTheme.inputDecoration(
                      hintText: 'Sosyal Enerji',
                      prefixIcon: Icons.bolt_rounded,
                    ),
                    items: _energyLevels
                        .map(
                          (value) => DropdownMenuItem(
                            value: value,
                            child: Text(
                              value,
                              style: GoogleFonts.poppins(
                                color: AppTheme.textWhite,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _socialEnergyLevel = value);
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  _sectionTitle('Günlük Hedefler'),
                  _field(
                    controller: _stepsController,
                    label: 'Adım hedefi',
                    icon: Icons.directions_walk_rounded,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        _requiredIntValidator(value, min: 100, max: 100000),
                  ),
                  _field(
                    controller: _caloriesController,
                    label: 'Kalori hedefi',
                    icon: Icons.local_fire_department_rounded,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        _requiredIntValidator(value, min: 500, max: 10000),
                  ),
                  _field(
                    controller: _waterController,
                    label: 'Su hedefi (bardak)',
                    icon: Icons.water_drop_rounded,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        _requiredIntValidator(value, min: 1, max: 30),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile.adaptive(
                    value: _leaderboardOptIn,
                    activeThumbColor: AppTheme.secondaryAccent,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Weekly League görünürlüğü',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Açıkken haftalık XP sıralamasında görünürsün.',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => _leaderboardOptIn = value),
                  ),
                  const SizedBox(height: 18),
                  _sectionTitle('Sosyal ve Bildirimler'),
                  SwitchListTile.adaptive(
                    value: _shareMilestones,
                    activeThumbColor: AppTheme.secondaryAccent,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Başarıları arkadaşlarla paylaş',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Seri, seviye ve rozet başarıların arkadaş akışında görünür.',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => _shareMilestones = value),
                  ),
                  SwitchListTile.adaptive(
                    value: _waterReminders,
                    activeThumbColor: AppTheme.secondaryAccent,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Su hatırlatmaları',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Her gün 11:00, 15:00 ve 19:00 saatlerinde cihazında hatırlatma gösterir.',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    onChanged: (value) =>
                        _updateReminderPreference(value: value, water: true),
                  ),
                  SwitchListTile.adaptive(
                    value: _dailyGoalReminder,
                    activeThumbColor: AppTheme.secondaryAccent,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Günlük hedef hatırlatması',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textWhite,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'Her gün saat 20:00’de adım ve su hedeflerini kontrol etmeni hatırlatır.',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    onChanged: (value) =>
                        _updateReminderPreference(value: value, water: false),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(_saving ? 'Kaydediliyor' : 'Kaydet'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppTheme.primaryAccent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          color: AppTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: GoogleFonts.poppins(color: AppTheme.textWhite),
        decoration: AppTheme.inputDecoration(hintText: label, prefixIcon: icon),
      ),
    );
  }

  String? _requiredIntValidator(
    String? value, {
    required int min,
    required int max,
  }) {
    final parsed = int.tryParse((value ?? '').trim());
    if (parsed == null) return 'Geçerli bir sayı gir';
    if (parsed < min || parsed > max) return '$min - $max arası olmalı';
    return null;
  }

  String? _optionalIntValidator(
    String? value, {
    required int min,
    required int max,
  }) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = int.tryParse(text);
    if (parsed == null) return 'Geçerli bir sayı gir';
    if (parsed < min || parsed > max) return '$min - $max arası olmalı';
    return null;
  }

  String? _optionalDoubleValidator(
    String? value, {
    required double min,
    required double max,
  }) {
    final text = (value ?? '').trim().replaceAll(',', '.');
    if (text.isEmpty) return null;
    final parsed = double.tryParse(text);
    if (parsed == null) return 'Geçerli bir sayı gir';
    if (parsed < min || parsed > max) {
      return '${min.toInt()} - ${max.toInt()} arası olmalı';
    }
    return null;
  }

  int? _optionalInt(String value) {
    final text = value.trim();
    return text.isEmpty ? null : int.parse(text);
  }

  double? _optionalDouble(String value) {
    final text = value.trim().replaceAll(',', '.');
    return text.isEmpty ? null : double.parse(text);
  }
}
