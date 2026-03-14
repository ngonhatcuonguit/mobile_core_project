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
  final double? ngG;    // Làm ngoài giờ
  final double? ngG2;   // Làm ngoài giờ loại 2
  final double? nL;     // Nghỉ lễ
  final double? bL;     // Bù lễ
  final double? b;      // Bệnh
  final double? p;      // Phép năm
  final double? pr;     // Phép riêng
  final double? ro;     // Nghỉ không lương
  final double? sickLeave; // Nghỉ ốm (other)
  final double? n;      // Nghỉ không phép
  final double? tN;     // Tai nạn
  final double? hT;     // Nghỉ hàng tuần (weekend)
  final double? ca3;    // Ca 3
  final double? cDC;    // Cách điều chỉnh
  final double? o;      // Nghỉ ốm
  final double? tS;     // Thai sản
  final double wd;      // Working days fraction
  final double? numHour;
  final double? numHourExtra;
  final String? note;
  final bool isDefault;
  final List<CheckingPointEntity> checkingPoints;

  const TimeSheetDataEntity({
    required this.dateWorking,
    this.ngG,
    this.ngG2,
    this.nL,
    this.bL,
    this.b,
    this.p,
    this.pr,
    this.ro,
    this.sickLeave,
    this.n,
    this.tN,
    this.hT,
    this.ca3,
    this.cDC,
    this.o,
    this.tS,
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
        ngG, ngG2, nL, bL, b, p, pr, ro, sickLeave, n, tN, hT, ca3, cDC, o, tS,
        wd, numHour, numHourExtra, note, isDefault, checkingPoints,
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

