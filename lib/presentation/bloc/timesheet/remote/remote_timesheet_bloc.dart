import 'package:bloc/bloc.dart';
import 'package:flutter_core_project/data/sources/datastate.dart';
import 'package:flutter_core_project/domain/usecases/get_timesheet.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_event.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_state.dart';

class RemoteTimesheetBloc extends Bloc<TimesheetEvent, TimesheetState> {
  final GetTimesheetUseCase _getTimesheetUseCase;

  RemoteTimesheetBloc(this._getTimesheetUseCase)
      : super(const TimesheetInitial()) {
    on<GetTimesheet>(onGetTimesheet);
    on<ChangeMonth>(onChangeMonth);
    on<SelectDay>(onSelectDay);
  }

  void onGetTimesheet(
    GetTimesheet event,
    Emitter<TimesheetState> emit,
  ) async {
    emit(const TimesheetLoading());

    final dataState = await _getTimesheetUseCase(
      params: GetTimesheetParams(year: event.year, month: event.month),
    );

    if (dataState is DataSuccess && dataState.data != null) {
      // Auto-select current day if in current month
      final now = DateTime.now();
      DateTime? selectedDate;
      if (event.year == now.year && event.month == now.month) {
        selectedDate = DateTime(now.year, now.month, now.day);
      }
      emit(TimesheetLoaded(
        timesheet: dataState.data!,
        selectedDate: selectedDate,
      ));
    } else if (dataState is DataFailed) {
      emit(TimesheetError(dataState.error!));
    }
  }

  void onChangeMonth(
    ChangeMonth event,
    Emitter<TimesheetState> emit,
  ) async {
    emit(const TimesheetLoading());

    final dataState = await _getTimesheetUseCase(
      params: GetTimesheetParams(year: event.year, month: event.month),
    );

    if (dataState is DataSuccess && dataState.data != null) {
      emit(TimesheetLoaded(timesheet: dataState.data!));
    } else if (dataState is DataFailed) {
      emit(TimesheetError(dataState.error!));
    }
  }

  void onSelectDay(
    SelectDay event,
    Emitter<TimesheetState> emit,
  ) {
    if (state is TimesheetLoaded) {
      final currentState = state as TimesheetLoaded;
      emit(TimesheetLoaded(
        timesheet: currentState.timesheet!,
        selectedDate: event.selectedDate,
      ));
    }
  }
}

