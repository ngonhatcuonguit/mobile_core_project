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

  factory TimesheetModel.fromJson(Map<String, dynamic> json) {
    return TimesheetModel(
      year: json['YEAR'] ?? 0,
      month: json['MONTH'] ?? 0,
      employeeId: json['EMPLOYEE_ID'] ?? '',
      dayOfWeek: json['DAY_OF_WEEK'] ?? 0,
      sumDayOfMonth: json['SUM_DAY_OF_MONTH'] ?? 0,
      timeSheetData: (json['TIME_SHEET_DATA'] as List<dynamic>?)
              ?.map((e) => TimeSheetDataModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class TimeSheetDataModel extends TimeSheetDataEntity {
  const TimeSheetDataModel({
    required super.dateWorking,
    super.ngG,
    super.nL,
    super.p,
    super.pr,
    super.ro,
    super.hT,
    required super.wd,
    super.numHour,
    super.numHourExtra,
    super.note,
    required super.isDefault,
    required super.checkingPoints,
  });

  factory TimeSheetDataModel.fromJson(Map<String, dynamic> json) {
    return TimeSheetDataModel(
      dateWorking: DateTime.parse(json['DATE_WORKING']),
      ngG: (json['NgG'] as num?)?.toDouble(),
      nL: (json['NL'] as num?)?.toDouble(),
      p: (json['P'] as num?)?.toDouble(),
      pr: (json['Pr'] as num?)?.toDouble(),
      ro: (json['Ro'] as num?)?.toDouble(),
      hT: (json['HT'] as num?)?.toDouble(),
      wd: (json['Wd'] as num?)?.toDouble() ?? 0.0,
      numHour: (json['NUM_HOUR'] as num?)?.toDouble(),
      numHourExtra: (json['NUM_HOUR_EXTRA'] as num?)?.toDouble(),
      note: json['NOTE'],
      isDefault: json['IS_DEFAULT'] ?? false,
      checkingPoints: (json['CheckingPoint'] as List<dynamic>?)
              ?.map((e) => CheckingPointModel.fromJson(e))
              .toList() ??
          [],
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
      id: json['ID'] ?? 0,
      workingDate: DateTime.parse(json['WORKING_DATE']),
      employeeId: json['EMPLOYEE_ID'] ?? '',
      timeIn: json['TIME_IN'] != null ? DateTime.parse(json['TIME_IN']) : null,
      timeOut:
          json['TIME_OUT'] != null ? DateTime.parse(json['TIME_OUT']) : null,
      wd: (json['WD'] as num?)?.toDouble() ?? 0.0,
      ot: (json['OT'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

