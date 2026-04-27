import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
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

    final uploadTask = kIsWeb
        ? ref.putData(await imageFile.readAsBytes(), metadata)
        : ref.putFile(File(imageFile.path), metadata);

    final snapshot = await uploadTask;
    return await snapshot.ref.getDownloadURL();
  }
}
