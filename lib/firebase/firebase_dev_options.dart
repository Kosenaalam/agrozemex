import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your DEV/TEST Firebase apps.
class FirebaseDevOptions {
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
          'FirebaseDevOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'FirebaseDevOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA9Lez5L4CSlubK3QZC-6q-SYYexH6GYI4',
    appId: '1:783000159900:web:ea43248ac3b323c7d08f59',
    messagingSenderId: '783000159900',
    projectId: 'agrozemex',
    authDomain: 'agrozemex.firebaseapp.com',
    databaseURL: 'https://agrozemex-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'agrozemex.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBnS0NgsBcJjmCAajrdxsfBvH1Vw8UyS3w',
    appId: '1:783000159900:android:3af0d12e69137936d08f59',
    messagingSenderId: '783000159900',
    projectId: 'agrozemex',
    databaseURL: 'https://agrozemex-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'agrozemex.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCQAQnBkvYN2sH89u1EmcV45CyGh0-u08M',
    appId: '1:783000159900:ios:1b4f6cc48407a978d08f59',
    messagingSenderId: '783000159900',
    projectId: 'agrozemex',
    databaseURL: 'https://agrozemex-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'agrozemex.firebasestorage.app',
    iosBundleId: 'com.example.agrozemex',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCQAQnBkvYN2sH89u1EmcV45CyGh0-u08M',
    appId: '1:783000159900:ios:1b4f6cc48407a978d08f59',
    messagingSenderId: '783000159900',
    projectId: 'agrozemex',
    databaseURL: 'https://agrozemex-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'agrozemex.firebasestorage.app',
    iosBundleId: 'com.example.agrozemex',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyA9Lez5L4CSlubK3QZC-6q-SYYexH6GYI4',
    appId: '1:783000159900:web:10038d591bd49861d08f59',
    messagingSenderId: '783000159900',
    projectId: 'agrozemex',
    authDomain: 'agrozemex.firebaseapp.com',
    databaseURL: 'https://agrozemex-default-rtdb.asia-southeast1.firebasedatabase.app',
    storageBucket: 'agrozemex.firebasestorage.app',
  );
}
