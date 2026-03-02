import '../../../data/sources/datastate.dart';
import '../../entities/timesheet/timesheet_entity.dart';

abstract class TimesheetRepository {
  Future<DataState<TimesheetEntity>> getTimesheet(int year, int month);
}

