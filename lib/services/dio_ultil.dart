
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';
import '../base/responses/base_response.dart';
import '../data/remote/datasources/client_api.dart';
import '../utils/helpers/pref_manager.dart';


class DioUtil {

  DioUtil(this._dio, this._pref) {
    _setUpInterceptors();
  }

  final Dio _dio;
  final PrefManager _pref;

  int _retryCount = 0;
  final List<Duration> _retryDelays = const [
    Duration(seconds: 1),
    Duration(seconds: 2),
    Duration(seconds: 3)
  ];

  final Duration _timeoutDuration = const Duration(seconds: 60);

  void _setUpInterceptors() {
    // Add interceptors

    _dio.interceptors.add(PrettyDioLogger(
      request: true,
      requestBody: true,
      responseBody: false,
      requestHeader: false,
      responseHeader: false,
    ));

    // Base options
    // _dio.options.baseUrl = EnvManager.shared.apiBaseUrlDriver;
    _dio.options.baseUrl = 'https://api.thp.vn';
    _dio.options.connectTimeout = _timeoutDuration;
    _dio.options.receiveTimeout = _timeoutDuration;
    _dio.options.sendTimeout = _timeoutDuration;
    _dio.options.headers = {'Content-Type': 'application/json'};
  }

  Future<Response<dynamic>> _execute(
      Future<Response<dynamic>> Function() request, {
        bool isShowError = false,
        bool isRetry = false,
        bool isTransformData = false,
      }) async {
    try {
      final response = await request();

      if (isTransformData) {
        final data = BaseResponse.fromJson(response.data ?? {});

        if (data.success == false) {
          throw DioException(
            requestOptions: response.requestOptions,
            response: response,
            message: data.message,
          );
        }
        return Response<dynamic>(
          data: data.data ?? {},
          requestOptions: response.requestOptions,
          statusCode: response.statusCode,
          statusMessage: response.statusMessage,
          headers: response.headers,
          isRedirect: response.isRedirect,
          redirects: response.redirects,
          extra: response.extra,
        );
      }

      return response;
    } on DioException catch (e) {
      if (isRetry) {
        if (_retryCount < _retryDelays.length) {
          if (_isRetryableError(e)) {
            await Future.delayed(_retryDelays[_retryCount]);
            _retryCount++;
            return _execute(
              request,
              isRetry: isRetry,
              isShowError: isShowError,
              isTransformData: isTransformData,
            );
          }
        }
        _retryCount = 0;
      }

      if (isShowError) {
        // Error dialog is handled at UI layer
        debugPrint('[THP_API] ❌ API Error: ${handleErrorTranslate(e)}');
      }

      throw DioException(
        requestOptions: e.requestOptions,
        response: e.response,
        message: handleErrorTranslate(e),
      );
    }
  }

  bool _isRetryableError(DioException e) {
    return [
      DioExceptionType.connectionTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.sendTimeout
    ].contains(e.type);
  }

  void _handleErrorDialog(DioException e, BuildContext context) {
    String message;
    switch (e.response?.statusCode) {
      case 401:
        message = 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại';
        break;
      case 403:
        message = 'Bạn không có quyền truy cập';
        break;
      default:
        message = handleErrorTranslate(e) ?? 'Đã có lỗi xảy ra, vui lòng thử lại';
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Lỗi'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<Response<dynamic>> _retryableRequest(
      Future<Response<dynamic>> Function() request, {
        bool isRetry = false,
        bool isShowError = false,
        bool isTransformData = false,
      }) async {
    return _execute(
      request,
      isRetry: isRetry,
      isShowError: isShowError,
      isTransformData: isTransformData,
    );
  }

  Future<Response<dynamic>> get(
      String url, {
        Map<String, dynamic>? queryParameters,
        Map<String, dynamic>? headers,
        String? path,
        CancelToken? cancelToken,
        ProgressCallback? onReceiveProgress,
        bool isRetry = false,
        bool isShowError = false,
        bool isTranformData = true,
        bool isAuth = true,
        bool isProvinceHeader = true,
      }) async {
    if (isProvinceHeader) {
      headers = {
        ...?headers,
        provinceHeader: _pref.provinceId,
      };
    }

    if (isAuth) {
      final apiToken = _pref.token;
      if (apiToken == null) {
        return Response<dynamic>(
          data: {},
          requestOptions: RequestOptions(
            path: '',
            baseUrl: '',
            queryParameters: {},
            headers: {},
          ),
          statusCode: 401,
          statusMessage: 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại',
          headers: Headers.fromMap({}),
          isRedirect: false,
          redirects: [],
          extra: {},
        );
      }

      queryParameters = {
        ...?queryParameters,
        token: apiToken,
      };
    }

    return _retryableRequest(
          () => _dio.get(
        url,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          headers: {
            ...?headers,
          },
        ),
      ),
      isRetry: isRetry,
      isShowError: isShowError,
      isTransformData: isTranformData,
    );
  }

// Add similar methods for post, put, delete, patch, download, request, fetch...

//post
  Future<Response<dynamic>> post(
      String url, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Map<String, dynamic>? headers,
        String path = '',
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
        bool isRetry = false,
        bool isShowError = false,
        bool isTranformData = true,
        bool isAuth = true,
        bool isProvinceHeader = true,
      }) async {
    if (isProvinceHeader) {
      headers = {
        ...?headers,
        provinceHeader: _pref.provinceId,
      };
    }
    if (isAuth) {
      final apiToken = _pref.token;
      if (apiToken == null) {
        return Response<dynamic>(
          data: {},
          requestOptions: RequestOptions(
            path: '',
            baseUrl: '',
            queryParameters: {},
            headers: {},
          ),
          statusCode: 401,
          statusMessage: 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại',
          headers: Headers.fromMap({}),
          isRedirect: false,
          redirects: [],
          extra: {},
        );
      }

      queryParameters = {
        ...?queryParameters,
        token: apiToken,
      };
    }

    return _retryableRequest(
          () => _dio.post(
        url,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          headers: {
            ...?headers,
          },
        ),
      ),
      isRetry: isRetry,
      isShowError: isShowError,
      isTransformData: isTranformData,
    );
  }

