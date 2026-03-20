import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_core_project/core/configs/app_config.dart';
import 'package:flutter_core_project/data/data_sources/remote/adjustment_report_api_service.dart';
import 'package:flutter_core_project/data/data_sources/remote/login_api_service.dart';
import 'package:flutter_core_project/data/data_sources/remote/news_api_service.dart';
import 'package:flutter_core_project/data/data_sources/remote/notification_api_service.dart';
import 'package:flutter_core_project/data/data_sources/remote/timesheet_api_service.dart';
import 'package:flutter_core_project/data/repositories/notification/notification_repository_impl.dart';
import 'package:flutter_core_project/data/repositories/timesheet/timesheet_repository_impl.dart';
import 'package:flutter_core_project/domain/repository/news/article_repository.dart';
import 'package:flutter_core_project/domain/repository/notification/notification_repository.dart';
import 'package:flutter_core_project/domain/repository/timesheet/timesheet_repository.dart';
import 'package:flutter_core_project/domain/usecases/submit_adjustment_report_usecase.dart';
import 'package:flutter_core_project/domain/usecases/get_timesheet.dart';
import 'package:flutter_core_project/domain/usecases/register_device_usecase.dart';
import 'package:flutter_core_project/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_bloc.dart';
import 'package:flutter_core_project/services/auth_service.dart';
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

  // Interceptor tự động gắn Bearer token vào MỌI request
  dio.interceptors.add(
    InterceptorsWrapper(
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
      onResponse: (response, handler) {
        if (kDebugMode) {
          debugPrint('[THP_DIO] ← ${response.statusCode} ${response.requestOptions.path}');
        }
        handler.next(response);
      },
      onError: (error, handler) {
        debugPrint('[THP_DIO] ✗ ${error.requestOptions.path} → ${error.message}');
        handler.next(error);
      },
    ),
  );

  return dio;
}

Future<void> initializeDependencies() async {
  sl.registerSingleton<Dio>(Dio());
  final thpDio = _buildThpDio();
  sl.registerSingleton<LoginApiService>(LoginApiService(thpDio));
  sl.registerSingleton<NewsApiService>(NewsApiService(sl()));
  sl.registerSingleton<TimesheetApiService>(TimesheetApiService(thpDio));
  sl.registerSingleton<NotificationApiService>(NotificationApiService(thpDio));
  sl.registerSingleton<AdjustmentReportApiService>(AdjustmentReportApiService(thpDio));
  sl.registerSingleton<ArticleRepository>(ArticleRepositoryImpl(sl()));
  sl.registerSingleton<TimesheetRepository>(TimesheetRepositoryImpl(sl()));
  sl.registerSingleton<NotificationRepository>(NotificationRepositoryImpl(sl()));
  sl.registerSingleton<GetArticleUseCase>(GetArticleUseCase(sl()));
  sl.registerSingleton<GetTimesheetUseCase>(GetTimesheetUseCase(sl()));
  sl.registerSingleton<SubmitAdjustmentReportUseCase>(SubmitAdjustmentReportUseCase(sl()));
  sl.registerSingleton<RegisterDeviceUseCase>(RegisterDeviceUseCase(sl()));
  sl.registerSingleton<RemoteArticlesBloc>(RemoteArticlesBloc(sl()));
  sl.registerSingleton<RemoteTimesheetBloc>(RemoteTimesheetBloc(sl()));
}
