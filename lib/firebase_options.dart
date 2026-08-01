import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
      default:
        return android;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCu9zcPmJVvimuqaJKEgxHs5K5v_yFowqI',
    appId: '1:317702297035:web:demo',
    messagingSenderId: '317702297035',
    projectId: 'otelcim-7f0ba',
    authDomain: 'otelcim-7f0ba.firebaseapp.com',
    storageBucket: 'otelcim-7f0ba.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCu9zcPmJVvimuqaJKEgxHs5K5v_yFowqI',
    appId: '1:317702297035:android:1e5a05db8fb1d67b6fd24e',
    messagingSenderId: '317702297035',
    projectId: 'otelcim-7f0ba',
    storageBucket: 'otelcim-7f0ba.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCu9zcPmJVvimuqaJKEgxHs5K5v_yFowqI',
    appId: '1:317702297035:ios:demo',
    messagingSenderId: '317702297035',
    projectId: 'otelcim-7f0ba',
    storageBucket: 'otelcim-7f0ba.firebasestorage.app',
    iosBundleId: 'com.example.otelcim',
  );
}
