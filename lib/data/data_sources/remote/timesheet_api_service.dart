import 'package:dio/dio.dart';
import 'package:flutter_core_project/data/models/timesheet/timesheet_model.dart';
import 'package:retrofit/dio.dart';

class TimesheetApiService {
  final Dio dio;

  TimesheetApiService(this.dio);

  Future<HttpResponse<TimesheetModel>> getTimesheet({
    required int year,
    required int month,
  }) async {
    // Mock data - simulating API response
    final mockData = _getMockTimesheetData(year, month);

    return HttpResponse(
      mockData,
      Response(
        requestOptions: RequestOptions(path: ''),
        statusCode: 200,
        data: mockData,
      ),
    );
  }

  TimesheetModel _getMockTimesheetData(int year, int month) {
    // Generate mock data for the requested month
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final List<Map<String, dynamic>> timeSheetDataList = [];

    for (int day = 1; day <= daysInMonth; day++) {
      final date = DateTime(year, month, day);
      final dayOfWeek = date.weekday;
      final isWeekend = dayOfWeek == 7;

      timeSheetDataList.add({
        "DATE_WORKING": date.toIso8601String(),
        "NgG": 0.0,
        "NgG_DC": null,
        "NL": (day == 16 || day == 17 || day == 18 || day == 19 || day == 20) ? 1.0 : null,
        "NL_DC": null,
        "BL": null,
        "B": null,
        "P": (day == 13) ? 1.0 : null,
        "Pr": null,
        "Ro": (day == 14 || day == 21) ? 1.0 : null,
        "SickLeave": null,
        "N": null,
        "TN": null,
        "HT": isWeekend ? 1.0 : null,
        "Ca3": 0.0,
        "Ca3_DC": null,
        "CDC": null,
        "O": null,
        "NUM_HOUR": (!isWeekend && day != 13 && day != 14 && day != 21 && !(day >= 16 && day <= 20)) ? 9.0 : null,
        "NUM_HOUR_EXTRA": null,
        "NOTE": "System chấm công tự động",
        "Wd": (!isWeekend && day != 13 && day != 14 && day != 21 && !(day >= 16 && day <= 20)) ? 1.0 : 0.0,
        "FML_GROUP_ID": "8",
        "IS_CALCULATED": "0",
        "Wd_OLD": null,
        "NgG_OLD": null,
        "NL_OLD": null,
        "Ca3_OLD": null,
        "IS_DEFAULT": true,
        "NgG_2": null,
        "NgG_2_OLD": null,
        "TS": null,
        "CheckingPoint": (!isWeekend && day != 13 && day != 14 && day != 21 && !(day >= 16 && day <= 20))
            ? [
                {
                  "ID": 2880000 + day,
                  "WORKING_DATE": date.toIso8601String(),
                  "EMPLOYEE_ID": "43950",
                  "TIME_IN": DateTime(year, month, day, 7, 50 + (day % 10)).toIso8601String(),
                  "TIME_OUT": DateTime(year, month, day, 17, 5 + (day % 10)).toIso8601String(),
                  "FML_GROUP_ID": "BD_VP_08H_HC_08-17",
                  "WD": 9.0,
                  "OT": 0.0,
                  "CA3": 0.0,
                  "CONG_WD": null,
                  "CONG_OT": null,
                  "CONG_CA3": null
                }
              ]
            : [
                {
                  "ID": 2880000 + day,
                  "WORKING_DATE": date.toIso8601String(),
                  "EMPLOYEE_ID": "43950",
                  "TIME_IN": date.toIso8601String(),
                  "TIME_OUT": null,
                  "FML_GROUP_ID": "",
                  "WD": 0.0,
                  "OT": 0.0,
                  "CA3": 0.0,
                  "CONG_WD": null,
                  "CONG_OT": null,
                  "CONG_CA3": null
                }
              ],
      });
    }

    final mockJson = {
      "YEAR": year,
      "MONTH": month,
      "EMPLOYEE_ID": "43950",
      "DAY_OF_WEEK": 7,
      "SUM_DAY_OF_MONTH": daysInMonth,
      "TIME_SHEET_DATA": timeSheetDataList,
    };

    return TimesheetModel.fromJson(mockJson);
  }
}

