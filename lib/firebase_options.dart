// This file is a placeholder. To generate the actual firebase_options.dart,
// run the following command in your terminal:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// This will create a proper firebase_options.dart with your Firebase project
// configuration for all platforms (iOS, Android, Web, macOS).
//
// Until then, the app will use this placeholder. Firebase features will not
// work until this file is properly generated.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return _web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _android;
      case TargetPlatform.iOS:
        return _ios;
      case TargetPlatform.macOS:
        return _macos;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions: $defaultTargetPlatform is not supported.',
        );
    }
  }

  // TODO: Replace these placeholder values with your actual Firebase config.
  // Run `flutterfire configure` to generate this file automatically.

  static const FirebaseOptions _android = FirebaseOptions(
    apiKey: 'YOUR-ANDROID-API-KEY',
    appId: 'YOUR-ANDROID-APP-ID',
    messagingSenderId: 'YOUR-MESSAGING-SENDER-ID',
    projectId: 'YOUR-PROJECT-ID',
    storageBucket: 'YOUR-STORAGE-BUCKET',
  );

  static const FirebaseOptions _ios = FirebaseOptions(
    apiKey: 'YOUR-IOS-API-KEY',
    appId: 'YOUR-IOS-APP-ID',
    messagingSenderId: 'YOUR-MESSAGING-SENDER-ID',
    projectId: 'YOUR-PROJECT-ID',
    storageBucket: 'YOUR-STORAGE-BUCKET',
    iosBundleId: 'com.example.aura',
  );

  static const FirebaseOptions _web = FirebaseOptions(
    apiKey: 'YOUR-WEB-API-KEY',
    appId: 'YOUR-WEB-APP-ID',
    messagingSenderId: 'YOUR-MESSAGING-SENDER-ID',
    projectId: 'YOUR-PROJECT-ID',
    storageBucket: 'YOUR-STORAGE-BUCKET',
    authDomain: 'YOUR-AUTH-DOMAIN',
  );

  static const FirebaseOptions _macos = FirebaseOptions(
    apiKey: 'YOUR-MACOS-API-KEY',
    appId: 'YOUR-MACOS-APP-ID',
    messagingSenderId: 'YOUR-MESSAGING-SENDER-ID',
    projectId: 'YOUR-PROJECT-ID',
    storageBucket: 'YOUR-STORAGE-BUCKET',
    iosBundleId: 'com.example.aura',
  );
}
