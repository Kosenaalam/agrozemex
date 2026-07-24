import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your PRODUCTION Firebase apps.
/// Make sure to replace placeholders with your actual production keys from the Firebase console.
class FirebaseProdOptions {
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
          'FirebaseProdOptions have not been configured for linux - '
          'you can configure this when you configure your production project.',
        );
      default:
        throw UnsupportedError(
          'FirebaseProdOptions are not supported for this platform.',
        );
    }
  }

  // TODO: Paste production credentials below after creating the 'agrozemex-prod' project in Firebase console

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'REPLACE_WITH_PROD_WEB_API_KEY',
    appId: 'REPLACE_WITH_PROD_WEB_APP_ID',
    messagingSenderId: 'REPLACE_WITH_PROD_WEB_MESSAGING_SENDER_ID',
    projectId: 'agrozemex-prod',
    authDomain: 'agrozemex-prod.firebaseapp.com',
    databaseURL: 'https://agrozemex-prod-default-rtdb.firebaseio.com',
    storageBucket: 'agrozemex-prod.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCsDIUoIutYvBUWIRJpVGBA2FXPONPV67Y',
    appId: '1:823519258644:android:582f6b44d1dbf9f1701f01',
    messagingSenderId: '823519258644',
    projectId: 'agrozemex-prod',
    databaseURL: 'https://agrozemex-prod-default-rtdb.firebaseio.com',
    storageBucket: 'agrozemex-prod.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'REPLACE_WITH_PROD_IOS_API_KEY',
    appId: 'REPLACE_WITH_PROD_IOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_PROD_IOS_MESSAGING_SENDER_ID',
    projectId: 'agrozemex-prod',
    databaseURL: 'https://agrozemex-prod-default-rtdb.firebaseio.com',
    storageBucket: 'agrozemex-prod.firebasestorage.app',
    iosBundleId: 'com.example.agrozemex',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'REPLACE_WITH_PROD_IOS_API_KEY',
    appId: 'REPLACE_WITH_PROD_IOS_APP_ID',
    messagingSenderId: 'REPLACE_WITH_PROD_IOS_MESSAGING_SENDER_ID',
    projectId: 'agrozemex-prod',
    databaseURL: 'https://agrozemex-prod-default-rtdb.firebaseio.com',
    storageBucket: 'agrozemex-prod.firebasestorage.app',
    iosBundleId: 'com.example.agrozemex',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'REPLACE_WITH_PROD_WEB_API_KEY',
    appId: 'REPLACE_WITH_PROD_WEB_APP_ID',
    messagingSenderId: 'REPLACE_WITH_PROD_WEB_MESSAGING_SENDER_ID',
    projectId: 'agrozemex-prod',
    authDomain: 'agrozemex-prod.firebaseapp.com',
    databaseURL: 'https://agrozemex-prod-default-rtdb.firebaseio.com',
    storageBucket: 'agrozemex-prod.firebasestorage.app',
  );
}
