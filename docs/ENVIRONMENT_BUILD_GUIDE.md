# 🏗️ Hướng dẫn Cấu hình Môi trường & Build — My THP

> Tài liệu này mô tả cách cấu hình domain, biến môi trường và các lệnh build/run
> cho 2 môi trường: **Dev** và **Prod**.

---

## 1. Tổng quan kiến trúc 2 môi trường

```
lib/
├── main_dev.dart        ← Entrypoint DEV  (load .env.dev)
├── main_prod.dart       ← Entrypoint PROD (load .env.prod)
└── core/configs/
    └── app_config.dart  ← Đọc biến từ .env, cung cấp cho toàn app

.env.dev                 ← Cấu hình môi trường Development
.env.prod                ← Cấu hình môi trường Production

android/app/build.gradle ← Flavor: dev | prod (tên app, applicationId)
ios/Runner/Info.plist    ← App display name
```

---

## 2. Cấu hình Domain (Base URL)

### 2.1 Chỉnh sửa file `.env.dev`

```dotenv
ENVIRONMENT=development
APP_TITLE=My THP (DEV)

# Thay bằng domain dev thực tế khi có server riêng
API_BASE_URL=https://dev-mythp-api.thp.com.vn

API_TIMEOUT_MS=30000
```

### 2.2 Chỉnh sửa file `.env.prod`

```dotenv
ENVIRONMENT=production
APP_TITLE=My THP

# Domain production chính thức
API_BASE_URL=https://mobile-app.thp.com.vn

API_TIMEOUT_MS=30000
```

> **Lưu ý:** Không commit các giá trị nhạy cảm (API key, secret) vào git.
> Thêm `.env.dev` và `.env.prod` vào `.gitignore` nếu cần bảo mật.

### 2.3 `AppConfig` — Đọc cấu hình trong code

```dart
import 'package:flutter_core_project/core/configs/app_config.dart';

// Lấy base URL hiện tại
final url = AppConfig.baseUrl;         // → từ API_BASE_URL trong .env

// Kiểm tra môi trường
if (AppConfig.isDev) {
  // Logic chỉ chạy ở DEV
}

// Timeout
final ms = AppConfig.timeoutMs;        // → từ API_TIMEOUT_MS trong .env
```

---

## 3. Thông tin 2 môi trường

| Thuộc tính | DEV | PROD |
|---|---|---|
| Entrypoint | `lib/main_dev.dart` | `lib/main_prod.dart` |
| Env file | `.env.dev` | `.env.prod` |
| App name | `My THP (DEV)` | `My THP` |
| Android App ID | `com.digital.thp.my_thp.dev` | `com.digital.thp.my_thp` |
| Android flavor | `dev` | `prod` |
| Debug banner | ✅ Hiển thị | ❌ Ẩn |
| Log API | Verbose | Minimal |

---

## 4. Lệnh Run (phát triển / debug)

### ▶️ Chạy môi trường DEV

```bash
flutter run --flavor dev -t lib/main_dev.dart
```

### ▶️ Chạy môi trường PROD

```bash
flutter run --flavor prod -t lib/main_prod.dart
```

---

## 5. Lệnh Build

### 🤖 Android — APK

```bash
# DEV
flutter build apk --flavor dev -t lib/main_dev.dart --debug
flutter build apk --flavor dev -t lib/main_dev.dart --release

# PROD
flutter build apk --flavor prod -t lib/main_prod.dart --release
```

### 🤖 Android — App Bundle (dùng để upload Google Play)

```bash
# DEV
flutter build appbundle --flavor dev -t lib/main_dev.dart

# PROD
flutter build appbundle --flavor prod -t lib/main_prod.dart --release
```

Output:
- DEV APK: `build/app/outputs/flutter-apk/app-dev-release.apk`
- PROD Bundle: `build/app/outputs/bundle/prodRelease/app-prod-release.aab`

### 🍎 iOS — Archive / IPA

```bash
# DEV
flutter build ios --flavor dev -t lib/main_dev.dart

# PROD
flutter build ios --flavor prod -t lib/main_prod.dart --release
```

> **Lưu ý iOS:** Cần tạo 2 Scheme riêng trong Xcode (`Runner-dev` / `Runner-prod`)
> tương ứng với 2 flavor nếu muốn build iOS flavor đầy đủ.
> Xem hướng dẫn thêm tại mục 7 bên dưới.

---

## 6. Cấu hình Signing Android (Release)

Thêm vào `android/app/build.gradle` trước `buildTypes`:

```groovy
signingConfigs {
    release {
        storeFile     file(System.getenv("KEYSTORE_PATH") ?: "keystore.jks")
        storePassword System.getenv("KEYSTORE_PASSWORD") ?: ""
        keyAlias      System.getenv("KEY_ALIAS") ?: ""
        keyPassword   System.getenv("KEY_PASSWORD") ?: ""
    }
}

buildTypes {
    release {
        signingConfig signingConfigs.release
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
    }
}
```

Đặt biến môi trường hoặc file `keystore.properties` (không commit lên git):

```properties
KEYSTORE_PATH=../my_thp_release.jks
KEYSTORE_PASSWORD=your_password
KEY_ALIAS=my_thp
KEY_PASSWORD=your_key_password
```

---

## 7. Cấu hình iOS Scheme cho Flavor (tùy chọn)

Để build iOS với `--flavor dev / prod`, thực hiện trong Xcode:

1. **Product → Scheme → Manage Schemes**
2. Duplicate scheme `Runner` → đặt tên `dev`
3. Trong scheme `dev`, tại **Build → Pre-actions**, thêm script:
   ```bash
   echo "FLUTTER_TARGET=lib/main_dev.dart" > ${SRCROOT}/Flutter/flutter_export_environment.sh
   ```
4. Lặp lại cho scheme `prod` với `main_prod.dart`

---

## 8. Checklist trước khi Release

- [ ] `API_BASE_URL` trong `.env.prod` trỏ đúng domain production
- [ ] `debugShowCheckedModeBanner: false` trong `main_prod.dart` ✅
- [ ] Signing config release đã cấu hình (không dùng debug key)
- [ ] Firebase `google-services.json` / `GoogleService-Info.plist` đúng environment
- [ ] Kiểm tra log `[THP_API] 🌐 Base URL` khi khởi động app xem URL đúng chưa
- [ ] Test API login + timesheet với token thực trên môi trường prod

---

## 9. Thay đổi Domain nhanh

Khi cần chuyển sang domain mới, **chỉ cần sửa 1 dòng** trong file `.env` tương ứng:

```dotenv
# Ví dụ đổi sang staging server
API_BASE_URL=https://staging-mythp-api.thp.com.vn
```

Không cần sửa bất kỳ file Dart nào. `AppConfig.baseUrl` sẽ tự động nhận giá trị mới.

