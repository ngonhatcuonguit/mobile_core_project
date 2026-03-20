import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_core_project/data/models/timesheet/adjustment_report_model.dart';

const String _kTag = '[THP_API]';

class AdjustmentReportApiService {
  final Dio dio;

  AdjustmentReportApiService(this.dio);

  /// POST /api/employee/requestadjust
  /// Response: { "status": "success", "data": "Bạn đã yêu cầu điều chỉnh thành công!" }
  /// Trả về [message] từ server để hiển thị popup.
  Future<String> submitAdjustmentReport(AdjustmentReportRequest request) async {
    const path = '/api/employee/requestadjust';
    final body = request.toJson();

    debugPrint('$_kTag ▶ POST $path');
    debugPrint('$_kTag   Body: $body');

    final response = await dio.post<dynamic>(
      path,
      data: body,
      options: Options(
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    debugPrint('$_kTag ◀ HTTP ${response.statusCode} $path');
    final rawBody = response.data?.toString() ?? 'null';
    final preview = rawBody.length > 2000
        ? '${rawBody.substring(0, 2000)}...[truncated]'
        : rawBody;
    debugPrint('$_kTag   Response body: $preview');

    final statusCode = response.statusCode ?? 0;
    if (statusCode >= 200 && statusCode < 300) {
      if (response.data is Map<String, dynamic>) {
        final body = response.data as Map<String, dynamic>;
        final status = (body['status'] ?? '').toString().toLowerCase();
        final message = body['data']?.toString() ??
            body['message']?.toString() ??
            'Gửi báo cáo thành công!';

        if (status == 'success') {
          return message;
        } else {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: message,
          );
        }
      }
      return 'Gửi báo cáo thành công!';
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'HTTP $statusCode: ${response.statusMessage}',
    );
  }
}
