import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_core_project/data/data_sources/remote/timesheet_api_service.dart';
import 'package:flutter_core_project/data/sources/datastate.dart';
import 'package:flutter_core_project/domain/entities/timesheet/timesheet_entity.dart';
import 'package:flutter_core_project/domain/repository/timesheet/timesheet_repository.dart';

class TimesheetRepositoryImpl implements TimesheetRepository {
  final TimesheetApiService _timesheetApiService;

  TimesheetRepositoryImpl(this._timesheetApiService);

  @override
  Future<DataState<TimesheetEntity>> getTimesheet(int year, int month) async {
    try {
      debugPrint('🌐 Fetching timesheet for $month/$year...');

      final httpResponse = await _timesheetApiService.getTimesheet(
        year: year,
        month: month,
      );

      debugPrint('✅ Response received: ${httpResponse.response.statusCode}');

      if (httpResponse.response.statusCode == HttpStatus.ok) {
        debugPrint('📅 Timesheet data: ${httpResponse.data.timeSheetData.length} days loaded');
        return DataSuccess(httpResponse.data);
      } else {
        final statusCode = httpResponse.response.statusCode;
        debugPrint('❌ HTTP Error: $statusCode');
        return DataFailed(
          DioException(
            requestOptions: RequestOptions(path: ''),
            message: 'HTTP $statusCode: ${httpResponse.response.statusMessage}',
            response: Response(
              statusCode: statusCode,
              statusMessage: httpResponse.response.statusMessage,
              requestOptions: RequestOptions(path: ''),
            ),
          ),
        );
      }
    } on DioException catch (e) {
      // Lấy message rõ ràng nhất có thể
      final msg = e.message?.isNotEmpty == true
          ? e.message!
          : e.error?.toString() ?? e.response?.statusMessage ?? 'Lỗi kết nối';
      debugPrint('❌ DioException: $msg | type=${e.type} | status=${e.response?.statusCode}');
      return DataFailed(
        DioException(
          requestOptions: e.requestOptions,
          message: msg,
          response: e.response,
          type: e.type,
          error: e.error,
        ),
      );
    } catch (e, st) {
      debugPrint('❌ Unexpected error: $e\n$st');
      return DataFailed(
        DioException(
          requestOptions: RequestOptions(path: ''),
          message: e.toString(),
        ),
      );
    }
  }
}