//put
  Future<Response<dynamic>> put(
      String url, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Map<String, dynamic>? headers,
        String path = '',
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
        bool isRetry = false,
        bool isShowError = false,
        bool isTranformData = true,
        bool isAuth = true,
        bool isProvinceHeader = true,
      }) async {
    if (isProvinceHeader) {
      headers = {
        ...?headers,
        provinceHeader: _pref.provinceId,
      };
    }
    if (isAuth) {
      final apiToken = _pref.token;
      if (apiToken == null) {
        return Response<dynamic>(
          data: {},
          requestOptions: RequestOptions(
            path: '',
            baseUrl: '',
            queryParameters: {},
            headers: {},
          ),
          statusCode: 401,
          statusMessage: 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại',
          headers: Headers.fromMap({}),
          isRedirect: false,
          redirects: [],
          extra: {},
        );
      }

      queryParameters = {
        ...?queryParameters,
        token: apiToken,
      };
    }

    return _retryableRequest(
          () => _dio.put(
        url,
        data: data,
        queryParameters: queryParameters,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
        options: Options(
          headers: {
            ...?headers,
          },
        ),
      ),
      isRetry: isRetry,
      isShowError: isShowError,
      isTransformData: isTranformData,
    );
  }
//postMultipart

  Future<Response<dynamic>> postMultipart(
      String url, {
        dynamic data,
        Map<String, dynamic>? queryParameters,
        Map<String, dynamic>? headers,
        CancelToken? cancelToken,
        ProgressCallback? onSendProgress,
        ProgressCallback? onReceiveProgress,
        bool isRetry = false,
        bool isShowError = false,
        bool isTranformData = false,
        bool isAuth = true,
        bool isProvinceHeader = true,
      }) async {
    if (isProvinceHeader) {
      headers = {
        ...?headers,
        provinceHeader: _pref.provinceId,
      };
    }

    if (isAuth) {
      final apiToken = _pref.token;
      if (apiToken == null) {
        return Response<dynamic>(
          data: {},
          requestOptions: RequestOptions(
            path: '',
            baseUrl: '',
            queryParameters: {},
            headers: {},
          ),
          statusCode: 401,
          statusMessage: 'Phiên đăng nhập đã hết hạn, vui lòng đăng nhập lại',
          headers: Headers.fromMap({}),
          isRedirect: false,
          redirects: [],
          extra: {},
        );
      }

      queryParameters = {
        ...?queryParameters,
        token: apiToken,
      };
    }

    return _retryableRequest(
          () => _dio.fetch(
        RequestOptions(
          method: "POST",
          baseUrl: url,
          cancelToken: cancelToken,
          data: data,
          queryParameters: queryParameters,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress,
          headers: {
            ...?headers,
          },
        ),
      ),
      isRetry: isRetry,
      isShowError: isShowError,
      isTransformData: isTranformData,
    );
  }

  String? handleErrorTranslate(DioException error) {
    final data = BaseResponse.fromJson(error.response?.data ?? {});
    final customMessages = {
      DioExceptionType.connectionTimeout: 'Lỗi kết nối, vui lòng thử lại',
      DioExceptionType.sendTimeout: 'Lỗi gửi dữ liệu, vui lòng thử lại',
      DioExceptionType.receiveTimeout: 'Lỗi nhận dữ liệu, vui lòng thử lại',
      DioExceptionType.cancel: 'Kết nối bị hủy, vui lòng thử lại',
      DioExceptionType.connectionError: 'Lỗi kết nối mạng, vui lòng thử lại',
    };

    return data.message ??
        customMessages[error.type] ??
        'Đã có lỗi xảy ra, vui lòng thử lại';
  }

  // DataError<T> handleError<T>(dynamic error) {
  //   if (error is DioException) {
  //     return DataError<T>(error.message ?? "Lỗi, vui lòng thử lại sau.");
  //   }
  //   return DataError<T>(error.toString());
  // }

}





