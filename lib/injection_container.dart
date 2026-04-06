import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_core_project/core/configs/api_error_config.dart';
import 'package:flutter_core_project/core/configs/app_config.dart';
import 'package:flutter_core_project/data/data_sources/remote/adjustment_report_api_service.dart';
import 'package:flutter_core_project/data/data_sources/remote/login_api_service.dart';
import 'package:flutter_core_project/data/data_sources/remote/news_api_service.dart';
import 'package:flutter_core_project/data/data_sources/remote/notification_api_service.dart';
import 'package:flutter_core_project/data/data_sources/remote/request_history_api_service.dart';
import 'package:flutter_core_project/data/data_sources/remote/timesheet_api_service.dart';
import 'package:flutter_core_project/data/repositories/notification/notification_repository_impl.dart';
import 'package:flutter_core_project/data/repositories/request_history/request_history_repository_impl.dart';
import 'package:flutter_core_project/data/repositories/timesheet/timesheet_repository_impl.dart';
import 'package:flutter_core_project/domain/repository/news/article_repository.dart';
import 'package:flutter_core_project/domain/repository/notification/notification_repository.dart';
import 'package:flutter_core_project/data/repositories/request_history/request_history_repository_impl.dart' show RequestHistoryRepository, RequestHistoryRepositoryImpl;
import 'package:flutter_core_project/domain/repository/timesheet/timesheet_repository.dart';
import 'package:flutter_core_project/domain/usecases/submit_adjustment_report_usecase.dart';
import 'package:flutter_core_project/domain/usecases/get_timesheet.dart';
import 'package:flutter_core_project/domain/usecases/register_device_usecase.dart';
import 'package:flutter_core_project/presentation/auth/pages/sign_in.dart';
import 'package:flutter_core_project/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_bloc.dart';
import 'package:flutter_core_project/services/api_error_handler.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:flutter_core_project/services/navigation_service.dart';
import 'package:get_it/get_it.dart';

import 'data/repositories/news/article_repository_impl.dart';
import 'domain/usecases/get_article.dart';

final sl = GetIt.instance;

Dio _buildThpDio() {
  final timeout = Duration(milliseconds: AppConfig.timeoutMs);
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
      connectTimeout: timeout,
      receiveTimeout: timeout,
      sendTimeout: timeout,
      headers: {
        'Accept': 'application/json',
      },
    ),
  );
  debugPrint('[THP_API] 🌐 Base URL = ${AppConfig.baseUrl} | env=${AppConfig.environment}');

  dio.interceptors.add(
    InterceptorsWrapper(
      // ── Request: tự động gắn Bearer token ──────────────────────────────
      onRequest: (options, handler) async {
        final token = await AuthService.getToken();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        if (kDebugMode) {
          debugPrint('[THP_DIO] → ${options.method} ${options.uri}');
          debugPrint('[THP_DIO]   headers: ${options.headers.keys.toList()}');
        }
        handler.next(options);
      },

      // ── Response: phát hiện HTTP error và hiển thị dialog tập trung ───
      //
      // Vì các service dùng validateStatus: (s) => s < 500,
      // các lỗi 4xx về dưới dạng "response thành công". Interceptor này
      // bắt chúng, show dialog (trừ request đã opt-out), rồi reject.
      //
      // Để bỏ qua dialog cho một request cụ thể, set:
      //   options.extra['skipErrorDialog'] = true
      onResponse: (response, handler) {
        final statusCode = response.statusCode ?? 0;
        if (kDebugMode) {
          debugPrint('[THP_DIO] ← $statusCode ${response.requestOptions.path}');
        }

        if (statusCode >= 400) {
          final skip =
              response.requestOptions.extra['skipErrorDialog'] == true;
          if (!skip) {
            // Trích xuất message từ body server (hỗ trợ cả "Message" và "message")
            String? serverMessage;
            try {
              final data = response.data;
              if (data is Map) {
                serverMessage =
                    (data['Message'] ?? data['message'] ?? data['error'])
                        ?.toString();
              }
            } catch (_) {}

            ApiErrorHandler.handleHttpError(
              statusCode,
              serverMessage: serverMessage,
            );
          }

          // Reject để lỗi tiếp tục lan lên repository / BLoC
          handler.reject(
            DioException(
              requestOptions: response.requestOptions,
              response: response,
              type: DioExceptionType.badResponse,
              message: 'HTTP $statusCode',
            ),
            // false = không gọi thêm onError interceptors (dialog đã show)
            false,
          );
          return;
        }

        handler.next(response);
      },

      // ── Error: xử lý lỗi mạng / timeout ────────────────────────────────
      onError: (error, handler) {
        debugPrint('[THP_DIO] ✗ ${error.requestOptions.path} → ${error.message}');

        final skip =
            error.requestOptions.extra['skipErrorDialog'] == true;
        if (!skip) {
          final networkErrors = {
            DioExceptionType.connectionTimeout,
            DioExceptionType.receiveTimeout,
            DioExceptionType.sendTimeout,
            DioExceptionType.connectionError,
          };
          if (networkErrors.contains(error.type)) {
            ApiErrorHandler.handleNetworkError();
          }
        }

        handler.next(error);
      },
    ),
  );

  return dio;
}

