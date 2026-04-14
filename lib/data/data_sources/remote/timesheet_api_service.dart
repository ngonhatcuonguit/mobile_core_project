import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_core_project/data/models/timesheet/timesheet_model.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:retrofit/dio.dart';

const String _kTag = '[THP_API]';

class TimesheetApiService {
  final Dio dio;

  TimesheetApiService(this.dio);

  /// POST /api/employee/timeesheet?employeeid=43950&year=2025&month=1
  /// Authorization: Bearer <token>  ← inject tự động bởi Dio interceptor
  Future<HttpResponse<TimesheetModel>> getTimesheet({
    required int year,
    required int month,
  }) async {
    final employeeId = await AuthService.getEmployeeId();

    final token = await AuthService.getToken();
    if (token == null || token.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: ''),
        message: 'Chưa đăng nhập hoặc token hết hạn',
      );
    }

    const path = '/api/employee/timeesheet';

    debugPrint('$_kTag ▶ POST ${_buildUrl(path, employeeId, year, month)}');

    final response = await dio.post<dynamic>(
      path,
      queryParameters: {
        'employeeid': employeeId,
        'year': year,
        'month': month,
      },
      options: Options(
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    debugPrint('$_kTag ◀ HTTP ${response.statusCode} $path');
    // Log toàn bộ raw response body — giới hạn 4000 ký tự để không tràn Logcat
    final rawBody = response.data?.toString() ?? 'null';
    final preview = rawBody.length > 4000 ? '${rawBody.substring(0, 4000)}...[truncated]' : rawBody;
    debugPrint('$_kTag   Response body: $preview');

    if (response.data == null) {
      throw DioException(
        requestOptions: response.requestOptions,
        message: 'Không nhận được dữ liệu từ server',
      );
    }

    final raw = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : Map<String, dynamic>.from(response.data as Map);

    // Kiểm tra status envelope ngoài
    final outerStatus = raw['status'] as String?;
    if (outerStatus != 'success') {
      final msg = raw['message'] as String? ?? 'API trả về lỗi (status=$outerStatus)';
      debugPrint('$_kTag ✗ API error: $msg');
      throw DioException(
        requestOptions: response.requestOptions,
        message: msg,
      );
    }

    final model = TimesheetModel.fromApiResponse(raw);

    debugPrint('$_kTag ✅ GetTimeSheet success – '
        '${model.timeSheetData.length} days for $month/$year (emp=$employeeId)');

    return HttpResponse(model, response);
  }

  String _buildUrl(String path, String? empId, int year, int month) =>
      'https://mobile-app.thp.com.vn$path'
      '?employeeid=$empId&year=$year&month=$month';
}
