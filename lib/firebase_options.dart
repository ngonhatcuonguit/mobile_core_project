// File generated manually from google-services.json / GoogleService-Info.plist
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Flavor được truyền vào lúc build qua --dart-define=FLAVOR=dev hoặc prod.
/// Mặc định là 'prod' nếu không truyền.
const String _flavor = String.fromEnvironment('FLAVOR', defaultValue: 'prod');

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
        // Chọn Firebase app dựa theo flavor
        return _flavor == 'dev' ? androidDev : android;
      case TargetPlatform.iOS:
        return _flavor == 'dev' ? iosDev : ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ─── PRODUCTION ─────────────────────────────────────────────────────────────
  // Values from android/app/google-services.json
  // Firebase app: com.digital.thp.my_thp
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDJBXStU4GJ-O7vRMfZF98ODPhX1vU0LOY',
    appId: '1:42808366470:android:788bfa8a80f1daf82d4807',
    messagingSenderId: '42808366470',
    projectId: 'mythp-9b465',
    storageBucket: 'mythp-9b465.firebasestorage.app',
  );

  // Values from ios/Runner/GoogleService-Info.plist
  // Firebase iOS app: vn.com.thp.payroll
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyADxsGoqXmG1MI6m0NO-xfz6Q6um-7MF0k',
    appId: '1:42808366470:ios:6229d65555e52ae22d4807',
    messagingSenderId: '42808366470',
    projectId: 'mythp-9b465',
    storageBucket: 'mythp-9b465.firebasestorage.app',
    iosBundleId: 'vn.com.thp.payroll',
  );

  // ─── DEVELOPMENT ─────────────────────────────────────────────────────────────
  // TODO: Sau khi đăng ký Firebase app 'com.digital.thp.my_thp.dev' trong Firebase Console,
  //       hãy cập nhật appId bên dưới với mobilesdk_app_id mới từ google-services.json.
  //       Hiện tại dev dùng chung Firebase app với prod (cùng appId) nên push notifications
  //       vẫn hoạt động bình thường. Chỉ cần thay appId sau khi có Firebase dev app riêng.
  //
  // Firebase app cần tạo: com.digital.thp.my_thp.dev
  // Steps: Firebase Console → Project Settings → Add Android app → package: com.digital.thp.my_thp.dev
  static const FirebaseOptions androidDev = FirebaseOptions(
    apiKey: 'AIzaSyDJBXStU4GJ-O7vRMfZF98ODPhX1vU0LOY', // TODO: thay bằng key của dev app nếu khác
    appId: '1:42808366470:android:788bfa8a80f1daf82d4807', // TODO: thay bằng mobilesdk_app_id của dev app
    messagingSenderId: '42808366470',
    projectId: 'mythp-9b465',
    storageBucket: 'mythp-9b465.firebasestorage.app',
  );

  static const FirebaseOptions iosDev = FirebaseOptions(
    apiKey: 'AIzaSyADxsGoqXmG1MI6m0NO-xfz6Q6um-7MF0k', // TODO: thay bằng key của iOS dev app nếu khác
    appId: '1:42808366470:ios:6229d65555e52ae22d4807', // TODO: thay bằng mobilesdk_app_id của iOS dev app
    messagingSenderId: '42808366470',
    projectId: 'mythp-9b465',
    storageBucket: 'mythp-9b465.firebasestorage.app',
    iosBundleId: 'vn.com.thp.payroll.dev', // TODO: thay bằng bundle ID iOS dev nếu khác
  );
}
