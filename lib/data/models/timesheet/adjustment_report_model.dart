import 'package:intl/intl.dart';

/// Request body gửi lên /api/employee
class AdjustmentReportRequest {
  final String workingDate;
  final String employeeId;
  final String? timeIn;
  final String? timeOut;
  final String? reason;
  final String reasonCode;
  final String? shift;

  const AdjustmentReportRequest({
    required this.workingDate,
    required this.employeeId,
    this.timeIn,
    this.timeOut,
    this.reason,
    required this.reasonCode,
    this.shift,
  });

  static final _fmt = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  factory AdjustmentReportRequest.fromFields({
    required DateTime workingDate,
    required String employeeId,
    DateTime? timeIn,
    DateTime? timeOut,
    String? reason,
    required String reasonCode,
    String? shift,
  }) {
    return AdjustmentReportRequest(
      workingDate: _fmt.format(DateTime(
        workingDate.year,
        workingDate.month,
        workingDate.day,
      )),
      employeeId: employeeId,
      timeIn: timeIn != null ? _fmt.format(timeIn) : null,
      timeOut: timeOut != null ? _fmt.format(timeOut) : null,
      reason: reason?.trim().isEmpty == true ? null : reason?.trim(),
      reasonCode: reasonCode,
      shift: shift,
    );
  }

  Map<String, dynamic> toJson() => {
        'WorkingDate': workingDate,
        'EmployeeID': employeeId,
        if (timeIn != null) 'TimeIn': timeIn,
        if (timeOut != null) 'TimeOut': timeOut,
        if (reason != null && reason!.isNotEmpty) 'Reason': reason,
        'ReasonCode': reasonCode,
        if (shift != null) 'Shift': shift,
      };
}

