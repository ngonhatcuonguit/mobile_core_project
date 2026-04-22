# 🔑 Hướng Dẫn Sử Dụng Keystore Mới

## Tóm Tắt Nhanh

✅ **Keystore đã được cấu hình thành công**

Bạn có thể ngay lập tức build release APK hoặc app bundle với keystore mới mà không cần cấu hình thêm gì.

## Build Lệnh

### 1. Build Release APK (Vanilla)
```bash
flutter build apk --release
```

**Output APK files**:
- `build/app/outputs/apk/dev/release/app-dev-release.apk` (DEV flavor)
- `build/app/outputs/apk/prod/release/app-prod-release.apk` (PROD flavor)

### 2. Build Release APK cho PROD flavor
```bash
flutter build apk --release -t lib/main_prod.dart
```

### 3. Build App Bundle (Android App Bundle - AAB)
```bash
flutter build appbundle --release
```

**Output**:
- `build/app/outputs/bundle/prodRelease/app-prod-release.aab`

## Thông Tin Keystore

| Thông Tin | Giá Trị |
|-----------|--------|
| **Keystore File** | `android/new-upload-key.jks` |
| **Keystore Password** | `THP@1001` |
| **Key Alias** | `upload` |
| **Key Password** | `THP@1001` |
| **Signature** | SHA256withRSA, 2048-bit |
| **Fingerprint (SHA1)** | `91:6F:B2:F1:A9:26:DE:C6:B2:74:C8:DD:F6:3F:CB:86:08:0D:93:1E` |

## Verification

✅ Build Test: PASSED
✅ Signature Verification: PASSED
✅ Both flavors (dev/prod): READY

## Lưu Ý Bảo Mật ⚠️

1. **Keystore file** được lưu tại: `android/new-upload-key.jks`
2. **Key.properties** được tự động ignore (xem `.gitignore`)
3. **Không commit credentials** - file `key.properties` sẽ không được commit vào Git
4. **Backup keystore** - Lưu trữ safe copy của `new-upload-key.jks` và password

## Troubleshooting

### Nếu gặp lỗi signing:
```bash
# Clean build
flutter clean

# Pub get
flutter pub get

# Rebuild
flutter build apk --release -v
```

### Kiểm tra keystore info:
```bash
keytool -list -v -keystore android/new-upload-key.jks -storepass THP@1001
```

### Verify APK signature:
```bash
jarsigner -verify -verbose build/app/outputs/apk/prod/release/app-prod-release.apk
```

---

**Configuration Date**: April 22, 2026
**Status**: ✅ PRODUCTION READY

