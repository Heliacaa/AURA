import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/models/meal_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../services/firestore_service.dart';

/// Currently selected image
final scannedImageProvider = StateProvider<XFile?>((ref) => null);

/// Scan result from Gemini Vision
final scanResultProvider = StateProvider<MealModel?>((ref) => null);

/// Scan loading state
final scanLoadingProvider = StateProvider<bool>((ref) => false);

/// Scan saving state
final scanSavingProvider = StateProvider<bool>((ref) => false);

/// Past scans stream
final pastScansProvider = StreamProvider<List<MealModel>>((ref) {
  final authUser = ref.watch(authStateProvider).valueOrNull;
  if (authUser == null) return const Stream.empty();
  return FirestoreService.instance.mealsStream(authUser.uid);
});
