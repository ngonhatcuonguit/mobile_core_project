abstract class TimesheetEvent {
  const TimesheetEvent();
}

class GetTimesheet extends TimesheetEvent {
  final int year;
  final int month;

  const GetTimesheet({required this.year, required this.month});
}

class ChangeMonth extends TimesheetEvent {
  final int year;
  final int month;

  const ChangeMonth({required this.year, required this.month});
}

class SelectDay extends TimesheetEvent {
  final DateTime selectedDate;

  const SelectDay({required this.selectedDate});
}

