import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_core_project/data/sources/datastate.dart';
import 'package:flutter_core_project/domain/entities/timesheet/timesheet_entity.dart';
import 'package:flutter_core_project/domain/usecases/get_timesheet.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_event.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kPrefYear  = 'ts_selected_year';
const _kPrefMonth = 'ts_selected_month';

class RemoteTimesheetBloc extends Bloc<TimesheetEvent, TimesheetState> {
  final GetTimesheetUseCase _getTimesheetUseCase;

  /// In-memory cache: key = "YYYY-M"
  final Map<String, TimesheetEntity> _cache = {};

  RemoteTimesheetBloc(this._getTimesheetUseCase)
      : super(const TimesheetInitial()) {
    on<GetTimesheet>(_onGetTimesheet);
    on<ChangeMonth>(_onChangeMonth);
    on<SelectDay>(_onSelectDay);
    on<RestoreTimesheetFromCache>(_onRestoreFromCache);
  }

  // ─── helpers ────────────────────────────────────────────────────────────────

  String _key(int year, int month) => '$year-$month';

  bool _isFutureMonth(int year, int month) {
    final now = DateTime.now();
    return DateTime(year, month).isAfter(DateTime(now.year, now.month));
  }

  Future<void> _saveSelectedMonth(int year, int month) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_kPrefYear, year);
      await prefs.setInt(_kPrefMonth, month);
    } catch (e) {
      debugPrint('[TimesheetBloc] pref save error: $e');
    }
  }

  TimesheetEntity _emptyEntity(int year, int month) => TimesheetEntity(
        year: year,
        month: month,
        employeeId: '',
        dayOfWeek: DateTime(year, month, 1).weekday,
        sumDayOfMonth: DateUtils.getDaysInMonth(year, month),
        timeSheetData: const [],
      );

  DateTime? _autoSelectToday(int year, int month) {
    final now = DateTime.now();
    if (year == now.year && month == now.month) {
      return DateTime(now.year, now.month, now.day);
    }
    return null;
  }

  // ─── handlers ───────────────────────────────────────────────────────────────

  Future<void> _onGetTimesheet(
    GetTimesheet event,
    Emitter<TimesheetState> emit,
  ) async {
    await _saveSelectedMonth(event.year, event.month);

    // Tháng tương lai → trả rỗng ngay, không call API
    if (_isFutureMonth(event.year, event.month)) {
      emit(TimesheetLoaded(
        timesheet: _emptyEntity(event.year, event.month),
        selectedDate: null,
      ));
      return;
    }

    // Có cache → dùng luôn
    final cached = _cache[_key(event.year, event.month)];
    if (cached != null) {
      debugPrint('[TimesheetBloc] cache hit ${event.year}-${event.month}');
      emit(TimesheetLoaded(
        timesheet: cached,
        selectedDate: _autoSelectToday(event.year, event.month),
      ));
      return;
    }

    emit(const TimesheetLoading());

    final dataState = await _getTimesheetUseCase(
      params: GetTimesheetParams(year: event.year, month: event.month),
    );

    if (dataState is DataSuccess && dataState.data != null) {
      _cache[_key(event.year, event.month)] = dataState.data!;
      emit(TimesheetLoaded(
        timesheet: dataState.data!,
        selectedDate: _autoSelectToday(event.year, event.month),
      ));
    } else if (dataState is DataFailed) {
      emit(TimesheetError(dataState.error!));
    }
  }

  Future<void> _onChangeMonth(
    ChangeMonth event,
    Emitter<TimesheetState> emit,
  ) async {
    await _saveSelectedMonth(event.year, event.month);

    // Tháng tương lai
    if (_isFutureMonth(event.year, event.month)) {
      emit(TimesheetLoaded(
        timesheet: _emptyEntity(event.year, event.month),
        selectedDate: null,
      ));
      return;
    }

    // Có cache
    final cached = _cache[_key(event.year, event.month)];
    if (cached != null) {
      debugPrint('[TimesheetBloc] cache hit ${event.year}-${event.month}');
      emit(TimesheetLoaded(
        timesheet: cached,
        selectedDate: _autoSelectToday(event.year, event.month),
      ));
      return;
    }

    emit(const TimesheetLoading());

    final dataState = await _getTimesheetUseCase(
      params: GetTimesheetParams(year: event.year, month: event.month),
    );

    if (dataState is DataSuccess && dataState.data != null) {
      _cache[_key(event.year, event.month)] = dataState.data!;
      emit(TimesheetLoaded(
        timesheet: dataState.data!,
        selectedDate: _autoSelectToday(event.year, event.month),
      ));
    } else if (dataState is DataFailed) {
      emit(TimesheetError(dataState.error!));
    }
  }

  void _onSelectDay(
    SelectDay event,
    Emitter<TimesheetState> emit,
  ) {
    if (state is TimesheetLoaded) {
      final cur = state as TimesheetLoaded;
      emit(TimesheetLoaded(
        timesheet: cur.timesheet!,
        selectedDate: event.selectedDate,
      ));
    }
  }

  /// Khi user quay lại màn hình: nếu đang có state loaded thì giữ nguyên,
  /// không reload API.
  ///
  /// Khi app vừa bật lại (Bloc khởi tạo lại, state = Initial, in-memory cache rỗng):
  ///   → Luôn call API để lấy data tháng hiện tại (vì data có thể thay đổi trong ngày).
  Future<void> _onRestoreFromCache(
    RestoreTimesheetFromCache event,
    Emitter<TimesheetState> emit,
  ) async {
    // Navigate qua màn hình khác rồi quay lại → Bloc vẫn sống, giữ nguyên
    if (state is TimesheetLoaded) return;

    // App restart → Bloc khởi tạo lại, in-memory cache rỗng
    // → Luôn call API tháng hiện tại để đảm bảo data mới nhất
    final now = DateTime.now();
    debugPrint('[TimesheetBloc] app start → force reload ${now.year}-${now.month}');
    add(GetTimesheet(year: now.year, month: now.month));
  }
}
