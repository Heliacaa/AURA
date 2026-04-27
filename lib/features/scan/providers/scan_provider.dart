import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../shared/models/meal_model.dart';

/// Currently selected image
final scannedImageProvider = StateProvider<XFile?>((ref) => null);

/// Scan result from Gemini Vision
final scanResultProvider = StateProvider<MealModel?>((ref) => null);

/// Scan loading state
final scanLoadingProvider = StateProvider<bool>((ref) => false);
