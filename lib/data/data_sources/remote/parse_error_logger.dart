import 'package:dio/dio.dart';

/// Error logger cho Retrofit/Dio
/// Được sử dụng bởi generated code từ retrofit_generator
class ParseErrorLogger {
  /// Log lỗi khi parse response
  void logError(
    Object error,
    StackTrace stackTrace,
    RequestOptions requestOptions, {
    Response? response,
  }) {
    // TODO: Implement error logging
    // Có thể gửi tới Crashlytics hoặc logging service
    // debugPrint('API Error: $error\nStack: $stackTrace');
  }
}

