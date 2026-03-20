import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_core_project/domain/entities/timesheet/timesheet_entity.dart';

abstract class TimesheetState extends Equatable {
  final TimesheetEntity? timesheet;
  final DioException? error;
  final DateTime? selectedDate;

  const TimesheetState({this.timesheet, this.error, this.selectedDate});

  @override
  List<Object?> get props => [timesheet, error, selectedDate];
}

class TimesheetInitial extends TimesheetState {
  const TimesheetInitial() : super();
}

class TimesheetLoading extends TimesheetState {
  const TimesheetLoading() : super();
}

class TimesheetLoaded extends TimesheetState {
  const TimesheetLoaded({
    required TimesheetEntity timesheet,
    DateTime? selectedDate,
  }) : super(timesheet: timesheet, selectedDate: selectedDate);
}

/// Đang call API nhưng vẫn giữ data cũ để UI không bị xóa trắng.
/// UI sẽ hiển thị overlay loading trong suốt đè lên content hiện tại.
class TimesheetRefreshing extends TimesheetState {
  const TimesheetRefreshing({
    required TimesheetEntity timesheet,
    DateTime? selectedDate,
  }) : super(timesheet: timesheet, selectedDate: selectedDate);
}

class TimesheetError extends TimesheetState {
  const TimesheetError(DioException error) : super(error: error);
}

