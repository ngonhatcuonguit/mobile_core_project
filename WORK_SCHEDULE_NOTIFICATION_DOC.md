# Work Schedule Notification System

## Overview
Hệ thống nhắc nhở và cảnh báo tự động dựa trên lịch làm việc đã setup, sử dụng `flutter_local_notifications` để bắn notification đúng giờ kèm âm thanh.

---

## Features Implemented

### 1. ⏰ Nhắc nhở Check-in
- **Khi nào**: Trước giờ check-in X phút (config trong `WorkScheduleReminder.checkInMinutesBefore`)
- **Nội dung**: "⏰ Sắp đến giờ làm - Ca [Tên ca]: Check-in lúc [HH:mm]. Nhớ điểm danh!"
- **Âm thanh**: Default notification sound
- **Action**: Khi tap → mark as ignored trong 10 phút (dùng SharedPreferences)

### 2. 🔔 Nhắc nhở Check-out
- **Khi nào**: Trước giờ check-out X phút (config trong `checkOutMinutesBefore`)
- **Nội dung**: "🔔 Sắp hết giờ làm - Ca [Tên ca]: Check-out lúc [HH:mm]. Chuẩn bị kết thúc ca!"
- **Âm thanh**: Default notification sound

### 3. ⚠️ Cảnh báo đi trễ
- **Khi nào**: **5 phút SAU giờ check-in** nếu user chưa ignore notification nhắc nhở check-in
- **Nội dung**: "⚠️ Cảnh báo đi trễ - Bạn chưa check-in ca [Tên ca]. Vui lòng điểm danh ngay!"
- **Âm thanh**: **Custom alert sound** (`alert_sound.mp3` / `alert_sound.aiff`)
- **Vibration**: Pattern đặc biệt [0, 500ms, 200ms, 500ms]
- **Priority**: Max (hiện ngay cả khi DND mode)

### 4. ⏱️ Cảnh báo tăng ca
- **Khi nào**: 15 phút SAU giờ check-out
- **Nội dung**: "⏱️ Thông báo tăng ca - Bạn đang làm việc quá giờ ca [Tên ca]. Nhớ check-out!"
- **Âm thanh**: **Custom alert sound**
- **Priority**: Max

---

## Architecture

```
WorkScheduleSetupPage
    │
    ├─ Auto-save (debounce 700ms)
    │       └─> _autoSave()
    │               └─> WorkScheduleNotificationService.scheduleFromWorkSchedule()
    │
    └─ WorkScheduleNotificationService
            ├─ initialize() → setup timezone, channel, permissions
            ├─ scheduleFromWorkSchedule() → cancel old + schedule 7 days ahead
            │       └─ For each active shift:
            │           ├─ Check-in reminder (-X min)
            │           ├─ Late alert (+5 min)
            │           ├─ Check-out reminder (-X min)
            │           └─ Overtime alert (+15 min)
            │
            └─ _scheduleNotification() → zonedSchedule với timezone
```

---

## Logic Chi Tiết

### Định nghĩa "Đi trễ"
```
if (currentTime > checkInTime + 5 minutes) 
    AND user chưa ignore check-in reminder
    → Bắn cảnh báo đi trễ
```

**Cách track ignore:**
- SharedPreferences key: `ignored_checkin_noti`
- Value: ISO8601 timestamp (expire sau 10 phút)
- Check: `DateTime.now().isBefore(expireTime)`

### Schedule Window
- **Thời gian**: Schedule cho **7 ngày tới** (hôm nay + 6 ngày sau)
- **Lý do**: Tránh schedule quá xa → dễ miss nếu user tắt máy / reboot
- **Auto-refresh**: Mỗi lần save schedule → cancel all → re-schedule

### Ca làm qua đêm (crossesMidnight)
```dart
if (shift.crossesMidnight) {
  checkOutTime = checkOutTime.add(Duration(days: 1));
}
```
VD: Ca đêm 22:00 → 06:00 (+1) nghĩa là checkout thuộc ngày hôm sau.

### Chỉ schedule cho ca ACTIVE
```dart
dayShifts = shifts.where((s) => s.isActive && ...)
```
Ca bị pause (`isActive = false`) → không schedule notification.

---

## File Structure

```
lib/
├── services/
│   └── work_schedule_notification_service.dart   ← Core logic
├── presentation/pages/work_schedule/
│   └── work_schedule_setup_page.dart             ← Integration point
└── data/models/work_schedule/
    └── work_schedule_model.dart                  ← Data structure

android/app/src/main/res/raw/
└── alert_sound.mp3                                ← Custom sound (optional)

ios/Runner/Resources/
└── alert_sound.aiff                               ← iOS sound (optional)
```

---

## Android Permissions

`AndroidManifest.xml` đã được update với:
```xml
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM"/>
<uses-permission android:name="android.permission.USE_EXACT_ALARM"/>
```

**Android 12+ (API 31+)**: User cần grant "Alarms & reminders" permission thủ công trong Settings nếu bị deny.

---

## iOS Configuration

**Info.plist** (nếu chưa có):
```xml
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

---

## Testing

### Test ngay lập tức
```dart
await WorkScheduleNotificationService.instance.showTestNotification();
```

### Check pending notifications
```dart
final pending = await WorkScheduleNotificationService.instance.getPendingNotifications();
print('Pending: ${pending.length}');
for (var p in pending) {
  print('${p.id}: ${p.title} at ${p.body}');
}
```

### Cancel all
```dart
await WorkScheduleNotificationService.instance.cancelAll();
```

---

## Sound Files Setup

### Android
1. Tạo file `alert_sound.mp3` (hoặc `.ogg`)
2. Copy vào `android/app/src/main/res/raw/alert_sound.mp3`
3. Build lại app

**Recommended specs:**
- Format: MP3, 128kbps
- Duration: 2-3 giây
- Volume: Normalized

### iOS
1. Tạo file `alert_sound.aiff` (hoặc `.caf`, `.wav`)
2. Add vào Xcode project: Runner → Resources → alert_sound.aiff
3. Rebuild

**Convert MP3 → AIFF:**
```bash
afconvert -f caff -d LEI16 input.mp3 alert_sound.aiff
```

---

## Troubleshooting

| Issue | Giải pháp |
|-------|-----------|
| Notification không hiện | Check permission trong Settings → Notifications |
| Âm thanh không phát | Verify file tồn tại trong `res/raw/`, filename chính xác (không có extension) |
| Schedule không đúng giờ | Check timezone: `tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'))` |
| Android 12+ không schedule | User phải grant "Alarms & reminders" permission |
| Notification bị cancel sau reboot | Implement boot receiver (future enhancement) |

---

## API Integration (Future)

Khi backend cung cấp API:
```dart
// Trong _autoSave()
final response = await dio.patch(
  '/api/v1/work-schedules',
  data: model.toJson(),
);

if (response.statusCode == 200) {
  // Server đã nhận, có thể schedule server-side notification
}
```

Server cũng có thể:
- Bắn FCM push notification làm backup cho local notification
- Track attendance để tự động cancel "late alert" nếu user đã check-in
- Analytics: thống kê tỉ lệ ignore reminder, late rate, etc.

---

## Future Enhancements

- [ ] Boot receiver: Re-schedule notifications sau khi reboot
- [ ] Geofencing: Tự check-in khi đến công ty
- [ ] Smart snooze: Cho phép snooze 5/10/15 phút
- [ ] Rich notification: Action buttons (Check-in Now / Snooze)
- [ ] Notification history: Lưu log trong local DB
- [ ] Adaptive notification: Học thói quen user (ML)

