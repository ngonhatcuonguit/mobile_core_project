import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_core_project/data/models/request_history/request_history_model.dart';

const String _kTag = '[THP_API]';

class RequestHistoryApiService {
  final Dio _dio;
  RequestHistoryApiService(this._dio);

  /// GET /api/employee/myrequest?page=X&pagesize=Y
  Future<RequestHistoryResponse> getMyRequests({
    int page = 1,
    int pageSize = 10,
  }) async {
    const path = '/api/employee/myrequest';
    debugPrint('$_kTag ▶ GET $path?page=$page&pagesize=$pageSize');

    final response = await _dio.get<dynamic>(
      path,
      queryParameters: {'page': page, 'pagesize': pageSize},
      options: Options(
        validateStatus: (status) => status != null && status < 500,
        extra: {'skipErrorDialog': true},
      ),
    );

    debugPrint('$_kTag ◀ HTTP ${response.statusCode} $path');

    if (response.statusCode == 200) {
      final json = response.data as Map<String, dynamic>;
      final result = RequestHistoryResponse.fromJson(json);
      debugPrint('$_kTag ✅ getMyRequests – total=${result.total}, page=$page');
      return result;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'HTTP ${response.statusCode}: Không tải được lịch sử phản hồi',
    );
  }
}

