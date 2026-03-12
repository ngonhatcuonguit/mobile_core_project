# API Logging Guide

## Keyword tìm kiếm trong Logcat

Tất cả các API call trong app đều được log với tag:

```
[THP_API]
```

## Cách dùng trong Android Studio / IntelliJ

Mở **Logcat** tab, nhập filter:

```
THP_API
```

Mỗi request sẽ in ra:
```
[THP_API] ▶ POST https://mythp-api.thp.com.vn/api/account/internallogin
[THP_API]   Body: {UserName: 43950, Password: ...}
[THP_API] ◀ 200 https://mythp-api.thp.com.vn/api/account/internallogin
[THP_API]   Response: {status: success, data: {...}}
```

## Lưu ý

- Log chỉ xuất hiện ở **debug mode** (`debugPrint` bị tắt tự động ở release).  
- Nếu dùng `adb` dòng lệnh: `adb logcat | grep THP_API`
- `pretty_dio_logger` trong `DioUtil` cũng log đầy đủ request/response nếu cần xem headers.

