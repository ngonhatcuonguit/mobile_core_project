import 'package:flutter/foundation.dart';
import 'package:flutter_core_project/domain/entities/timesheet/timesheet_entity.dart';

class TimesheetModel extends TimesheetEntity {
  const TimesheetModel({
    required super.year,
    required super.month,
    required super.employeeId,
    required super.dayOfWeek,
    required super.sumDayOfMonth,
    required super.timeSheetData,
  });

  /// Parses the raw API response:
  ///   { "status": "success", "data": { "status": "success", "data": { ... } } }
  /// or the inner data map directly (used by mock).
  factory TimesheetModel.fromApiResponse(Map<String, dynamic> json) {
    // Unwrap: { status, data: { status, data: { YEAR, MONTH, ... } } }
    final outer = json['data'];
    final inner = outer is Map<String, dynamic> ? outer['data'] : null;
    final data  = inner is Map<String, dynamic> ? inner : json;

    debugPrint('[TIMESHEET_MODEL] outer.status=${json['status']} '
        'inner.status=${outer is Map ? outer['status'] : '?'} '
        'YEAR=${data['YEAR']} MONTH=${data['MONTH']} '
        'TS_count=${(data['TIME_SHEET_DATA'] as List?)?.length ?? 0}');

    return TimesheetModel.fromJson(data);
  }

  factory TimesheetModel.fromJson(Map<String, dynamic> json) {
    return TimesheetModel(
      year: json['YEAR'] ?? 0,
      month: json['MONTH'] ?? 0,
      employeeId: json['EMPLOYEE_ID'] ?? '',
      dayOfWeek: json['DAY_OF_WEEK'] ?? 0,
      sumDayOfMonth: json['SUM_DAY_OF_MONTH'] ?? 0,
      timeSheetData: (json['TIME_SHEET_DATA'] as List<dynamic>?)
              ?.map((e) => TimeSheetDataModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class TimeSheetDataModel extends TimeSheetDataEntity {
  const TimeSheetDataModel({
    required super.dateWorking,
    super.ngG,
    super.ngG2,
    super.nL,
    super.bL,
    super.b,
    super.p,
    super.pr,
    super.ro,
    super.sickLeave,
    super.n,
    super.tN,
    super.hT,
    super.ca3,
    super.cDC,
    super.o,
    super.tS,
    required super.wd,
    super.numHour,
    super.numHourExtra,
    super.note,
    required super.isDefault,
    required super.checkingPoints,
  });

  factory TimeSheetDataModel.fromJson(Map<String, dynamic> json) {
    // Helper: safely cast dynamic value to double (handles int, double, null)
    double? _d(String key) {
      final v = json[key];
      if (v == null) return null;
      return (v as num).toDouble();
    }

    // CheckingPoint có thể là null HOẶC List — xử lý an toàn cả hai
    List<CheckingPointModel> _parseCheckingPoints() {
      final raw = json['CheckingPoint'];
      if (raw == null) return [];
      if (raw is! List) return [];
      return raw
          .where((e) => e != null && e is Map)
          .map((e) {
            try {
              return CheckingPointModel.fromJson(e as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<CheckingPointModel>()
          .toList();
    }

    return TimeSheetDataModel(
      dateWorking: DateTime.parse(json['DATE_WORKING'] as String),
      ngG:       _d('NgG'),
      ngG2:      _d('NgG_2'),
      nL:        _d('NL'),
      bL:        _d('BL'),
      b:         _d('B'),
      p:         _d('P'),
      pr:        _d('Pr'),
      ro:        _d('Ro'),
      sickLeave: _d('SickLeave'),
      n:         _d('N'),
      tN:        _d('TN'),
      hT:        _d('HT'),
      ca3:       _d('Ca3'),
      cDC:       _d('CDC'),
      o:         _d('O'),
      tS:        _d('TS'),
      wd:        _d('Wd') ?? 0.0,
      numHour:      _d('NUM_HOUR'),
      numHourExtra: _d('NUM_HOUR_EXTRA'),
      note:      json['NOTE'] as String?,
      isDefault: json['IS_DEFAULT'] as bool? ?? false,
      checkingPoints: _parseCheckingPoints(),
    );
  }
}

class CheckingPointModel extends CheckingPointEntity {
  const CheckingPointModel({
    required super.id,
    required super.workingDate,
    required super.employeeId,
    super.timeIn,
    super.timeOut,
    required super.wd,
    required super.ot,
  });

  factory CheckingPointModel.fromJson(Map<String, dynamic> json) {
    return CheckingPointModel(
      id:          (json['ID'] as num?)?.toInt() ?? 0,
      workingDate: DateTime.parse(json['WORKING_DATE'] as String),
      employeeId:  json['EMPLOYEE_ID'] as String? ?? '',
      timeIn:  json['TIME_IN']  != null ? DateTime.parse(json['TIME_IN']  as String) : null,
      timeOut: json['TIME_OUT'] != null ? DateTime.parse(json['TIME_OUT'] as String) : null,
      wd: (json['WD'] as num?)?.toDouble() ?? 0.0,
      ot: (json['OT'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
