# 🔥 Firebase Setup Documentation — MyTHP App

> **Project:** `mythp-9b465`  
> **Flutter:** 3.19.x | **Dart:** 3.3.x  
> **Android package:** `com.digital.thp.my_thp` (prod) / `com.digital.thp.my_thp.dev` (dev)  
> **iOS Bundle ID:** `com.digital.thp.mythpapp`


Kiến trúc chuẩn push notification
Mobile App
↓
Get FCM Token
↓
Send token to Server
↓
Server lưu token
↓
Server gọi Firebase FCM API
↓
Firebase
↓
Push notification → Mobile

---

## 📋 Mục lục

1. [Tổng quan hệ thống](#1-tổng-quan-hệ-thống)
2. [Các thư viện đã cài đặt](#2-các-thư-viện-đã-cài-đặt)
3. [Cấu trúc file Firebase](#3-cấu-trúc-file-firebase)
4. [FCM — Push Notification](#4-fcm--push-notification)
5. [Firebase Analytics](#5-firebase-analytics)
6. [Firebase Crashlytics](#6-firebase-crashlytics)
7. [Hướng dẫn sử dụng trong code](#7-hướng-dẫn-sử-dụng-trong-code)
8. [Checklist trước khi publish Store](#8-checklist-trước-khi-publish-store)
9. [Lỗi thường gặp & cách xử lý](#9-lỗi-thường-gặp--cách-xử-lý)

---

## 1. Tổng quan hệ thống

```
MyTHP App
    │
    ├── main() / main_dev() / main_prod()
    │       └── FirebaseService.instance.initialize()
    │               ├── Firebase.initializeApp()          ← Firebase Core
    │               ├── _initCrashlytics()                ← Crashlytics
    │               ├── _initAnalytics()                  ← Analytics  
    │               └── _initFCM()                        ← FCM + Local Notif
    │
    ├── lib/services/firebase_service.dart   ← Singleton service trung tâm
    ├── lib/services/analytics_observer.dart ← Auto screen tracking
    │
    ├── android/app/google-services.json     ← Android config
    └── ios/Runner/GoogleService-Info.plist  ← iOS config
```

### Luồng hoạt động FCM:
```
Firebase Console
    │  (gửi push)
    ▼
FCM Server
    │
    ├─[App FOREGROUND]──► onMessage.listen() ──► LocalNotifications.show()
    ├─[App BACKGROUND]──► onBackgroundMessage() (background isolate)
    └─[App TERMINATED]──► getInitialMessage() (khi user mở app từ notif)
```

---

## 2. Các thư viện đã cài đặt

| Package | Phiên bản | Mục đích |
|---------|-----------|----------|
| `firebase_core` | ^2.32.0 | Khởi tạo Firebase, bắt buộc có |
| `firebase_messaging` | ^14.9.4 | FCM Push Notification |
| `firebase_analytics` | ^10.10.7 | Theo dõi hành vi người dùng |
| `firebase_crashlytics` | ^3.5.7 | Báo cáo crash & lỗi |
| `flutter_local_notifications` | ^16.3.3 | Hiển thị notification khi foreground |

> ⚠️ Các phiên bản này tương thích với **Flutter 3.19 / Dart 3.3**.  
> Khi nâng Flutter lên 3.22+, cần nâng Firebase lên ^3.x.x.

---

## 3. Cấu trúc file Firebase

### Android — `android/app/google-services.json`
- Chứa cấu hình cho **cả 2 package**: prod và dev
- Không được commit lên Git công khai (chứa API key)
- Nếu bị lộ: vào Firebase Console → Project Settings → Regenerate API key

### iOS — `ios/Runner/GoogleService-Info.plist`
- Bundle ID: `com.digital.thp.mythpapp`
- Cũng không được commit lên Git công khai

### Android Gradle — `android/build.gradle` (root)
```groovy
classpath 'com.google.gms:google-services:4.4.2'
classpath 'com.google.firebase:firebase-crashlytics-gradle:2.9.9'
```
> Dùng **google-services 4.4.x** và **crashlytics-gradle 2.9.x** vì project đang dùng  
> Gradle 7.5. Nếu nâng lên Gradle 8.x mới dùng crashlytics-gradle 3.x.

### Android Gradle — `android/app/build.gradle`
```groovy
plugins {
    id "com.google.gms.google-services"
    id "com.google.firebase.crashlytics"
}
```

---

## 4. FCM — Push Notification

### 4.1 Cách hoạt động

FCM hỗ trợ 3 trạng thái app:

| Trạng thái | Handler | Hành vi |
|------------|---------|---------|
| **Foreground** | `FirebaseMessaging.onMessage` | Dùng `flutter_local_notifications` để hiển thị |
| **Background** | `onBackgroundMessage()` | Chạy trong background isolate riêng |
| **Terminated** | `getInitialMessage()` | Lấy message khi user mở app từ notification |

### 4.2 Notification Channel (Android 8.0+)
Channel ID: `high_importance_channel`  
Được khai báo trong:
- `AndroidManifest.xml` — `com.google.firebase.messaging.default_notification_channel_id`
- `firebase_service.dart` — `AndroidNotificationChannel`

### 4.3 Lấy FCM Token để gửi Push cho từng user
```dart
// Lấy token
// final token = await FirebaseService.instance.getFCMToken();
// print('FCM Token: $token');

// Gửi token lên backend (gọi sau khi user đăng nhập thành công)
// await myApiService.updateFcmToken(userId, token);
```

### 4.4 Subscribe/Unsubscribe Topic (gửi broadcast)
```dart
// Đăng ký nhận thông báo theo chủ đề
// await FirebaseService.instance.subscribeToTopic('all_users');
// await FirebaseService.instance.subscribeToTopic('promotion');

// Hủy đăng ký
// await FirebaseService.instance.unsubscribeFromTopic('promotion');
```

### 4.5 Payload format (từ backend)
```json
{
  "to": "<FCM_TOKEN>",
  "notification": {
    "title": "Tiêu đề thông báo",
    "body": "Nội dung thông báo"
  },
  "data": {
    "route": "/timesheet",
    "id": "123"
  }
}
```

### 4.6 iOS — Yêu cầu thêm
Để FCM hoạt động trên iOS, cần thêm trong **Xcode**:
1. **Signing & Capabilities** → thêm **Push Notifications**
2. **Signing & Capabilities** → **Background Modes** → tick **Remote notifications**
3. Upload **APNs Authentication Key (.p8)** lên Firebase Console:  
   `Firebase Console → Project Settings → Cloud Messaging → APNs Authentication Key`

---

## 5. Firebase Analytics

### 5.1 Auto screen tracking
Đã tích hợp `AppFirebaseAnalyticsObserver` vào `MaterialApp.navigatorObservers`.  
Mỗi khi navigate sang route mới, tên màn hình tự động được ghi nhận.

### 5.2 Log custom event
```dart
// Log sự kiện đơn giản
// await FirebaseService.instance.logEvent('button_clicked');

// Log sự kiện với tham số
// await FirebaseService.instance.logEvent(
//   'view_timesheet',
//   parameters: {
//     'month': '2026-03',
//     'employee_id': '001',
//   },
// );

// Các event mặc định của Firebase (nên dùng)
// await FirebaseService.instance.analytics.logLogin(loginMethod: 'email');
// await FirebaseService.instance.analytics.logSignUp(signUpMethod: 'email');
```

### 5.3 Gắn User ID sau khi đăng nhập
```dart
// Sau khi login thành công
// await FirebaseService.instance.setUserId(user.id);

// Khi logout
// await FirebaseService.instance.setUserId(null);
```

### 5.4 Lưu ý quan trọng
- Analytics **TẮT trên debug build** (`kDebugMode = true`) để tránh ô nhiễm data
- Chỉ bật trên **release/prod** build
- Data thường hiển thị trên Firebase Console sau **24 giờ**
- Dùng **DebugView** để test real-time:  
  `firebase analytics:events --debug-device` hoặc bật DebugView trong Xcode

---

## 6. Firebase Crashlytics

### 6.1 Crash tự động được ghi nhận
Sau khi tích hợp, tất cả crash sẽ tự động gửi lên Firebase Console:
- `FlutterError.onError` → bắt lỗi Flutter framework
- `PlatformDispatcher.instance.onError` → bắt lỗi async/Zone

### 6.2 Ghi nhận lỗi thủ công
```dart
// try {
//   await someRiskyOperation();
// } catch (e, stack) {
//   // Ghi lỗi không fatal (app vẫn tiếp tục chạy)
//   await FirebaseService.instance.recordError(
//     e, stack,
//     reason: 'Failed to load timesheet data',
//     fatal: false,
//   );
// }
```

### 6.3 Ghi nhận lỗi fatal
```dart
// Lỗi nghiêm trọng (app crash)
// await FirebaseService.instance.recordError(
//   exception, stack,
//   fatal: true,
// );
```

### 6.4 Thêm thông tin user vào crash report
```dart
// Gắn userId để crash report dễ debug
// await FirebaseService.instance.setUserId('user_123');
//
// // Thêm custom key
// await FirebaseService.instance.crashlytics.setCustomKey('screen', 'HomeScreen');
// await FirebaseService.instance.crashlytics.setCustomKey('api_env', 'production');
```

### 6.5 Test Crashlytics
```dart
// Gây crash thủ công để test (chỉ dùng khi debug!)
// FirebaseCrashlytics.instance.crash();
```

### 6.6 Lưu ý
- Crashlytics **TẮT trên debug build**, chỉ bật trên release
- Crash report có thể delay **vài phút** mới xuất hiện trên Console
- Cần build **release APK/IPA** để test Crashlytics thực sự

---

## 7. Hướng dẫn sử dụng trong code

### 7.1 Import dùng ở bất kỳ đâu
```dart
import 'package:flutter_core_project/services/firebase_service.dart';

// Singleton — dùng trực tiếp không cần khởi tạo
final firebaseService = FirebaseService.instance;
```

### 7.2 Pattern xử lý deep link từ notification
Mở file `firebase_service.dart`, tìm hàm `_handleMessageOpenedApp` và thêm navigation:
```dart
void _handleMessageOpenedApp(RemoteMessage message) {
  final route = message.data['route'];
  if (route != null) {
    // Dùng NavigatorKey để navigate
    navigatorKey.currentState?.pushNamed(route);
  }
}
```

### 7.3 Đăng ký FCM token với backend sau khi login
```dart
// Trong AuthBloc hoặc AuthService, sau khi login thành công:
Future<void> onLoginSuccess(User user) async {
  // Gắn userId lên Analytics & Crashlytics
  await FirebaseService.instance.setUserId(user.id);
  
  // Lấy và gửi FCM token lên server
  final fcmToken = await FirebaseService.instance.getFCMToken();
  if (fcmToken != null) {
    await apiService.registerFcmToken(userId: user.id, token: fcmToken);
  }
  
  // Subscribe topics
  await FirebaseService.instance.subscribeToTopic('all_users');
}

// Khi logout:
Future<void> onLogout() async {
  await FirebaseService.instance.setUserId(null);
  await FirebaseService.instance.unsubscribeFromTopic('all_users');
}
```

---

## 8. Checklist trước khi publish Store

### ✅ Android (Google Play)
- [ ] `google-services.json` có đúng package name `com.digital.thp.my_thp`
- [ ] Build release: `flutter build appbundle --flavor prod --release`
- [ ] Crashlytics plugin `2.9.9` (tương thích Gradle 7.x)
- [ ] `multiDexEnabled true` trong `build.gradle` (đã có)
- [ ] `minSdkVersion 19` (Android 4.4+)
- [ ] `targetSdkVersion 33` trở lên
- [ ] Test push notification trên release APK

### ✅ iOS (App Store)
- [ ] `GoogleService-Info.plist` có đúng Bundle ID
- [ ] Thêm **Push Notifications** capability trong Xcode
- [ ] Tick **Remote notifications** trong Background Modes
- [ ] Upload **APNs Key (.p8)** lên Firebase Console
- [ ] `platform :ios, '13.0'` trong Podfile (đã set)
- [ ] Build release: `flutter build ipa --flavor prod --release`
- [ ] Không được bật `FirebaseAppDelegateProxyEnabled` nếu dùng manual setup

### ✅ Firebase Console
- [ ] Bật **Crashlytics** trong Firebase Console
- [ ] Bật **Analytics** trong Firebase Console
- [ ] Tạo FCM notification channel (tự động qua code)
- [ ] Test send push từ Firebase Console → Cloud Messaging

---

## 9. Lỗi thường gặp & cách xử lý

### ❌ `No matching client found for package name`
**Nguyên nhân:** `google-services.json` thiếu entry cho package name  
**Fix:** Thêm entry cho `com.digital.thp.my_thp.dev` vào `google-services.json` (đã fix)

### ❌ `Crashlytics Gradle plugin 3 requires Gradle 8.0`
**Nguyên nhân:** Dùng plugin version quá mới  
**Fix:** Dùng `firebase-crashlytics-gradle:2.9.9` (đã fix)

### ❌ `firebase_core_web requires SDK >=3.4.0`
**Nguyên nhân:** Firebase ^3.x yêu cầu Dart 3.4+, project đang dùng Dart 3.3  
**Fix:** Dùng `firebase_core: ^2.32.0` (đã fix)

### ❌ FCM token là null trên iOS
**Nguyên nhân:** APNS chưa được setup hoặc chạy trên simulator  
**Fix:** 
- Test trên thiết bị thật
- Upload APNs key lên Firebase Console
- Đảm bảo có Push Notifications capability trong Xcode

### ❌ Notification không hiện khi app foreground
**Nguyên nhân:** FCM mặc định không hiện notification khi foreground  
**Fix:** Đã xử lý qua `flutter_local_notifications` trong `_handleForegroundMessage()`

### ❌ Analytics data không xuất hiện
**Nguyên nhân:** Analytics tắt trên debug build  
**Fix:** Build release hoặc dùng Firebase DebugView:
```bash
# Android
adb shell setprop debug.firebase.analytics.app com.digital.thp.my_thp

# iOS (Xcode scheme arguments)
-FIRDebugEnabled
```

---

## 📁 Files liên quan

```
lib/
├── services/
│   ├── firebase_service.dart       ← Service chính (FCM + Analytics + Crashlytics)
│   └── analytics_observer.dart     ← Auto screen tracking
├── main.dart                       ← Entry point (gọi Firebase.init)
├── main_dev.dart                   ← Entry point dev
└── main_prod.dart                  ← Entry point prod

android/
├── build.gradle                    ← Google Services + Crashlytics classpath
└── app/
    ├── build.gradle                ← Apply plugins
    ├── google-services.json        ← Android Firebase config (prod + dev)
    └── src/main/AndroidManifest.xml← Permissions + FCM channel metadata

ios/
└── Runner/
    ├── AppDelegate.swift           ← Firebase.configure() + FCM setup
    ├── GoogleService-Info.plist    ← iOS Firebase config
    └── Info.plist                  ← UIBackgroundModes remote-notification
```

