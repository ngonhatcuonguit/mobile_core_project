import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  final String message;
  final int? statusCode;
  final Object? data;

  factory ApiException.fromDio(DioException exception) {
    final responseData = exception.response?.data;
    String? serverMessage;
    if (responseData is Map) {
      serverMessage = (responseData['message'] ??
              responseData['Message'] ??
              responseData['error'])
          ?.toString();
    }

    return ApiException(
      message: serverMessage ?? _fallbackMessage(exception),
      statusCode: exception.response?.statusCode,
      data: responseData,
    );
  }

  static String _fallbackMessage(DioException exception) {
    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Ket noi may chu qua thoi gian cho phep.';
      case DioExceptionType.connectionError:
        return 'Khong the ket noi den may chu.';
      case DioExceptionType.cancel:
        return 'Yeu cau da bi huy.';
      case DioExceptionType.badCertificate:
        return 'Chung chi bao mat cua may chu khong hop le.';
      case DioExceptionType.badResponse:
        return 'May chu tra ve du lieu khong hop le.';
      case DioExceptionType.unknown:
        return exception.message ?? 'Da xay ra loi khong xac dinh.';
    }
  }

  @override
  String toString() => message;
}
