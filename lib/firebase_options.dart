// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
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
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyDfO0MzagARb1PgkIksRodh0AibOICrIUo',
    appId: '1:245931080224:web:2940f13de52ba612711a45',
    messagingSenderId: '245931080224',
    projectId: 'chat-d35d9',
    authDomain: 'chat-d35d9.firebaseapp.com',
    storageBucket: 'chat-d35d9.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA7PeiMZTevUZrlQJCactCKMVuHzQRbXIQ',
    appId: '1:245931080224:android:65ba5552589a3fe0711a45',
    messagingSenderId: '245931080224',
    projectId: 'chat-d35d9',
    storageBucket: 'chat-d35d9.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC6PcdVlFfzDUf6A57bDFC7pCjEOYCioyQ',
    appId: '1:245931080224:ios:91078a2d2fe7f2ba711a45',
    messagingSenderId: '245931080224',
    projectId: 'chat-d35d9',
    storageBucket: 'chat-d35d9.firebasestorage.app',
    iosBundleId: 'com.example.chat',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC6PcdVlFfzDUf6A57bDFC7pCjEOYCioyQ',
    appId: '1:245931080224:ios:91078a2d2fe7f2ba711a45',
    messagingSenderId: '245931080224',
    projectId: 'chat-d35d9',
    storageBucket: 'chat-d35d9.firebasestorage.app',
    iosBundleId: 'com.example.chat',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDfO0MzagARb1PgkIksRodh0AibOICrIUo',
    appId: '1:245931080224:web:1e6bb2aa70af4301711a45',
    messagingSenderId: '245931080224',
    projectId: 'chat-d35d9',
    authDomain: 'chat-d35d9.firebaseapp.com',
    storageBucket: 'chat-d35d9.firebasestorage.app',
  );
}
