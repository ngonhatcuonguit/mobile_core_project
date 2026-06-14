import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
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
  static final WorkScheduleNotificationService instance =
      WorkScheduleNotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  bool _androidNotificationsEnabled = true;
  bool _androidCanScheduleExact = true;
  bool _androidExactAlarmRequestAttempted = false;

  static const String _channelId = 'work_schedule_alerts';
  static const String _channelName = 'Work Schedule Notifications';
  static const String _channelDescription =
      'Nhắc nhở và cảnh báo liên quan đến lịch làm việc';

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

    final androidPlugin = _androidPlugin;

    // Create high-priority channel for Android
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin?.createNotificationChannel(channel);

    _initialized = true;
    debugPrint('[WorkScheduleNoti] Initialized');
  }

  AndroidFlutterLocalNotificationsPlugin? get _androidPlugin =>
      _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> _ensureAndroidNotificationPermission(
    AndroidFlutterLocalNotificationsPlugin? androidPlugin,
  ) async {
    if (androidPlugin == null) return;

    try {
      final enabled = await androidPlugin
          .areNotificationsEnabled()
          .timeout(const Duration(seconds: 3));
      if (enabled == true) {
        _androidNotificationsEnabled = true;
        return;
      }

      final granted = await androidPlugin
          .requestNotificationsPermission()
          .timeout(const Duration(seconds: 15), onTimeout: () => false);
      _androidNotificationsEnabled = granted == true;

      debugPrint('[WorkScheduleNoti] Android notification permission: '
          '$_androidNotificationsEnabled');
    } catch (e, stack) {
      debugPrint('[WorkScheduleNoti] Android notification permission check '
          'failed: $e\n$stack');
    }
  }

  Future<void> _refreshAndroidExactAlarmPermission(
    AndroidFlutterLocalNotificationsPlugin? androidPlugin, {
    bool requestIfMissing = false,
  }) async {
    if (androidPlugin == null) return;

    try {
      final canScheduleExact = await androidPlugin
          .canScheduleExactNotifications()
          .timeout(const Duration(seconds: 3));
      if (canScheduleExact == true) {
        _androidCanScheduleExact = true;
        return;
      }

      if (!requestIfMissing || _androidExactAlarmRequestAttempted) {
        _androidCanScheduleExact = false;
        return;
      }

      _androidExactAlarmRequestAttempted = true;
      final granted = await androidPlugin
          .requestExactAlarmsPermission()
          .timeout(const Duration(seconds: 20), onTimeout: () => false);
      _androidCanScheduleExact = granted == true;

      debugPrint('[WorkScheduleNoti] Android exact alarm permission: '
          '$_androidCanScheduleExact');
    } catch (e, stack) {
      _androidCanScheduleExact = false;
      debugPrint('[WorkScheduleNoti] Android exact alarm permission check '
          'failed: $e\n$stack');
    }
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
    try {
      if (!_initialized) {
        await initialize().timeout(const Duration(seconds: 5));
      }
    } catch (e, stack) {
      debugPrint('[WorkScheduleNoti] Initialize failed: $e\n$stack');
      return;
    }

    final androidPlugin = _androidPlugin;
    await _ensureAndroidNotificationPermission(androidPlugin);
    await _refreshAndroidExactAlarmPermission(
      androidPlugin,
      requestIfMissing: true,
    );

    if (!_androidNotificationsEnabled) {
      debugPrint('[WorkScheduleNoti] Android notification permission is not '
          'granted; scheduled notifications may not be shown.');
    }

    // Cancel all existing notifications trước. Nếu cancel lỗi, vẫn thử schedule
    // notification mới để save flow không bị chặn bởi plugin/platform state.
    try {
      await cancelAll().timeout(const Duration(seconds: 5));
    } catch (e, stack) {
      debugPrint('[WorkScheduleNoti] cancelAll failed: $e\n$stack');
    }

    final reminder = schedule.reminder;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var scheduledCount = 0;

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
        final checkInTime =
            DateTime(date.year, date.month, date.day, checkInHour, checkInMin);

        // Parse giờ check-out (có thể sang ngày hôm sau)
        final checkOutParts = shift.checkOutTime.split(':');
        final checkOutHour = int.parse(checkOutParts[0]);
        final checkOutMin = int.parse(checkOutParts[1]);
        DateTime checkOutTime = DateTime(
            date.year, date.month, date.day, checkOutHour, checkOutMin);
        if (shift.crossesMidnight) {
          checkOutTime = checkOutTime.add(const Duration(days: 1));
        }

        // 1. Check-in reminder
        if (reminder.checkInEnabled && checkInTime.isAfter(now)) {
          final reminderTime = checkInTime
              .subtract(Duration(minutes: reminder.checkInMinutesBefore));
          if (reminderTime.isAfter(now)) {
            final scheduled = await _scheduleNotification(
              id: _baseCheckInReminderId + dayOffset * 100 + shiftIndex,
              title: '⏰ Sắp đến giờ làm',
              body:
                  'Ca ${shift.name}: Check-in lúc ${shift.checkInTime}. Nhớ điểm danh!',
              scheduledTime: reminderTime,
              payload: 'checkin_reminder|${shift.id}|${date.toIso8601String()}',
              channelId: _channelId,
              isAlert: false,
            );
            if (scheduled) scheduledCount++;
          }

          // 2. Late alert (5 phút sau giờ check-in)
          if (reminder.lateAlertEnabled) {
            final lateAlertTime = checkInTime.add(const Duration(minutes: 5));
            if (lateAlertTime.isAfter(now)) {
              final scheduled = await _scheduleNotification(
                id: _baseLateAlertId + dayOffset * 100 + shiftIndex,
                title: '⚠️ Cảnh báo đi trễ',
                body:
                    'Bạn chưa check-in ca ${shift.name}. Vui lòng điểm danh ngay!',
                scheduledTime: lateAlertTime,
                payload: 'late_alert|${shift.id}|${date.toIso8601String()}',
                channelId: _channelId,
                isAlert: true,
              );
              if (scheduled) scheduledCount++;
            }
          }
        }

        // 3. Check-out reminder
        if (reminder.checkOutEnabled && checkOutTime.isAfter(now)) {
          final reminderTime = checkOutTime
              .subtract(Duration(minutes: reminder.checkOutMinutesBefore));
          if (reminderTime.isAfter(now)) {
            final scheduled = await _scheduleNotification(
              id: _baseCheckOutReminderId + dayOffset * 100 + shiftIndex,
              title: '🔔 Sắp hết giờ làm',
              body:
                  'Ca ${shift.name}: Check-out lúc ${shift.checkOutTime}. Chuẩn bị kết thúc ca!',
              scheduledTime: reminderTime,
              payload:
                  'checkout_reminder|${shift.id}|${date.toIso8601String()}',
              channelId: _channelId,
              isAlert: false,
            );
            if (scheduled) scheduledCount++;
          }
        }

        // 4. Overtime alert (15 phút sau giờ check-out)
        if (reminder.overtimeAlertEnabled && checkOutTime.isAfter(now)) {
          final overtimeAlertTime =
              checkOutTime.add(const Duration(minutes: 15));
          if (overtimeAlertTime.isAfter(now)) {
            final scheduled = await _scheduleNotification(
              id: _baseOvertimeAlertId + dayOffset * 100 + shiftIndex,
              title: '⏱️ Thông báo tăng ca',
              body:
                  'Bạn đang làm việc quá giờ ca ${shift.name}. Nhớ check-out!',
              scheduledTime: overtimeAlertTime,
              payload: 'overtime_alert|${shift.id}|${date.toIso8601String()}',
              channelId: _channelId,
              isAlert: true,
            );
            if (scheduled) scheduledCount++;
          }
        }
      }
    }

    debugPrint('[WorkScheduleNoti] Scheduled $scheduledCount notification(s) '
        'for ${schedule.shifts.length} shift(s)');
  }

  // ─── Schedule single notification ──────────────────────────────────────────
  Future<bool> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    required String payload,
    required String channelId,
    required bool isAlert, // true = âm thanh cảnh báo
  }) async {
    final tzScheduledTime = tz.TZDateTime.from(scheduledTime, tz.local);

    Future<void> schedule({
      required AndroidScheduleMode mode,
      required bool customSound,
    }) {
      return _notifications
          .zonedSchedule(
            id,
            title,
            body,
            tzScheduledTime,
            _notificationDetails(
              channelId: channelId,
              isAlert: isAlert,
              customSound: customSound,
            ),
            payload: payload,
            androidScheduleMode: mode,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          )
          .timeout(const Duration(seconds: 4));
    }

    if (_androidCanScheduleExact) {
      try {
        await schedule(
          mode: AndroidScheduleMode.exactAllowWhileIdle,
          customSound: true,
        );
        debugPrint(
            '[WorkScheduleNoti] Scheduled #$id at $scheduledTime: $title');
        return true;
      } on PlatformException catch (e) {
        _androidCanScheduleExact = false;
        debugPrint('[WorkScheduleNoti] Exact schedule failed #$id: '
            '${e.code} ${e.message} — retry inexact');
      } catch (e) {
        debugPrint('[WorkScheduleNoti] Schedule failed #$id: '
            '$e — retry inexact');
      }
    } else {
      debugPrint('[WorkScheduleNoti] Exact alarm unavailable; scheduling '
          '#$id as inexact.');
    }

    try {
      await schedule(
        mode: AndroidScheduleMode.inexactAllowWhileIdle,
        customSound: true,
      );
      debugPrint('[WorkScheduleNoti] Scheduled #$id inexact at $scheduledTime');
      return true;
    } catch (e) {
      debugPrint('[WorkScheduleNoti] Inexact schedule failed #$id: '
          '$e — retry without custom sound');
    }

    try {
      await schedule(
        mode: AndroidScheduleMode.inexactAllowWhileIdle,
        customSound: false,
      );
      debugPrint('[WorkScheduleNoti] Scheduled #$id inexact/no-sound at '
          '$scheduledTime');
      return true;
    } catch (e, stack) {
      debugPrint('[WorkScheduleNoti] Skip notification #$id: $e\n$stack');
      return false;
    }
  }

  NotificationDetails _notificationDetails({
    required String channelId,
    required bool isAlert,
    required bool customSound,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: isAlert ? Importance.max : Importance.high,
        priority: isAlert ? Priority.max : Priority.high,
        playSound: true,
        sound: null,
        enableVibration: true,
        vibrationPattern:
            isAlert ? Int64List.fromList([0, 500, 200, 500]) : null,
        styleInformation: const BigTextStyleInformation(''),
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: isAlert && customSound ? 'alert_sound.aiff' : null,
        interruptionLevel: isAlert
            ? InterruptionLevel.timeSensitive
            : InterruptionLevel.active,
      ),
    );
  }

  Future<void> _markCheckInReminderIgnored() async {
    final prefs = await SharedPreferences.getInstance();
    final ignoreUntil =
        DateTime.now().add(const Duration(minutes: 10)).toIso8601String();
    await prefs.setString(_ignoreCheckInKey, ignoreUntil);
    debugPrint(
        '[WorkScheduleNoti] Check-in reminder ignored until $ignoreUntil');
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

    final androidPlugin = _androidPlugin;
    await _ensureAndroidNotificationPermission(androidPlugin);

    if (!_androidNotificationsEnabled) {
      debugPrint('[WorkScheduleNoti] Android notification permission is not '
          'granted; test notification may not be shown.');
    }

    await _notifications.show(
      99999,
      '🔔 Test Notification',
      'This is a test notification from Work Schedule Service',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
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
