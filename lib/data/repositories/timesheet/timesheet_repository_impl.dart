import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_core_project/data/data_sources/remote/timesheet_api_service.dart';
import 'package:flutter_core_project/data/models/timesheet/timesheet_model.dart';
import 'package:flutter_core_project/data/sources/datastate.dart';
import 'package:flutter_core_project/domain/entities/timesheet/timesheet_entity.dart';
import 'package:flutter_core_project/domain/repository/timesheet/timesheet_repository.dart';

class TimesheetRepositoryImpl implements TimesheetRepository {
  final TimesheetApiService _timesheetApiService;

  TimesheetRepositoryImpl(this._timesheetApiService);

  @override
  Future<DataState<TimesheetEntity>> getTimesheet(int year, int month) async {
    try {
      print('🌐 Fetching timesheet for $month/$year...');

      final httpResponse = await _timesheetApiService.getTimesheet(
        year: year,
        month: month,
      );

      print('✅ Response received: ${httpResponse.response.statusCode}');

      if (httpResponse.response.statusCode == HttpStatus.ok) {
        print('📅 Timesheet data loaded successfully');
        return DataSuccess(httpResponse.data);
      } else {
        print('❌ HTTP Error: ${httpResponse.response.statusCode}');
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            response: Response(
              statusCode: httpResponse.response.statusCode,
              statusMessage: httpResponse.response.statusMessage,
              requestOptions: RequestOptions(path: ''),
            ),
          ),
        );
      }
    } on DioException catch (e) {
      print('❌ DioException caught in repository: ${e.message}');
      return DataFailed(e);
    } catch (e) {
      print('❌ Unexpected error: $e');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          error: e.toString(),
        ),
      );
    }
  }
}

