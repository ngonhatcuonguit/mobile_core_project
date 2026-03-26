import 'dart:convert';

// ─── Shift Entry ──────────────────────────────────────────────────────────────
/// A single shift template that knows which days it applies to and how often.
class WorkShiftEntry {
  final String id;
  final String name;
  final String checkInTime;
  final String checkOutTime;
  final bool crossesMidnight;
  final List<int> appliedDays;
  final String repeatType;
  final bool isActive; // toggle tạm dừng/kích hoạt ca

  const WorkShiftEntry({
    required this.id,
    required this.name,
    required this.checkInTime,
    required this.checkOutTime,
    this.crossesMidnight = false,
    required this.appliedDays,
    this.repeatType = 'weekly',
    this.isActive = true,
  });

  WorkShiftEntry copyWith({
    String? id,
    String? name,
    String? checkInTime,
    String? checkOutTime,
    bool? crossesMidnight,
    List<int>? appliedDays,
    String? repeatType,
    bool? isActive,
  }) =>
      WorkShiftEntry(
        id: id ?? this.id,
        name: name ?? this.name,
        checkInTime: checkInTime ?? this.checkInTime,
        checkOutTime: checkOutTime ?? this.checkOutTime,
        crossesMidnight: crossesMidnight ?? this.crossesMidnight,
        appliedDays: appliedDays ?? this.appliedDays,
        repeatType: repeatType ?? this.repeatType,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'check_in_time': checkInTime,
        'check_out_time': checkOutTime,
        'crosses_midnight': crossesMidnight,
        'applied_days': appliedDays,
        'repeat_type': repeatType,
        'is_active': isActive,
      };

  factory WorkShiftEntry.fromJson(Map<String, dynamic> j) => WorkShiftEntry(
        id: j['id'] as String,
        name: j['name'] as String,
        checkInTime: j['check_in_time'] as String,
        checkOutTime: j['check_out_time'] as String,
        crossesMidnight: (j['crosses_midnight'] as bool?) ?? false,
        appliedDays: List<int>.from((j['applied_days'] as List?) ?? []),
        repeatType: (j['repeat_type'] as String?) ?? 'weekly',
        isActive: (j['is_active'] as bool?) ?? true,
      );
}

// ─── Reminder ─────────────────────────────────────────────────────────────────
class WorkScheduleReminder {
  final bool checkInEnabled;
  final int checkInMinutesBefore;
  final bool checkOutEnabled;
  final int checkOutMinutesBefore;
  final bool lateAlertEnabled;
  final bool overtimeAlertEnabled;

  const WorkScheduleReminder({
    this.checkInEnabled = true,
    this.checkInMinutesBefore = 15,
    this.checkOutEnabled = false,
    this.checkOutMinutesBefore = 10,
    this.lateAlertEnabled = true,
    this.overtimeAlertEnabled = false,
  });

  WorkScheduleReminder copyWith({
    bool? checkInEnabled,
    int? checkInMinutesBefore,
    bool? checkOutEnabled,
    int? checkOutMinutesBefore,
    bool? lateAlertEnabled,
    bool? overtimeAlertEnabled,
  }) =>
      WorkScheduleReminder(
        checkInEnabled: checkInEnabled ?? this.checkInEnabled,
        checkInMinutesBefore: checkInMinutesBefore ?? this.checkInMinutesBefore,
        checkOutEnabled: checkOutEnabled ?? this.checkOutEnabled,
        checkOutMinutesBefore: checkOutMinutesBefore ?? this.checkOutMinutesBefore,
        lateAlertEnabled: lateAlertEnabled ?? this.lateAlertEnabled,
        overtimeAlertEnabled: overtimeAlertEnabled ?? this.overtimeAlertEnabled,
      );

  Map<String, dynamic> toJson() => {
        'check_in_enabled': checkInEnabled,
        'check_in_minutes_before': checkInMinutesBefore,
        'check_out_enabled': checkOutEnabled,
        'check_out_minutes_before': checkOutMinutesBefore,
        'late_alert_enabled': lateAlertEnabled,
        'overtime_alert_enabled': overtimeAlertEnabled,
      };

  factory WorkScheduleReminder.fromJson(Map<String, dynamic> j) =>
      WorkScheduleReminder(
        checkInEnabled: (j['check_in_enabled'] as bool?) ?? true,
        checkInMinutesBefore: (j['check_in_minutes_before'] as int?) ?? 15,
        checkOutEnabled: (j['check_out_enabled'] as bool?) ?? false,
        checkOutMinutesBefore: (j['check_out_minutes_before'] as int?) ?? 10,
        lateAlertEnabled: (j['late_alert_enabled'] as bool?) ?? true,
        overtimeAlertEnabled: (j['overtime_alert_enabled'] as bool?) ?? false,
      );
}

// ─── Root Model ───────────────────────────────────────────────────────────────
/// Payload POSTed to server.
/// Each WorkShiftEntry carries its own applied_days + repeat_type so the server
/// can build a per-day schedule for every employee independently.
class WorkScheduleModel {
  final String employeeId;
  final String employeeName;
  final String department;
  final String scheduleId;
  final String scheduleName;

  /// All shift entries — each knows which days & frequency it belongs to.
  final List<WorkShiftEntry> shifts;

  final WorkScheduleReminder reminder;
  final DateTime createdAt;
  final DateTime updatedAt;

  const WorkScheduleModel({
    required this.employeeId,
    required this.employeeName,
    required this.department,
    required this.scheduleId,
    required this.scheduleName,
    required this.shifts,
    required this.reminder,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Helper: returns all shifts that apply on a given ISO weekday (1–7).
  List<WorkShiftEntry> shiftsForDay(int isoWeekday) => shifts
      .where((s) =>
          s.repeatType == 'daily' ||
          s.appliedDays.contains(isoWeekday))
      .toList()
    ..sort((a, b) => a.checkInTime.compareTo(b.checkInTime));

  WorkScheduleModel copyWith({
    String? employeeId,
    String? employeeName,
    String? department,
    String? scheduleId,
    String? scheduleName,
    List<WorkShiftEntry>? shifts,
    WorkScheduleReminder? reminder,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      WorkScheduleModel(
        employeeId: employeeId ?? this.employeeId,
        employeeName: employeeName ?? this.employeeName,
        department: department ?? this.department,
        scheduleId: scheduleId ?? this.scheduleId,
        scheduleName: scheduleName ?? this.scheduleName,
        shifts: shifts ?? this.shifts,
        reminder: reminder ?? this.reminder,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'employee_id': employeeId,
        'employee_name': employeeName,
        'department': department,
        'schedule_id': scheduleId,
        'schedule_name': scheduleName,
        'shifts': shifts.map((s) => s.toJson()).toList(),
        'reminder': reminder.toJson(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };

  String toJsonString() => jsonEncode(toJson());

  factory WorkScheduleModel.fromJson(Map<String, dynamic> j) =>
      WorkScheduleModel(
        employeeId: j['employee_id'] as String,
        employeeName: j['employee_name'] as String,
        department: j['department'] as String,
        scheduleId: j['schedule_id'] as String,
        scheduleName: j['schedule_name'] as String,
        shifts: (j['shifts'] as List)
            .map((e) => WorkShiftEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        reminder: WorkScheduleReminder.fromJson(
            j['reminder'] as Map<String, dynamic>),
        createdAt: DateTime.parse(j['created_at'] as String),
        updatedAt: DateTime.parse(j['updated_at'] as String),
      );

  factory WorkScheduleModel.fromJsonString(String raw) =>
      WorkScheduleModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
}

/// SharedPreferences key
const String kWorkScheduleKey = 'work_schedule';

