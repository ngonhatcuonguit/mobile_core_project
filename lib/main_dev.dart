import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/core/configs/app_config.dart';
import 'package:flutter_core_project/core/configs/theme/app_theme.dart';
import 'package:flutter_core_project/injection_container.dart';
import 'package:flutter_core_project/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:flutter_core_project/presentation/bloc/article/remote/remote_article_event.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_bloc.dart';
import 'package:flutter_core_project/presentation/pages/splash/splash.dart';
import 'package:flutter_core_project/services/analytics_observer.dart';
import 'package:flutter_core_project/services/firebase_service.dart';
import 'package:flutter_core_project/services/localization_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'presentation/choose_mode/bloc/locale_cubit.dart';
import 'presentation/choose_mode/bloc/theme_cubit.dart';

Future<void> main() async {
  // preserve() phải gọi TRƯỚC WidgetsFlutterBinding
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await dotenv.load(fileName: ".env.dev");

  final results = await Future.wait([
    FirebaseService.instance.initialize(),
    getApplicationDocumentsDirectory(),
    initializeDependencies(),
  ]);

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : results[1] as Directory,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => LocaleCubit()),
        // GetArticles chỉ dispatch sau khi app đã render xong, không block startup
        BlocProvider(
            create: (context) =>
                sl<RemoteArticlesBloc>()..add(const GetArticles())),
        BlocProvider(create: (_) => sl<RemoteTimesheetBloc>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp(
                title: AppConfig.appTitle,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                debugShowCheckedModeBanner: true,

                // Dismiss keyboard toàn app khi tap ra ngoài
                builder: (context, child) {
                  return GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
                    child: child!,
                  );
                },

                // Auto screen tracking cho Firebase Analytics
                navigatorObservers: [
                  AppFirebaseAnalyticsObserver(
                    analytics: FirebaseService.instance.analytics,
                  ),
                ],

                // Localization delegates
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: const [
                  Locale('en', ''), // English
                  Locale('vi', ''), // Vietnamese
                ],
                locale: locale,

                home: const SplashPage(),
              );
            },
          );
        },
      ),
    );
  }
}
