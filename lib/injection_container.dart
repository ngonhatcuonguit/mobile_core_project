import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_core_project/data/data_sources/remote/login_api_service.dart';
import 'package:flutter_core_project/data/data_sources/remote/news_api_service.dart';
import 'package:flutter_core_project/data/data_sources/remote/timesheet_api_service.dart';
import 'package:flutter_core_project/data/repositories/timesheet/timesheet_repository_impl.dart';
import 'package:flutter_core_project/domain/repository/news/article_repository.dart';
import 'package:flutter_core_project/domain/repository/timesheet/timesheet_repository.dart';
import 'package:flutter_core_project/domain/usecases/get_timesheet.dart';
import 'package:flutter_core_project/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_bloc.dart';
import 'package:get_it/get_it.dart';

import 'data/repositories/news/article_repository_impl.dart';
import 'domain/usecases/get_article.dart';

final sl = GetIt.instance;

Dio _buildThpDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://mythp-api.thp.com.vn',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );
  if (kDebugMode) {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (o, h) {
        debugPrint('[THP_DIO] → ${o.method} ${o.uri}');
        h.next(o);
      },
      onResponse: (r, h) {
        debugPrint('[THP_DIO] ← ${r.statusCode} type=${r.data?.runtimeType}');
        h.next(r);
      },
      onError: (e, h) {
        debugPrint('[THP_DIO] ✗ ${e.message}');
        h.next(e);
      },
    ));
  }
  return dio;
}

Future<void> initializeDependencies() async {
  sl.registerSingleton<Dio>(Dio());
  final thpDio = _buildThpDio();
  sl.registerSingleton<LoginApiService>(LoginApiService(thpDio));
  sl.registerSingleton<NewsApiService>(NewsApiService(sl()));
  sl.registerSingleton<TimesheetApiService>(TimesheetApiService(thpDio));
  sl.registerSingleton<ArticleRepository>(ArticleRepositoryImpl(sl()));
  sl.registerSingleton<TimesheetRepository>(TimesheetRepositoryImpl(sl()));
  sl.registerSingleton<GetArticleUseCase>(GetArticleUseCase(sl()));
  sl.registerSingleton<GetTimesheetUseCase>(GetTimesheetUseCase(sl()));
  sl.registerSingleton<RemoteArticlesBloc>(RemoteArticlesBloc(sl()));
  sl.registerSingleton<RemoteTimesheetBloc>(RemoteTimesheetBloc(sl()));
}
