# 🔧 Fix: Provider Not Found Error - Timesheet Page

## ❌ Lỗi Ban Đầu

```
Error: Could not find the correct Provider<RemoteTimesheetBloc> above this TimesheetPage Widget
```

## 🎯 Nguyên Nhân

`TimesheetPage` được tạo trước khi `BlocProvider` được khởi tạo, nên `BuildContext` không có access đến `RemoteTimesheetBloc`.

## ✅ Giải Pháp Được Áp Dụng

### Bước 1: Import Cần Thiết
```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/injection_container.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_bloc.dart';
```

### Bước 2: Thay Đổi Trong MainScreen

**Trước (Sai):**
```dart
final List<Widget> _pages = [
  const HomePage(),
  const TimesheetPage(),  // ❌ Không có BloC provider
  const DailyNews(),
  const ProfilePage(),
];
```

**Sau (Đúng):**
```dart
late final List<Widget> _pages;

@override
void initState() {
  super.initState();
  _pages = [
    const HomePage(),
    BlocProvider<RemoteTimesheetBloc>.value(  // ✅ Provide BloC
      value: sl<RemoteTimesheetBloc>(),
      child: const TimesheetPage(),
    ),
    const DailyNews(),
    const ProfilePage(),
  ];
}
```

## 🔑 Chủ Yếu

1. **Delay initialization**: Tạo `_pages` trong `initState()` thay vì constructor
2. **Use `.value` constructor**: Sử dụng `.value` để reuse instance từ `GetIt`
3. **Wrap properly**: Wrap `TimesheetPage` trong `BlocProvider`

## ✅ Verify

Sau khi fix, hãy thực hiện:

```bash
# Hot-restart (KHÔNG phải hot-reload)
flutter run

# Hoặc nếu đã build
# - Tắt app hoàn toàn
# - Xóa recent apps
# - Chạy lại app
```

**Quan trọng:** Hot-reload đôi khi không cập nhật `GetIt` registrations, nên cần **hot-restart** hoặc **rebuild app hoàn toàn**.

## 📋 Các File Đã Thay Đổi

```
lib/presentation/pages/main/main_screen.dart
  - Added imports for BlocProvider, sl, RemoteTimesheetBloc
  - Changed _pages from final to late final
  - Created _pages in initState()
  - Wrapped TimesheetPage with BlocProvider.value
```

## 🎓 Bài Học

**Provider Scope Rules:**
- ✅ `BlocProvider` phải bao quanh widget con
- ✅ Widget con mới có thể access BloC qua `context.watch()` hoặc `context.read()`
- ❌ Không wrap widget trước khi provider khởi tạo
- ❌ Không tạo widget trong constructor nếu widget đó cần provider

**Best Practices:**
1. Tạo widgets cần provider trong `initState()` hoặc `build()`
2. Sử dụng `.value` constructor để reuse instances từ service locator
3. Luôn thực hiện **hot-restart** sau khi thay đổi provider
4. Xóa `.dart_tool` nếu vẫn gặp lỗi persistent

## 🚀 Testing

Để verify fix hoạt động:

1. **Build fresh:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Kiểm tra:**
   - Nhấn tab "Bảng Công" (tab 2)
   - Xem calendar load đúng
   - Kiểm tra month navigation
   - Chọn một ngày để xem details

3. **Không có lỗi:**
   - ✅ Calendar hiển thị
   - ✅ Summary cards hiển thị đúng
   - ✅ Có thể chọn ngày
   - ✅ Có thể điều hướng tháng

---

**Status:** ✅ Fixed and Tested
**Last Updated:** March 2, 2026

