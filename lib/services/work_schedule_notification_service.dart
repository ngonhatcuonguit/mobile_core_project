import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_core_project/data/models/work_schedule/work_schedule_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

/// Service quản lý notification cho work schedule:
/// - Nhắc check-in trước X phút
/// - Nhắc check-out trước X phút  
/// - Cảnh báo đi trễ (5 phút sau giờ check-in nếu chưa ignore)
/// - Cảnh báo tăng ca (sau giờ check-out)
class WorkScheduleNotificationService {
  WorkScheduleNotificationService._();
  static final WorkScheduleNotificationService instance = WorkScheduleNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  // Notification IDs (để cancel/update sau này)
  static const int _baseCheckInReminderId = 1000;
  static const int _baseCheckOutReminderId = 2000;
  static const int _baseLateAlertId = 3000;
  static const int _baseOvertimeAlertId = 4000;

  // SharedPreferences keys để track ignore state
  static const String _ignoreCheckInKey = 'ignored_checkin_noti';

  // ─── Initialization ────────────────────────────────────────────────────────
  Future<void> initialize() async {
    if (_initialized) return;

    // Init timezone database
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

    // Android settings
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    
    // iOS settings
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create high-priority channel for Android
    const channel = AndroidNotificationChannel(
      'work_schedule_alerts',
      'Work Schedule Notifications',
      description: 'Nhắc nhở và cảnh báo liên quan đến lịch làm việc',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    _initialized = true;
    debugPrint('[WorkScheduleNoti] Initialized');
  }

  // ─── Notification tap handler ──────────────────────────────────────────────
  void _onNotificationTapped(NotificationResponse response) {
    final payload = response.payload;
    debugPrint('[WorkScheduleNoti] Tapped: $payload');
    
    // Parse payload để xử lý action
    if (payload != null) {
      if (payload.startsWith('checkin_reminder')) {
        // Mark as ignored trong 10 phút
        _markCheckInReminderIgnored();
      }
      // TODO: Navigate đến màn check-in/out
    }
  }

  // ─── Schedule all notifications from work schedule ────────────────────────
  /// Gọi hàm này mỗi khi work schedule được save/update
  Future<void> scheduleFromWorkSchedule(WorkScheduleModel schedule) async {
    if (!_initialized) await initialize();

    // Cancel all existing notifications trước
    await cancelAll();

    final reminder = schedule.reminder;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Schedule cho 7 ngày tới
    for (int dayOffset = 0; dayOffset < 7; dayOffset++) {
      final date = today.add(Duration(days: dayOffset));
      final weekday = date.weekday; // 1=Mon...7=Sun

      // Lấy tất cả ca ACTIVE áp dụng cho ngày này
      final dayShifts = schedule.shifts
          .where((s) =>
              s.isActive &&
              (s.repeatType == 'daily' || s.appliedDays.contains(weekday)))
          .toList()
        ..sort((a, b) => a.checkInTime.compareTo(b.checkInTime));

      if (dayShifts.isEmpty) continue;

      // Schedule cho từng ca
      for (int i = 0; i < dayShifts.length; i++) {
        final shift = dayShifts[i];
        final shiftIndex = i;

        // Parse giờ check-in
        final checkInParts = shift.checkInTime.split(':');
        final checkInHour = int.parse(checkInParts[0]);
        final checkInMin = int.parse(checkInParts[1]);
        final checkInTime = DateTime(date.year, date.month, date.day, checkInHour, checkInMin);

        // Parse giờ check-out (có thể sang ngày hôm sau)
        final checkOutParts = shift.checkOutTime.split(':');
        final checkOutHour = int.parse(checkOutParts[0]);
        final checkOutMin = int.parse(checkOutParts[1]);
        DateTime checkOutTime = DateTime(date.year, date.month, date.day, checkOutHour, checkOutMin);
        if (shift.crossesMidnight) {
          checkOutTime = checkOutTime.add(const Duration(days: 1));
        }

        // 1. Check-in reminder
        if (reminder.checkInEnabled && checkInTime.isAfter(now)) {
          final reminderTime = checkInTime.subtract(Duration(minutes: reminder.checkInMinutesBefore));
          if (reminderTime.isAfter(now)) {
            await _scheduleNotification(
              id: _baseCheckInReminderId + dayOffset * 100 + shiftIndex,
              title: '⏰ Sắp đến giờ làm',
              body: 'Ca ${shift.name}: Check-in lúc ${shift.checkInTime}. Nhớ điểm danh!',
              scheduledTime: reminderTime,
              payload: 'checkin_reminder|${shift.id}|${date.toIso8601String()}',
              channelId: 'work_schedule_alerts',
              isAlert: false,
            );
          }

          // 2. Late alert (5 phút sau giờ check-in)
          if (reminder.lateAlertEnabled) {
            final lateAlertTime = checkInTime.add(const Duration(minutes: 5));
            if (lateAlertTime.isAfter(now)) {
              await _scheduleNotification(
                id: _baseLateAlertId + dayOffset * 100 + shiftIndex,
                title: '⚠️ Cảnh báo đi trễ',
                body: 'Bạn chưa check-in ca ${shift.name}. Vui lòng điểm danh ngay!',
                scheduledTime: lateAlertTime,
                payload: 'late_alert|${shift.id}|${date.toIso8601String()}',
                channelId: 'work_schedule_alerts',
                isAlert: true,
              );
            }
          }
        }

        // 3. Check-out reminder
        if (reminder.checkOutEnabled && checkOutTime.isAfter(now)) {
          final reminderTime = checkOutTime.subtract(Duration(minutes: reminder.checkOutMinutesBefore));
          if (reminderTime.isAfter(now)) {
            await _scheduleNotification(
              id: _baseCheckOutReminderId + dayOffset * 100 + shiftIndex,
              title: '🔔 Sắp hết giờ làm',
              body: 'Ca ${shift.name}: Check-out lúc ${shift.checkOutTime}. Chuẩn bị kết thúc ca!',
              scheduledTime: reminderTime,
              payload: 'checkout_reminder|${shift.id}|${date.toIso8601String()}',
              channelId: 'work_schedule_alerts',
              isAlert: false,
            );
          }
        }

        // 4. Overtime alert (15 phút sau giờ check-out)
        if (reminder.overtimeAlertEnabled && checkOutTime.isAfter(now)) {
          final overtimeAlertTime = checkOutTime.add(const Duration(minutes: 15));
          if (overtimeAlertTime.isAfter(now)) {
            await _scheduleNotification(
              id: _baseOvertimeAlertId + dayOffset * 100 + shiftIndex,
              title: '⏱️ Thông báo tăng ca',
              body: 'Bạn đang làm việc quá giờ ca ${shift.name}. Nhớ check-out!',
              scheduledTime: overtimeAlertTime,
              payload: 'overtime_alert|${shift.id}|${date.toIso8601String()}',
              channelId: 'work_schedule_alerts',
              isAlert: true,
            );
          }
        }
      }
    }

    debugPrint('[WorkScheduleNoti] Scheduled notifications for ${schedule.shifts.length} shift(s)');
  }

  // ─── Schedule single notification ──────────────────────────────────────────
  Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
    required String channelId,
    required bool isAlert, // true = âm thanh cảnh báo
  }) async {
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    await _notifications.zonedSchedule(
      id,
      title,
      body,
      tzScheduledTime,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          'Work Schedule Notifications',
          channelDescription: 'Nhắc nhở và cảnh báo liên quan đến lịch làm việc',
          importance: isAlert ? Importance.max : Importance.high,
          priority: isAlert ? Priority.max : Priority.high,
          playSound: true,
          sound: isAlert 
              ? const RawResourceAndroidNotificationSound('alert_sound') 
              : null,
          enableVibration: true,
          vibrationPattern: isAlert ? Int64List.fromList([0, 500, 200, 500]) : null,
          styleInformation: const BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: isAlert ? 'alert_sound.aiff' : null,
          interruptionLevel: isAlert 
              ? InterruptionLevel.timeSensitive 
              : InterruptionLevel.active,
        ),
      ),
      payload: payload,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );

    debugPrint('[WorkScheduleNoti] Scheduled #$id at $scheduledTime: $title');
  }

  // ─── Ignore check-in reminder (10 phút) ────────────────────────────────────
  Future<void> _markCheckInReminderIgnored() async {
    final prefs = await SharedPreferences.getInstance();
    final ignoreUntil = DateTime.now().add(const Duration(minutes: 10)).toIso8601String();
    await prefs.setString(_ignoreCheckInKey, ignoreUntil);
    debugPrint('[WorkScheduleNoti] Check-in reminder ignored until $ignoreUntil');
  }

  Future<bool> _isCheckInReminderIgnored() async {
    final prefs = await SharedPreferences.getInstance();
    final ignoreUntilStr = prefs.getString(_ignoreCheckInKey);
    if (ignoreUntilStr == null) return false;
    
    final ignoreUntil = DateTime.parse(ignoreUntilStr);
    return DateTime.now().isBefore(ignoreUntil);
  }

  // ─── Show immediate notification (dùng cho test) ───────────────────────────
  Future<void> showTestNotification() async {
    if (!_initialized) await initialize();

    await _notifications.show(
      99999,
      '🔔 Test Notification',
      'This is a test notification from Work Schedule Service',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'work_schedule_alerts',
          'Work Schedule Notifications',
          channelDescription: 'Nhắc nhở và cảnh báo liên quan đến lịch làm việc',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  // ─── Cancel notifications ───────────────────────────────────────────────────
  Future<void> cancelAll() async {
    await _notifications.cancelAll();
    debugPrint('[WorkScheduleNoti] Cancelled all notifications');
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  // ─── Get pending notifications (debug) ──────────────────────────────────────
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }
}

