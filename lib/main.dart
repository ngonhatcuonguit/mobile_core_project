import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_core_project/core/configs/theme/app_theme.dart';
import 'package:flutter_core_project/injection_container.dart';
import 'package:flutter_core_project/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:flutter_core_project/presentation/bloc/article/remote/remote_article_event.dart';
import 'package:flutter_core_project/presentation/bloc/timesheet/remote/remote_timesheet_bloc.dart';
import 'package:flutter_core_project/presentation/auth/pages/sign_in.dart';
import 'package:flutter_core_project/presentation/pages/main/main_screen.dart';
import 'package:flutter_core_project/services/auth_service.dart';
import 'package:flutter_core_project/presentation/widgets/network/network_status_banner.dart';
import 'package:flutter_core_project/services/analytics_observer.dart';
import 'package:flutter_core_project/data/data_sources/remote/notification_api_service.dart';
import 'package:flutter_core_project/services/firebase_service.dart';
import 'package:flutter_core_project/services/localization_service.dart';
import 'package:flutter_core_project/services/navigation_service.dart';
import 'package:flutter_core_project/services/network_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_core_project/utils/in_memory_storage.dart';
import 'presentation/choose_mode/bloc/locale_cubit.dart';
import 'presentation/choose_mode/bloc/theme_cubit.dart';

Future<void> main() async {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Giữ native splash hiển thị trong suốt quá trình init — không màn hình trắng
  FlutterNativeSplash.preserve(widgetsBinding: binding);

  // ① HydratedBloc storage PHẢI được khởi tạo TRƯỚC KHI bất kỳ HydratedCubit nào được tạo.
  //    ThemeCubit & LocaleCubit extend HydratedCubit → crash nếu storage = null.
  //    Chạy TUẦN TỰ và TRƯỚC Future.wait để đảm bảo thứ tự.
  await _initHydratedStorage();

  // ② Sau khi storage đã sẵn sàng, chạy các init còn lại song song
  try {
    await Future.wait([
      // Timeout toàn bộ Firebase init — tránh splash bị kẹt nếu Firebase/APNs hang
      FirebaseService.instance
          .initialize()
          .timeout(const Duration(seconds: 20), onTimeout: () {
        debugPrint('[main] ⚠️ Firebase init timeout — tiếp tục không có Firebase.');
      }),
      initializeDependencies(),
      NetworkService().init(),
    ]).timeout(const Duration(seconds: 30), onTimeout: () {
      debugPrint('[main] ⚠️ Startup timeout — tiếp tục chạy app.');
      return [null, null, null];
    });
  } catch (e, stack) {
    debugPrint('[main] ❌ Lỗi khởi động: $e\n$stack');
  }

  // ③ Post-init: inject dependencies & run app
  try {
    // Inject NotificationApiService vào FirebaseService sau khi DI sẵn sàng.
    FirebaseService.instance.notificationApiService = sl<NotificationApiService>();

    // Retry gửi FCM token — lần đầu trong _initFCM() bị bỏ qua vì DI chạy song song.
    final isLoggedIn = await AuthService.isLoggedIn();
    if (isLoggedIn) {
      // fire-and-forget — không block splash
      FirebaseService.instance.registerCurrentDevice();
    }

    FlutterNativeSplash.remove();
    runApp(MyApp(isLoggedIn: isLoggedIn));
  } catch (e, stack) {
    debugPrint('[main] ❌ Lỗi post-init: $e\n$stack');
    FlutterNativeSplash.remove();
    runApp(MyApp(isLoggedIn: false));
  }
}

/// Khởi tạo HydratedBloc storage — luôn thành công, không bao giờ để storage = null.
///
/// Thứ tự ưu tiên:
///   1. getApplicationDocumentsDirectory() — persistent storage tốt nhất
///   2. getTemporaryDirectory()             — fallback khi documents dir không truy cập được
///   3. MemoryStorage()                     — in-memory, state không persist nhưng app chạy bình thường
Future<void> _initHydratedStorage() async {
  if (kIsWeb) {
    try {
      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: HydratedStorage.webStorageDirectory,
      );
      debugPrint('[main] ✅ HydratedBloc storage (web) initialized');
    } catch (e) {
      debugPrint('[main] ❌ HydratedStorage (web) lỗi: $e — dùng MemoryStorage');
      HydratedBloc.storage = InMemoryStorage();
    }
    return;
  }

  // Native (iOS / Android): thử documents → temp → memory
  Directory? storageDir;
  try {
    storageDir = await getApplicationDocumentsDirectory();
  } catch (e) {
    debugPrint('[main] ⚠️ getApplicationDocumentsDirectory lỗi: $e');
    try {
      storageDir = await getTemporaryDirectory();
      debugPrint('[main] ⚠️ Dùng temp directory cho HydratedBloc storage');
    } catch (e2) {
      debugPrint('[main] ⚠️ getTemporaryDirectory lỗi: $e2');
    }
  }

  if (storageDir != null) {
    try {
      HydratedBloc.storage = await HydratedStorage.build(
        storageDirectory: storageDir,
      );
      debugPrint('[main] ✅ HydratedBloc storage: ${storageDir.path}');
      return;
    } catch (e) {
      debugPrint('[main] ❌ HydratedStorage.build() lỗi: $e — dùng MemoryStorage');
    }
  }

  // Absolute fallback — state không được persist nhưng app chạy bình thường.
  // Điều này xảy ra khi file system không truy cập được (rất hiếm).
  HydratedBloc.storage = InMemoryStorage();
  debugPrint('[main] ⚠️ HydratedBloc dùng InMemoryStorage — state sẽ reset mỗi lần khởi động app');
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
        BlocProvider(create: (context) => sl<RemoteTimesheetBloc>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          return BlocBuilder<LocaleCubit, Locale>(
            builder: (context, locale) {
              return MaterialApp(
                title: 'Flutter Core Project',
                navigatorKey: NavigationService.navigatorKey,
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                debugShowCheckedModeBanner: false,

                // Dismiss keyboard toàn app: tap bất kỳ vùng nào → ẩn keyboard
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

                home: NetworkStatusBanner(
                  child: isLoggedIn ? const MainScreen() : const SigninPage(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
