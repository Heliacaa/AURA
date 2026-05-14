import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StorageService {
  StorageService._();
  static final instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload meal image and return download URL
  Future<String> uploadMealImage({
    required String uid,
    required XFile imageFile,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('users/$uid/meals/$timestamp.jpg');
    final metadata = SettableMetadata(contentType: 'image/jpeg');

    // Use putData instead of putFile to ensure it works across all platforms (Windows, Web, etc.)
    final imageBytes = await imageFile.readAsBytes();
    final uploadTask = ref.putData(imageBytes, metadata);

    // Add a timeout to prevent infinite hanging
    final snapshot = await uploadTask.timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception(
        'Resim yükleme zaman aşımına uğradı. Lütfen internet bağlantını kontrol et.',
      ),
    );
    return await snapshot.ref.getDownloadURL();
  }
}