Future<void> initializeDependencies() async {
  setupApiErrorConfigs();

  sl.registerSingleton<Dio>(Dio());
  final thpDio = _buildThpDio();
  sl.registerSingleton<LoginApiService>(LoginApiService(thpDio));
  sl.registerSingleton<NewsApiService>(NewsApiService(sl()));
  sl.registerSingleton<TimesheetApiService>(TimesheetApiService(thpDio));
  sl.registerSingleton<NotificationApiService>(NotificationApiService(thpDio));
  sl.registerSingleton<AdjustmentReportApiService>(AdjustmentReportApiService(thpDio));
  sl.registerSingleton<RequestHistoryApiService>(RequestHistoryApiService(thpDio));
  sl.registerSingleton<ArticleRepository>(ArticleRepositoryImpl(sl()));
  sl.registerSingleton<TimesheetRepository>(TimesheetRepositoryImpl(sl()));
  sl.registerSingleton<NotificationRepository>(NotificationRepositoryImpl(sl()));
  sl.registerSingleton<RequestHistoryRepository>(RequestHistoryRepositoryImpl(sl()));
  sl.registerSingleton<GetArticleUseCase>(GetArticleUseCase(sl()));
  sl.registerSingleton<GetTimesheetUseCase>(GetTimesheetUseCase(sl()));
  sl.registerSingleton<SubmitAdjustmentReportUseCase>(SubmitAdjustmentReportUseCase(sl()));
  sl.registerSingleton<RegisterDeviceUseCase>(RegisterDeviceUseCase(sl()));
  sl.registerSingleton<RemoteArticlesBloc>(RemoteArticlesBloc(sl()));
  sl.registerSingleton<RemoteTimesheetBloc>(RemoteTimesheetBloc(sl()));
}

// ─────────────────────────────────────────────────────────────────────────────
// Cấu hình dialog lỗi API theo từng HTTP status code
// ─────────────────────────────────────────────────────────────────────────────
//
// Để thêm / thay đổi hành vi cho một mã lỗi, chỉnh sửa tại đây.
// Xem thêm: lib/core/configs/api_error_config.dart
// ─────────────────────────────────────────────────────────────────────────────

void setupApiErrorConfigs() {
  // ── 401 — Token hết hạn / chưa đăng nhập ──────────────────────────────
  ApiErrorConfigs.register(
    401,
    ApiErrorDialogConfig(
      icon: Icons.lock_clock_outlined,
      iconColor: const Color(0xFFF57C00),
      title: 'Phiên đăng nhập hết hạn',
      defaultMessage: 'Vui lòng đăng nhập lại để tiếp tục sử dụng.',
      actions: [
        ApiErrorActionConfig(
          label: 'Đăng nhập lại',
          backgroundColor: const Color(0xFF2196F3),
          foregroundColor: Colors.white,
          onPressed: (ctx) async {
            Navigator.of(ctx).pop(); // đóng dialog
            await AuthService.logout(); // xoá token + thông tin user
            // Navigate về màn hình đăng nhập, xoá toàn bộ stack
            NavigationService.navigator?.pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const SigninPage()),
              (_) => false,
            );
          },
        ),
      ],
    ),
  );

  // ── 403 — Không có quyền truy cập ─────────────────────────────────────
  ApiErrorConfigs.register(
    403,
    const ApiErrorDialogConfig(
      icon: Icons.block_rounded,
      iconColor: Color(0xFFE53935),
      title: 'Không có quyền truy cập',
      defaultMessage: 'Tài khoản của bạn không có quyền thực hiện hành động này.',
      actions: [
        ApiErrorActionConfig(label: 'Đóng'),
      ],
    ),
  );

  // ── 404 — Không tìm thấy tài nguyên ───────────────────────────────────
  ApiErrorConfigs.register(
    404,
    const ApiErrorDialogConfig(
      icon: Icons.search_off_rounded,
      iconColor: Color(0xFF9E9E9E),
      title: 'Không tìm thấy dữ liệu',
      defaultMessage: 'Tài nguyên yêu cầu không tồn tại hoặc đã bị xoá.',
      actions: [
        ApiErrorActionConfig(label: 'Đóng'),
      ],
    ),
  );

  // ── 500 — Lỗi máy chủ nội bộ ──────────────────────────────────────────
  ApiErrorConfigs.register(
    500,
    const ApiErrorDialogConfig(
      icon: Icons.dns_rounded,
      iconColor: Color(0xFFE53935),
      title: 'Lỗi máy chủ',
      defaultMessage: 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau ít phút.',
      actions: [
        ApiErrorActionConfig(label: 'Đóng'),
      ],
    ),
  );

  // ── 503 — Máy chủ tạm ngừng hoạt động ────────────────────────────────
  ApiErrorConfigs.register(
    503,
    const ApiErrorDialogConfig(
      icon: Icons.cloud_off_rounded,
      iconColor: Color(0xFFE53935),
      title: 'Dịch vụ tạm ngừng',
      defaultMessage: 'Dịch vụ đang bảo trì. Vui lòng thử lại sau.',
      actions: [
        ApiErrorActionConfig(label: 'Đóng'),
      ],
    ),
  );
}
