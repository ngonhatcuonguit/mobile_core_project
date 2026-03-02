import 'package:equatable/equatable.dart';

class TimesheetEntity extends Equatable {
  final int year;
  final int month;
  final String employeeId;
  final int dayOfWeek;
  final int sumDayOfMonth;
  final List<TimeSheetDataEntity> timeSheetData;

  const TimesheetEntity({
    required this.year,
    required this.month,
    required this.employeeId,
    required this.dayOfWeek,
    required this.sumDayOfMonth,
    required this.timeSheetData,
  });

  @override
  List<Object?> get props => [
        year,
        month,
        employeeId,
        dayOfWeek,
        sumDayOfMonth,
        timeSheetData,
      ];
}

class TimeSheetDataEntity extends Equatable {
  final DateTime dateWorking;
  final double? ngG; // Nghỉ giữa giờ
  final double? nL; // Nghỉ lễ
  final double? p; // Phép
  final double? pr; // Phép riêng
  final double? ro; // Nghỉ không lương
  final double? hT; // Nghỉ HT (weekend)
  final double wd; // Working days
  final double? numHour;
  final double? numHourExtra;
  final String? note;
  final bool isDefault;
  final List<CheckingPointEntity> checkingPoints;

  const TimeSheetDataEntity({
    required this.dateWorking,
    this.ngG,
    this.nL,
    this.p,
    this.pr,
    this.ro,
    this.hT,
    required this.wd,
    this.numHour,
    this.numHourExtra,
    this.note,
    required this.isDefault,
    required this.checkingPoints,
  });

  @override
  List<Object?> get props => [
        dateWorking,
        ngG,
        nL,
        p,
        pr,
        ro,
        hT,
        wd,
        numHour,
        numHourExtra,
        note,
        isDefault,
        checkingPoints,
      ];
}

class CheckingPointEntity extends Equatable {
  final int id;
  final DateTime workingDate;
  final String employeeId;
  final DateTime? timeIn;
  final DateTime? timeOut;
  final double wd;
  final double ot;

  const CheckingPointEntity({
    required this.id,
    required this.workingDate,
    required this.employeeId,
    this.timeIn,
    this.timeOut,
    required this.wd,
    required this.ot,
  });

  @override
  List<Object?> get props => [
        id,
        workingDate,
        employeeId,
        timeIn,
        timeOut,
        wd,
        ot,
      ];
}

