import 'package:flutter_core_project/data/sources/datastate.dart';
import 'package:flutter_core_project/domain/entities/timesheet/timesheet_entity.dart';
import 'package:flutter_core_project/domain/usecases/usecase.dart';
import '../repository/timesheet/timesheet_repository.dart';

class GetTimesheetUseCase implements UseCase<DataState<TimesheetEntity>, GetTimesheetParams> {
  final TimesheetRepository _timesheetRepository;

  GetTimesheetUseCase(this._timesheetRepository);

  @override
  Future<DataState<TimesheetEntity>> call({GetTimesheetParams? params}) {
    return _timesheetRepository.getTimesheet(
      params!.year,
      params.month,
    );
  }
}

class GetTimesheetParams {
  final int year;
  final int month;

  GetTimesheetParams({required this.year, required this.month});
}

