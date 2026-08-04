# API Logging Guide

## Keyword tìm kiếm trong Logcat

API service THP dùng hai tag chính:

```
[THP_API]
[THP_DIO]
```

## Cách dùng trong Android Studio / IntelliJ

Mở **Logcat** tab, nhập filter:

```
THP_API
```

Mỗi request sẽ in ra:
```
[THP_API] ▶ POST https://mobile-app.thp.com.vn/api/account/internallogin
[THP_API]   Body: {UserName: 43950, Password: ...}
[THP_API] ◀ 200 https://mobile-app.thp.com.vn/api/account/internallogin
[THP_API]   Response: {status: success, data: {...}}
```

## Lưu ý

- Các API mới phải bọc log bằng `kDebugMode` để log chỉ xuất hiện ở **debug mode**.
- Luồng LevelUp chỉ log endpoint, HTTP status và số lượng item; không log email,
  token, thông tin thí sinh hoặc toàn bộ nội dung bài thi.
- Nếu dùng `adb` dòng lệnh:
  `adb logcat | grep -E 'THP_API|THP_DIO'`
- `pretty_dio_logger` trong nhánh `DioUtil` cũ hiện log request và request
  body; header và response body đang được tắt trong cấu hình.

## API Chấm điểm LevelUp

Các request metadata dùng cùng tag `[THP_API]`:

```text
GET /api/exam/listFactorys
GET /api/exam/listLevels
GET /api/exam/listLines
GET /api/exam/listMachines
GET /api/exam/listPractical
```

Ví dụ log an toàn:

```text
[THP_API] ▶ GET /api/exam/listPractical
[THP_API] ◀ 200 /api/exam/listPractical – 0 items
```
