import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/aura_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../home/providers/home_provider.dart';
import '../providers/scan_provider.dart';
import '../services/vision_service.dart';
import '../../../services/firestore_service.dart';
import '../../../services/storage_service.dart';

class ScanScreen extends ConsumerStatefulWidget {
  const ScanScreen({super.key});

  @override
  ConsumerState<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends ConsumerState<ScanScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  late AnimationController _scanLineController;

  @override
  void initState() {
    super.initState();
    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _scanLineController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return;

    ref.read(scannedImageProvider.notifier).state = picked;
    ref.read(scanResultProvider.notifier).state = null;

    // Start analysis
    ref.read(scanLoadingProvider.notifier).state = true;
    _scanLineController.repeat();

    try {
      // Get today's meals for goal-aware analysis
      final user = ref.read(currentUserProvider).valueOrNull;
      final todayMeals = ref.read(todayMealsProvider).valueOrNull ?? [];
      int caloriesConsumed = 0;
      double proteinConsumed = 0;
      double carbsConsumed = 0;
      double fatConsumed = 0;
      for (final m in todayMeals) {
        caloriesConsumed += m.calories;
        proteinConsumed += m.protein;
        carbsConsumed += m.carbs;
        fatConsumed += m.fat;
      }

      final result = await VisionService.instance.analyzeFood(
        picked,
        calorieGoal: user?.dailyGoals.calories ?? 2000,
        caloriesConsumed: caloriesConsumed,
        proteinConsumed: proteinConsumed,
        carbsConsumed: carbsConsumed,
        fatConsumed: fatConsumed,
      );
      ref.read(scanResultProvider.notifier).state = result;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Analiz başarısız: ${e.toString()}')),
        );
      }
    } finally {
      ref.read(scanLoadingProvider.notifier).state = false;
      _scanLineController.stop();
    }
  }

  Future<void> _saveMeal() async {
    final image = ref.read(scannedImageProvider);
    final result = ref.read(scanResultProvider);
    final uid = ref.read(authStateProvider).valueOrNull?.uid;

    if (image == null || result == null || uid == null) return;
    
    ref.read(scanSavingProvider.notifier).state = true;

    try {
      // Upload image (with fallback)
      debugPrint('Resim yükleniyor...');
      String imageUrl = '';
      try {
        imageUrl = await StorageService.instance.uploadMealImage(
          uid: uid,
          imageFile: image,
        );
        debugPrint('Resim yüklendi: $imageUrl');
      } catch (storageErr) {
        debugPrint('Resim yüklenemedi (Storage hatası): $storageErr');
        // İsteğe bağlı olarak kullanıcıya küçük bir uyarı gösterebilirsiniz
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Resim Firebase\'e yüklenemedi ancak veriler kaydediliyor...')),
          );
        }
      }

      // Save meal with image URL
      debugPrint('Firestore kaydı yapılıyor...');
      final meal = result.copyWith(imageUrl: imageUrl);
      await FirestoreService.instance.saveMeal(uid, meal).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Veritabanı kaydı zaman aşımına uğradı.'),
      );
      debugPrint('Firestore kaydı tamamlandı.');

      // Award XP
      await FirestoreService.instance.updateUserXP(
        uid: uid,
        xpDelta: 20,
        statDeltas: {'vitality': 3},
        taskDescription: '+3 Vitalite (Yemek kaydedildi)',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yemek kaydedildi! 🎉')),
        );
      }

      // Reset state
      ref.read(scannedImageProvider.notifier).state = null;
      ref.read(scanResultProvider.notifier).state = null;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt başarısız: ${e.toString()}')),
        );
      }
    } finally {
      ref.read(scanSavingProvider.notifier).state = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final image = ref.watch(scannedImageProvider);
    final result = ref.watch(scanResultProvider);
    final isLoading = ref.watch(scanLoadingProvider);
    final isSaving = ref.watch(scanSavingProvider);
    final pastScansAsyc = ref.watch(pastScansProvider);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'AI Vision Tarama',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppTheme.textWhite,
              ),
            ),
            const SizedBox(height: 20),

            // Image preview
            GestureDetector(
              onTap: () => _pickImage(ImageSource.camera),
              child: Container(
                width: double.infinity,
                height: 220,
                decoration: BoxDecoration(
                  color: AppTheme.cardBackground,
                  borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
                  child: Stack(
                    children: [
                      if (image != null)
                        Positioned.fill(
                          child: kIsWeb
                              ? Image.network(image.path, fit: BoxFit.cover)
                              : Image.file(File(image.path), fit: BoxFit.cover),
                        )
                      else
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('🍽️',
                                  style: TextStyle(fontSize: 48)),
                              const SizedBox(height: 8),
                              Text(
                                'Yemek fotoğrafı çekmek için dokun',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Scan line animation
                      if (isLoading)
                        AnimatedBuilder(
                          animation: _scanLineController,
                          builder: (context, child) {
                            return Positioned(
                              top: _scanLineController.value * 216,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppTheme.secondaryAccent.withAlpha(0),
                                      AppTheme.secondaryAccent,
                                      AppTheme.secondaryAccent.withAlpha(0),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: isLoading
                        ? null
                        : () => _pickImage(ImageSource.camera),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.camera_alt_rounded,
                                color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Fotoğraf Çek',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: isLoading
                        ? null
                        : () => _pickImage(ImageSource.gallery),
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white.withAlpha(20)),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.photo_library_rounded,
                                color: AppTheme.textSecondary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Galeriden Seç',
                              style: GoogleFonts.poppins(
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Loading indicator
            if (isLoading) ...[
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(
                        color: AppTheme.secondaryAccent),
                    const SizedBox(height: 12),
                    Text(
                      'Yemek analiz ediliyor...',
                      style: GoogleFonts.poppins(
                        color: AppTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Results
            if (result != null) ...[
              Text(
                'Tarama Sonuçları',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              AuraCard(
                emoji: '✅',
                title: 'Tespit Edildi: ${result.detectedFood}',
                borderColor: AppTheme.secondaryAccent,
              ),
              AuraCard(
                emoji: '🔥',
                title: 'Kalori: ${result.calories} kcal',
                borderColor: AppTheme.secondaryAccent,
              ),
              // Remaining budget indicator
              Builder(builder: (context) {
                final user = ref.watch(currentUserProvider).valueOrNull;
                final todayMeals =
                    ref.watch(todayMealsProvider).valueOrNull ?? [];
                int consumed = 0;
                for (final m in todayMeals) {
                  consumed += m.calories;
                }
                final goal = user?.dailyGoals.calories ?? 2000;
                final remaining = goal - consumed - result.calories;
                final isOver = remaining < 0;
                return AuraCard(
                  emoji: isOver ? '⚠️' : '📊',
                  title: isOver
                      ? 'Bütçeyi ${-remaining} kcal aştın!'
                      : 'Kalan: $remaining kcal',
                  borderColor:
                      isOver ? AppTheme.statRed : AppTheme.secondaryAccent,
                );
              }),
              AuraCard(
                emoji: '📊',
                title:
                    'Protein: ${result.protein.toStringAsFixed(1)}g | Karb: ${result.carbs.toStringAsFixed(1)}g | Yağ: ${result.fat.toStringAsFixed(1)}g',
                borderColor: AppTheme.secondaryAccent,
              ),
              if (result.aiAdvice.isNotEmpty)
                AuraCard(
                  emoji: '💡',
                  title: 'Tavsiye: ${result.aiAdvice}',
                  borderColor: AppTheme.primaryAccent,
                ),
              const SizedBox(height: 16),

              // Save button
              GestureDetector(
                onTap: isSaving ? null : _saveMeal,
                child: Container(
                  height: 52,
                  decoration: AppTheme.gradientButton(radius: 12),
                  child: Center(
                    child: isSaving 
                        ? const SizedBox(
                            height: 24, 
                            width: 24, 
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                          )
                        : Text(
                            'Kaydet',
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
            
            const SizedBox(height: 32),
            
            // Past Scans Section
            pastScansAsyc.when(
              data: (meals) {
                if (meals.isEmpty) return const SizedBox.shrink();
                
                return Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: Text(
                      'Eski Taratmalar',
                      style: GoogleFonts.poppins(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textWhite,
                      ),
                    ),
                    children: [
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 140,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: meals.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 12),
                          itemBuilder: (context, index) {
                            final meal = meals[index];
                            return Container(
                              width: 120,
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackground,
                                borderRadius: BorderRadius.circular(AppTheme.cardBorderRadius),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(AppTheme.cardBorderRadius),
                                      ),
                                      child: meal.imageUrl.isNotEmpty
                                          ? Image.network(
                                              meal.imageUrl,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              color: Colors.grey.withAlpha(30),
                                              child: const Icon(Icons.fastfood, color: Colors.grey),
                                            ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          meal.detectedFood,
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppTheme.textWhite,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          '${meal.calories} kcal',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10,
                                            color: AppTheme.secondaryAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (e, st) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
