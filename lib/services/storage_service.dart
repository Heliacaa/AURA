import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService._();
  static final instance = StorageService._();

  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload meal image and return download URL
  Future<String> uploadMealImage({
    required String uid,
    required File imageFile,
  }) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref().child('users/$uid/meals/$timestamp.jpg');

    final uploadTask = ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
