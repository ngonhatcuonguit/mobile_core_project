# Construction Plan

Ứng dụng Flutter hỗ trợ lập kế hoạch xây dựng, được tái cấu trúc từ phần core dùng chung của dự án cũ.

## Tính năng hiện tại

- Home với carousel dự án có hiệu ứng focus và tự chuyển, cùng danh sách dịch vụ xây dựng.
- Tab Vật liệu và Tính khối lượng dùng dữ liệu cục bộ, sẵn sàng mở rộng cho dự án mới.
- Profile với tùy chọn tiếng Việt/English và Light/Dark mode.
- Logo, launcher icon và splash screen của Construction Plan.
- Kiến trúc BLoC/Cubit theo luồng data source, repository, use case và presentation.
- Dio, environment, token interceptor, SharedPreferences và SQLite đã sẵn sàng cho API.
- Firebase Cloud Messaging, local foreground notification và token sync đã cấu hình.
- State ngôn ngữ và giao diện được lưu bằng `hydrated_bloc`.

## Chạy dự án

Trong VS Code, chọn `Flutter (Dev)` ở Run and Debug. Trong Android Studio,
chọn shared run configuration `Flutter Dev`. Entry point `lib/main.dart` và
flavor mặc định đều trỏ tới môi trường Dev, nên nút Run tự sinh của IDE cũng
có thể chạy trực tiếp.

Với thiết bị Xiaomi/HyperOS, mở khóa điện thoại và chấp nhận hộp thoại
`Cài đặt qua USB` khi cài APK lần đầu.

```bash
tool/flutter_local.sh pub get
tool/flutter_local.sh run
```

Build APK production:

```bash
./build-apk.sh prod release
```

Kiểm tra source:

```bash
tool/flutter_local.sh analyze
tool/flutter_local.sh test
```

Chi tiết mở rộng API: [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)

Cấu hình credential FCM: [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)

## Entry points

- `lib/main.dart`: mặc định, môi trường dev
- `lib/main_dev.dart`: flavor dev, hiển thị debug banner
- `lib/main_prod.dart`: flavor prod

Android application ID: `com.constructionplan.app`  
iOS bundle ID: `com.constructionplan.app`
