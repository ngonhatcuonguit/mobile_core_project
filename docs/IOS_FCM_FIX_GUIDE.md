# 🔔 iOS FCM Push Notification — Hướng dẫn sửa lỗi hoàn chỉnh

**Ngày:** 8 April 2026  
**Trạng thái:** ✅ Code đã được fix — Cần thực hiện thêm các bước manual

---

## 📋 Tóm tắt vấn đề phát hiện

| # | Vấn đề | Mức độ | Trạng thái |
|---|--------|--------|-----------|
| 1 | **Bundle ID không khớp** (Xcode vs Firebase) | 🔴 CRITICAL | ✅ Fixed (code) + cần Apple Developer Portal |
| 2 | **Thiếu `didReceiveRemoteNotification` trong AppDelegate** | 🔴 CRITICAL | ✅ Fixed |
| 3 | **`aps-environment` hardcode `development`** cho mọi build | 🟡 QUAN TRỌNG | ✅ Fixed |
| 4 | **Foreground notification hiện 2 lần** trên iOS | 🟡 QUAN TRỌNG | ✅ Fixed |
| 5 | **APNs Key chưa upload** vào Firebase Console | 🔴 CRITICAL | ⚠️ Cần làm thủ công |

---

## ✅ Những gì đã được fix tự động trong code

### Fix 1 — `ios/Runner/AppDelegate.swift`
**Vấn đề:** Khi `FirebaseAppDelegateProxyEnabled = false` (đang set trong Info.plist), Firebase tắt method swizzling tự động. Cần gọi `Messaging.messaging().appDidReceiveMessage(userInfo)` thủ công để Firebase nhận được background/silent notifications.

**Đã thêm:**
```swift
// Bắt buộc khi FirebaseAppDelegateProxyEnabled = false
override func application(_ application: UIApplication,
                           didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                           fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
    Messaging.messaging().appDidReceiveMessage(userInfo)  // ← quan trọng
    super.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
}
```

### Fix 2 — `lib/services/firebase_service.dart`
**Vấn đề:** Khi app đang foreground trên iOS, `setForegroundNotificationPresentationOptions` đã hiện banner natively. Nhưng code cũ còn gọi thêm `_localNotifications.show()` → notification bị hiện **2 lần**.

**Đã sửa:** Chỉ dùng `_localNotifications.show()` cho Android. iOS dùng native FCM presentation.

### Fix 3 — `ios/Runner/Runner.entitlements`
**Vấn đề:** `aps-environment = development` hardcode cho mọi build. Release builds (TestFlight, App Store) cần `production` — hardcode sẽ override provisioning profile và notifications sẽ không hoạt động khi production.

**Đã sửa:** Xóa `aps-environment` → Xcode Automatic Signing tự gán đúng environment:
- Debug build → `development` (APNs Sandbox)
- Release build → `production` (APNs Production)

### Fix 4 — `ios/Runner.xcodeproj/project.pbxproj`
**Vấn đề:** Bundle ID trong Xcode (`vn.com.thp.payroll`) **không khớp** với Firebase iOS app (`com.digital.thp.mythpapp`). Đây là **nguyên nhân chính** iOS không nhận được push notification.

**Đã sửa:** Cập nhật tất cả Runner build configurations:
```
vn.com.thp.payroll  →  com.digital.thp.mythpapp
```

---

## ⚠️ Các bước MANUAL bắt buộc phải thực hiện

### BƯỚC 1 — Apple Developer Portal: Tạo App ID với Push Notifications

> 🔗 https://developer.apple.com/account/resources/identifiers/list

1. Đăng nhập Apple Developer (Team: **D4V3H8CCZ9**)
2. **Identifiers** → `+` → chọn **App IDs**
3. Nếu `com.digital.thp.mythpapp` **chưa tồn tại**:
   - Description: `My THP`
   - Bundle ID (Explicit): `com.digital.thp.mythpapp`
   - Capabilities: ✅ **Push Notifications**
   - Click **Continue** → **Register**
4. Nếu `com.digital.thp.mythpapp` **đã tồn tại**:
   - Click vào nó → Edit
   - Đảm bảo ✅ **Push Notifications** được bật
   - Save

---

### BƯỚC 2 — Firebase Console: Upload APNs Auth Key (p8)

> 🔗 https://console.firebase.google.com → Project `mythp-9b465`

**2a. Tạo APNs Auth Key từ Apple Developer Portal (nếu chưa có)**

1. Apple Developer → **Certificates, Identifiers & Profiles** → **Keys**
2. Click `+` → tên: `FCM Push Key`
3. Bật ✅ **Apple Push Notifications service (APNs)**
4. **Continue** → **Register** → **Download** file `.p8`
5. ⚠️ **Lưu ngay** — chỉ download được 1 lần!
6. Ghi lại **Key ID** (hiển thị sau khi tạo)

