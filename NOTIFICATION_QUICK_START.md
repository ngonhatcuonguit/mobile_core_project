# Hướng Dẫn Sử Dụng Notification System

## 🚀 Quick Start

### 1. Cài đặt dependencies
```bash
cd flutter_core_project
flutter pub get
```

### 2. Build app
```bash
# Android
flutter run

# iOS (cần Xcode)
cd ios && pod install && cd ..
flutter run
```

### 3. Test notification
1. Mở app → Vào màn "Work Schedule Setup"
2. Thêm ít nhất 1 ca làm việc
3. Enable "Nhắc nhở check-in" trong phần NHẮC NHỞ & CẢNH BÁO
4. Chọn thời gian nhắc trước: 5 phút
5. Lưu lại (auto-save)

**Debug mode**: Tap icon 🔔 ở góc phải top bar để test notification ngay lập tức.

---

## 📱 Grant Permissions

### Android 13+ (API 33+)
Khi lần đầu mở app, hệ thống sẽ hỏi:
- ✅ "Allow [App] to send you notifications?" → **Allow**

### Android 12+ (API 31+)
Cần grant "Alarms & reminders":
1. Settings → Apps → [Your App]
2. Permissions → Alarms & reminders → **Allow**

### iOS
Khi lần đầu schedule notification:
- ✅ "Allow notifications?" → **Allow**

---

## 🔔 Notification Flow

```
08:00 - Giờ check-in của ca
│
├─ 07:55 → 🔔 Nhắc nhở: "⏰ Sắp đến giờ làm"
│           (5 phút trước)
│
├─ 08:00 → [User should check-in]
│
└─ 08:05 → ⚠️ Cảnh báo: "⚠️ Cảnh báo đi trễ"
            (5 phút sau, nếu chưa ignore reminder)
            ► Âm thanh cảnh báo
            ► Vibration mạnh
            ► Priority Max
```

---

## 🎵 Custom Sound Setup (Optional)

### Tìm file âm thanh
- [Mixkit Free Sound Effects](https://mixkit.co/free-sound-effects/alarm/)
- [FreeSound.org](https://freesound.org/search/?q=alert)
- [NotificationSounds.com](https://notificationsounds.com/)

### Android
1. Download file `.mp3` hoặc `.ogg`
2. Rename thành `alert_sound.mp3`
3. Copy vào: `android/app/src/main/res/raw/alert_sound.mp3`
4. Rebuild app

### iOS
1. Convert sang `.aiff`:
   ```bash
   afconvert -f caff -d LEI16 input.mp3 alert_sound.aiff
   ```
2. Mở Xcode → Runner → Add Files to "Runner"
3. Chọn `alert_sound.aiff` → Copy items if needed
4. Rebuild

**Nếu không có custom sound**: Hệ thống dùng default notification sound.

---

## 🧪 Testing & Debug

### Test ngay lập tức
```dart
// Tap icon 🔔 trên top bar (debug mode only)
await WorkScheduleNotificationService.instance.showTestNotification();
```

### Xem pending notifications
```dart
final pending = await WorkScheduleNotificationService.instance
    .getPendingNotifications();
print('Scheduled: ${pending.length} notifications');
for (var n in pending) {
  print('${n.id}: ${n.title}');
}
```

### Cancel tất cả
```dart
await WorkScheduleNotificationService.instance.cancelAll();
```

---

## ⚙️ Configuration

### Thay đổi thời gian nhắc
1. Vào màn Work Schedule Setup
2. Section "NHẮC NHỞ & CẢNH BÁO"
3. Toggle bật/tắt từng loại
4. Dùng stepper để chọn: 5/10/15/20/30/45/60 phút

### Cảnh báo đi trễ
**Logic hardcode**: Luôn bắn sau **5 phút** nếu:
- `lateAlertEnabled = true`
- User chưa ignore check-in reminder

### Cảnh báo tăng ca
**Logic hardcode**: Luôn bắn sau **15 phút** check-out time nếu:
- `overtimeAlertEnabled = true`

---

## 🐛 Troubleshooting

### Notification không hiện
1. **Check permission**: Settings → Apps → Notifications → ✅ Enabled
2. **Android 12+**: Settings → Alarms & reminders → ✅ Allow
3. **Check schedule**: Tap 🔔 để test notification

### Âm thanh không phát
1. Verify file tồn tại: `res/raw/alert_sound.mp3`
2. Filename đúng (không có extension trong code)
3. Rebuild app
4. Check volume: Không ở chế độ im lặng/DND

### Notification bị cancel
- **Reboot**: Notification bị clear khi restart device
- **Giải pháp**: Re-schedule sau khi reboot (boot receiver - future enhancement)

### Notification schedule sai giờ
1. Check timezone: App dùng `Asia/Ho_Chi_Minh`
2. Check device time: Đúng múi giờ VN
3. Debug: Print `scheduledTime` trong log

---

## 📊 Analytics (Future)

Khi có API, server có thể track:
- Tỉ lệ ignore reminder
- Tỉ lệ late (so với scheduled time)
- Average check-in time vs scheduled time
- Overtime frequency

→ Optimize notification timing dựa trên behavior patterns.

---

## 🔐 Privacy

- Notification data chỉ lưu local (SharedPreferences)
- Không gửi lên server
- User có thể disable bất kỳ lúc nào
- Clear data: Uninstall app

---

## 📚 Related Docs

- [WORK_SCHEDULE_NOTIFICATION_DOC.md](./WORK_SCHEDULE_NOTIFICATION_DOC.md) - Kiến trúc chi tiết
- [WORK_SCHEDULE_DOC.md](./WORK_SCHEDULE_DOC.md) - Data model & logic
- [flutter_local_notifications](https://pub.dev/packages/flutter_local_notifications) - Package documentation

