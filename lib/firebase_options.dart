// File generated manually from google-services.json / GoogleService-Info.plist
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // Values from android/app/google-services.json
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDJBXStU4GJ-O7vRMfZF98ODPhX1vU0LOY',
    appId: '1:42808366470:android:788bfa8a80f1daf82d4807',
    messagingSenderId: '42808366470',
    projectId: 'mythp-9b465',
    storageBucket: 'mythp-9b465.firebasestorage.app',
  );

  // Values from ios/Runner/GoogleService-Info.plist
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyADxsGoqXmG1MI6m0NO-xfz6Q6um-7MF0k',
    appId: '1:42808366470:ios:75a96755f45d5c962d4807',
    messagingSenderId: '42808366470',
    projectId: 'mythp-9b465',
    storageBucket: 'mythp-9b465.firebasestorage.app',
    iosBundleId: 'com.digital.thp.mythpapp',
  );
}

