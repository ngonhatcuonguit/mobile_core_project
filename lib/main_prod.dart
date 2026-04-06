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
import 'package:flutter_core_project/presentation/auth/pages/sign_in.dart';
import 'package:flutter_core_project/presentation/pages/main/main_screen.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:flutter_core_project/services/analytics_observer.dart';
import 'package:flutter_core_project/data/data_sources/remote/notification_api_service.dart';
import 'package:flutter_core_project/services/firebase_service.dart';
import 'package:flutter_core_project/services/localization_service.dart';
import 'package:flutter_core_project/services/navigation_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'presentation/choose_mode/bloc/locale_cubit.dart';
import 'presentation/choose_mode/bloc/theme_cubit.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  await dotenv.load(fileName: ".env.prod");

  final results = await Future.wait([
    FirebaseService.instance.initialize(),
    getApplicationDocumentsDirectory(),
    initializeDependencies(),
  ]);

  // Inject NotificationApiService vào FirebaseService sau khi DI sẵn sàng.
  FirebaseService.instance.notificationApiService = sl<NotificationApiService>();

  // Retry gửi FCM token — lần đầu trong _initFCM() bị bỏ qua vì DI chạy song song.
  final isLoggedIn = await AuthService.isLoggedIn();
  if (isLoggedIn) {
    FirebaseService.instance.registerCurrentDevice();
  }

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorage.webStorageDirectory
        : results[1] as Directory,
  );

  FlutterNativeSplash.remove();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
        BlocProvider(create: (_) => LocaleCubit()),
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
                navigatorKey: NavigationService.navigatorKey,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                debugShowCheckedModeBanner: false,

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

                home: isLoggedIn ? const MainScreen() : const SigninPage(),
              );
            },
          );
        },
      ),
    );
  }
}
