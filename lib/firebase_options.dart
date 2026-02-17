import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for ios - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyANLGB0zekmjlkwblUD_6eh09gebh1oLq4',
    appId: '1:135446987002:web:6e8f1c2d3a9b5e4f658943',
    messagingSenderId: '135446987002',
    projectId: 'smartlabesp32',
    databaseURL:
        'https://smartlabesp32-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'smartlabesp32.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyANLGB0zekmjlkwblUD_6eh09gebh1oLq4',
    appId: '1:135446987002:android:cfc16a2e9886f55a658943',
    messagingSenderId: '135446987002',
    projectId: 'smartlabesp32',
    databaseURL:
        'https://smartlabesp32-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'smartlabesp32.firebasestorage.app',
  );
}
