import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_core_project/data/models/level_up/level_up_models.dart';

const String _kTag = '[THP_API]';

class LevelUpApiService {
  final Dio _dio;

  LevelUpApiService(this._dio);

  Future<List<LevelUpFactory>> getFactories({required String email}) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty) {
      throw const LevelUpApiException(
        'Tài khoản chưa có email để kiểm tra quyền chấm thi.',
      );
    }
    final data = await _getList(
      '/api/exam/listFactorys',
      queryParameters: {'email': normalizedEmail},
    );
    return data
        .map(LevelUpFactory.fromJson)
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<List<LevelUpLevel>> getLevels() async {
    final data = await _getList('/api/exam/listLevels');
    return data
        .map(LevelUpLevel.fromJson)
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<List<LevelUpLine>> getLines({required int factoryId}) async {
    final data = await _getList(
      '/api/exam/listLines',
      queryParameters: {'FactoryId': factoryId},
    );
    return data
        .map(LevelUpLine.fromJson)
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<List<LevelUpMachine>> getMachines({required int lineId}) async {
    final data = await _getList(
      '/api/exam/listMachines',
      queryParameters: {'LineId': lineId},
    );
    return data
        .map(LevelUpMachine.fromJson)
        // listPractical vẫn có thể trả bài thi cho máy Active = 0
        // (ví dụ MachineId 562), nên client không được tự loại máy này.
        .where((item) => item.id > 0)
        .toList(growable: false);
  }

  Future<List<LevelUpPracticalExam>> getPracticalExams({
    required LevelUpFilter filter,
    required LevelUpExamStatus status,
  }) async {
    if (!filter.canLoadExams) {
      throw const LevelUpApiException(
        'Vui lòng chọn đủ nhà máy, line, máy và cấp bậc trước khi xem bài thi.',
      );
    }

    final query = <String, dynamic>{
      'FactoryId': filter.factoryId,
      'LineId': filter.lineId,
      'MachineId': filter.machineId,
      'LevelId': filter.levelId,
      'Status': status.apiValue,
    };
    final data = await _getList(
      '/api/exam/listPractical',
      queryParameters: query,
      preferredListKeys: const [
        'Practicals',
        'PracticalExams',
        'Exams',
        'Candidates',
        'Items',
        'Results',
      ],
    );
    return [
      for (var index = 0; index < data.length; index++)
        LevelUpPracticalExam.fromJson(
          data[index],
          fallbackFilter: filter,
          index: index,
        ),
    ];
  }

  Future<LevelUpPracticalDetail> getPracticalDetail({
    required int practicalId,
  }) async {
    if (practicalId <= 0) {
      throw const LevelUpApiException('ID bài thi không hợp lệ.');
    }
    final root = await _requestJson(
      '/api/exam/detailPractical',
      queryParameters: {'practicalId': practicalId},
    );
    final rawData = _readCaseInsensitive(root, 'data');
    if (rawData is! Map) {
      throw const LevelUpApiException(
        'Chi tiết bài thi trả về không đúng định dạng.',
      );
    }
    return LevelUpPracticalDetail.fromJson(
      Map<String, dynamic>.from(rawData),
      examPracticalId: practicalId,
    );
  }

  Future<void> submitPracticalScores({
    required List<LevelUpPracticalScoreRequest> scores,
  }) async {
    if (scores.isEmpty) {
      throw const LevelUpApiException('Bài thi không có câu hỏi để gửi điểm.');
    }
    await _requestJson(
      '/api/exam/submitPractical',
      method: 'POST',
      data: [for (final score in scores) score.toJson()],
      allowEmptyResponse: true,
    );
  }

  Future<List<Map<String, dynamic>>> _getList(
    String path, {
    Map<String, dynamic>? queryParameters,
    List<String> preferredListKeys = const ['Items', 'Results'],
  }) async {
    final root = await _requestJson(
      path,
      queryParameters: queryParameters,
    );
    final result = _extractMapList(root, preferredListKeys);
    if (kDebugMode) {
      debugPrint('$_kTag ◀ $path – ${result.length} items');
    }
    return result;
  }

  Future<Map<String, dynamic>> _requestJson(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? queryParameters,
    Object? data,
    bool allowEmptyResponse = false,
  }) async {
    if (kDebugMode) debugPrint('$_kTag ▶ $method $path');

    try {
      final response = await _dio.request<dynamic>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: Options(
          method: method,
          contentType: data == null ? null : Headers.jsonContentType,
          validateStatus: (status) => status != null && status < 500,
          extra: {
            'skipErrorDialog': true,
            'handleUnauthorized': true,
            'redactQueryInLogs': true,
          },
        ),
      );

      final statusCode = response.statusCode ?? 0;
      if (statusCode < 200 || statusCode >= 300) {
        throw LevelUpApiException(
          _extractMessage(response.data) ??
              'Không tải được dữ liệu chấm thi (HTTP $statusCode).',
          statusCode: statusCode,
        );
      }

      if (allowEmptyResponse) {
        final responseData = response.data;
        if (responseData == null) return const {};
        if (responseData is String) {
          final responseText = responseData.trim();
          if (responseText.isEmpty ||
              (!responseText.startsWith('{') &&
                  !responseText.startsWith('['))) {
            return const {};
          }
        } else if (responseData is! Map && responseData is! List) {
          return const {};
        }
      }
      final root = _asJson(response.data);
      final apiStatus = _readCaseInsensitive(root, 'status')?.toString();
      if (apiStatus != null &&
          apiStatus.isNotEmpty &&
          apiStatus.toLowerCase() != 'success' &&
          apiStatus.toLowerCase() != 'true') {
        throw LevelUpApiException(
          _extractMessage(root) ?? 'Hệ thống trả về trạng thái $apiStatus.',
        );
      }
      if (kDebugMode) debugPrint('$_kTag ◀ $statusCode $method $path');
      return root;
    } on LevelUpApiException {
      rethrow;
    } on DioException catch (error) {
      if (kDebugMode) {
        debugPrint('$_kTag ✗ $path – ${error.type}: ${error.message}');
      }
      throw LevelUpApiException(
        _dioMessage(error),
        cause: error,
        statusCode: error.response?.statusCode,
      );
    } on FormatException catch (error) {
      if (kDebugMode) debugPrint('$_kTag ✗ $path – invalid response');
      throw LevelUpApiException(
        'Dữ liệu chấm thi trả về không đúng định dạng.',
        cause: error,
      );
    }
  }

  Map<String, dynamic> _asJson(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is List) return {'data': raw};
    if (raw is String) {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
      if (decoded is List) return {'data': decoded};
    }
    throw FormatException('Unsupported response type: ${raw.runtimeType}');
  }

  List<Map<String, dynamic>> _extractMapList(
    Map<String, dynamic> root,
    List<String> preferredKeys,
  ) {
    final data = _readCaseInsensitive(root, 'data');
    final direct = _asMapList(data);
    if (direct != null) return direct;

    if (data is Map) {
      final dataMap = Map<String, dynamic>.from(data);
      for (final key in preferredKeys) {
        final list = _asMapList(_readCaseInsensitive(dataMap, key));
        if (list != null) return list;
      }
    }

    for (final key in preferredKeys) {
      final list = _asMapList(_readCaseInsensitive(root, key));
      if (list != null) return list;
    }
    return const [];
  }

  List<Map<String, dynamic>>? _asMapList(Object? value) {
    if (value is! List) return null;
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  Object? _readCaseInsensitive(Map<String, dynamic> json, String key) {
    if (json.containsKey(key)) return json[key];
    final lower = key.toLowerCase();
    for (final entry in json.entries) {
      if (entry.key.toLowerCase() == lower) return entry.value;
    }
    return null;
  }

  String? _extractMessage(dynamic raw) {
    if (raw is! Map) return null;
    final json = Map<String, dynamic>.from(raw);
    final message = _readCaseInsensitive(json, 'message') ??
        _readCaseInsensitive(json, 'error');
    final text = message?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  String _dioMessage(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Kết nối hệ thống chấm thi quá thời gian. Vui lòng thử lại.';
      case DioExceptionType.connectionError:
        return 'Không thể kết nối hệ thống chấm thi. Kiểm tra mạng nội bộ/VPN.';
      default:
        return _extractMessage(error.response?.data) ??
            'Không tải được dữ liệu chấm thi. Vui lòng thử lại.';
    }
  }
}

class LevelUpApiException implements Exception {
  final String message;
  final Object? cause;
  final int? statusCode;

  const LevelUpApiException(
    this.message, {
    this.cause,
    this.statusCode,
  });

  @override
  String toString() => message;
}
