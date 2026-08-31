# Construction Plan

Ứng dụng Flutter hỗ trợ lập kế hoạch xây dựng, được tái cấu trúc từ phần core dùng chung của dự án cũ.

## Tính năng hiện tại

- Home với carousel dự án có hiệu ứng focus và tự chuyển, cùng danh sách dịch vụ xây dựng.
- Tab Vật liệu và Tính khối lượng dùng dữ liệu cục bộ, sẵn sàng mở rộng cho dự án mới.
- Profile với tùy chọn tiếng Việt/English và Light/Dark mode.
- Logo, launcher icon và splash screen của Construction Plan.
- Dữ liệu minh họa được đóng gói cục bộ; không đăng nhập, không gọi API, không Firebase.
- State ngôn ngữ và giao diện được lưu bằng `hydrated_bloc`.

## Chạy dự án

```bash
flutter pub get
flutter run --flavor dev -t lib/main_dev.dart
```

Build APK production:

```bash
./build-apk.sh prod release
```

Kiểm tra source:

```bash
flutter analyze
flutter test
```

## Entry points

- `lib/main.dart`: mặc định
- `lib/main_dev.dart`: flavor dev, hiển thị debug banner
- `lib/main_prod.dart`: flavor prod

Android application ID: `com.constructionplan.app`  
iOS bundle ID: `com.constructionplan.app`