**2b. Upload key vào Firebase Console**

1. Firebase Console → Project `mythp-9b465` → ⚙️ **Project Settings**
2. Tab **Cloud Messaging**
3. Mục **Apple app configuration** → chọn iOS app `com.digital.thp.mythpapp`
4. Mục **APNs authentication key** → click **Upload**
5. Chọn file `.p8` vừa download
6. Điền:
   - **Key ID**: (từ bước 2a)
   - **Team ID**: `D4V3H8CCZ9`
7. **Upload**

---

### BƯỚC 3 — Rebuild iOS App

Sau khi hoàn tất bước 1 và 2, rebuild:

```bash
cd ios
rm -rf Pods Podfile.lock
pod install
cd ..
flutter clean
flutter pub get
flutter run -t lib/main_prod.dart
```

---

### BƯỚC 4 — Test push notification qua Firebase Console

1. Mở Firebase Console → **Messaging** → **Create your first campaign**
2. **Firebase Notification messages** → **Create**
3. Điền:
   - **Notification title**: `Test Push`
   - **Notification text**: `iOS FCM test`
4. **Next** → Target: chọn app iOS hoặc nhập FCM token cụ thể
5. **Next** → **Next** → **Review** → **Publish**

**Debug: Kiểm tra trong Xcode Console:**
```
FCM Token: <your_fcm_token>
[APNs] ❌ Failed to register...  ← nếu có lỗi APNs
[FCM] Permission status: authorized  ← phải là authorized
```

---

## 🔍 Checklist đầy đủ trước khi test

```
✅ Fix 1: AppDelegate.swift — didReceiveRemoteNotification thêm vào
✅ Fix 2: firebase_service.dart — iOS foreground không dùng localNotifications
✅ Fix 3: Runner.entitlements — aps-environment đã bỏ (Xcode tự quản lý)
✅ Fix 4: project.pbxproj — Bundle ID = com.digital.thp.mythpapp

⬜ BƯỚC 1: Apple Developer Portal — App ID com.digital.thp.mythpapp có Push Notifications
⬜ BƯỚC 2: Firebase Console — APNs Auth Key (.p8) đã upload cho iOS app
⬜ BƯỚC 3: Rebuild iOS app (pod install + flutter clean)
⬜ BƯỚC 4: Test qua Firebase Console
```

---

## 🧐 Giải thích kỹ thuật — Tại sao iOS không nhận notification?

### Root Cause: Bundle ID Mismatch

```
Xcode builds app with:     vn.com.thp.payroll
iOS registers APNs with:   vn.com.thp.payroll  ← APNs token gắn với bundle này
Firebase iOS app has:      com.digital.thp.mythpapp
Firebase APNs creds for:   com.digital.thp.mythpapp

Khi gửi notification:
FCM token → Firebase → APNs (dùng creds của com.digital.thp.mythpapp)
                     ↓
APNs nhận request nhưng APNs token là của vn.com.thp.payroll
→ Delivery FAIL hoặc silent drop
```

### Sau khi fix:
```
Xcode builds app with:     com.digital.thp.mythpapp  ✅
iOS registers APNs with:   com.digital.thp.mythpapp  ✅
Firebase iOS app has:      com.digital.thp.mythpapp  ✅
Firebase APNs creds for:   com.digital.thp.mythpapp  ✅
→ Delivery SUCCESS ✅
```

---

## 🆘 Nếu vẫn không nhận được sau khi làm đủ các bước

### Kiểm tra permission
Thêm log trong Dart:
```dart
final settings = await FirebaseMessaging.instance.getNotificationSettings();
print('Authorization: ${settings.authorizationStatus}'); // phải là authorized
```

### Kiểm tra APNs token
```swift
// Trong didRegisterForRemoteNotificationsWithDeviceToken
print("[APNs] ✅ Token: \(deviceToken.map { String(format: "%02.2hhx", $0) }.joined())")
```

### Kiểm tra FCM token vs bundle ID
Chạy app trên device thật (không phải simulator — simulator không nhận push). 
Đảm bảo FCM token được in ra trong console.

### Common mistakes
| Lỗi | Nguyên nhân | Fix |
|-----|-------------|-----|
| Không nhận notification trên device thật | Simulator không hỗ trợ push | Dùng device thật |
| Nhận notification nhưng silent | `content-available: 1` mà không có `notification` body | Thêm notification payload |
| Notification chỉ xuất hiện khi app background | Foreground handling code bị lỗi | Kiểm tra `onMessage.listen` |
| "MismatchSenderId" error | GOOGLE_APP_ID trong plist sai | Download lại GoogleService-Info.plist |

