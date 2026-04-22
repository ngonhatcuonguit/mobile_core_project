# 📱 Flutter Core Project — Tài Liệu Ôn Tập Phỏng Vấn Technical

> **Project:** My THP — Internal Enterprise App (THP Group)  
> **Version:** 1.0.1+1 | **Flutter SDK:** ≥3.1.4 <4.0.0  
> **Tác giả tài liệu:** Tổng hợp từ toàn bộ codebase thực tế  
> **Ngày tổng hợp:** 20/04/2026

---

## MỤC LỤC

1. [Tổng quan & Elevator Pitch](#1-tổng-quan--elevator-pitch)
2. [Kiến trúc dự án — Clean Architecture](#2-kiến-trúc-dự-án--clean-architecture)
3. [Cấu trúc Folder chi tiết](#3-cấu-trúc-folder-chi-tiết)
4. [Design Patterns](#4-design-patterns)
5. [Startup Flow — Khởi động App](#5-startup-flow--khởi-động-app)
6. [Dependency Injection (GetIt)](#6-dependency-injection-getit)
7. [Networking — Dio Strategy](#7-networking--dio-strategy)
8. [State Management — BLoC/Cubit](#8-state-management--bloccubit)
9. [Data Flow từng Module](#9-data-flow-từng-module)
10. [Firebase Integration](#10-firebase-integration)
11. [Work Schedule & Local Notification](#11-work-schedule--local-notification)
12. [Localization & Theme](#12-localization--theme)
13. [Platform Configuration](#13-platform-configuration)
14. [Third-party Libraries & SDK](#14-third-party-libraries--sdk)
15. [API Endpoints](#15-api-endpoints)
16. [Technical Debt & Cải tiến](#16-technical-debt--cải-tiến)
17. [Câu hỏi phỏng vấn thường gặp](#17-câu-hỏi-phỏng-vấn-thường-gặp)
18. [Checklist ôn tập](#18-checklist-ôn-tập)

---

## 1. Tổng quan & Elevator Pitch

### 1.1 Mô tả App

**My THP** là ứng dụng mobile nội bộ của Tập đoàn THP, phục vụ nhân viên:

| Chức năng | Mô tả |
|-----------|-------|
| 🔐 **Authentication** | Đăng nhập nội bộ bằng tài khoản doanh nghiệp, lưu session |
| 📅 **Timesheet** | Bảng công theo tháng, cache UI state, xem chi tiết theo ngày, điểm chấm công |
| 📝 **Điều chỉnh công** | Gửi yêu cầu điều chỉnh bảng công qua API |
| 🔔 **Notification** | Trung tâm thông báo: list/paging/filter read-unread, FCM token registration |
| 📆 **Work Schedule** | Thiết lập ca làm việc, nhắc check-in/check-out, cảnh báo trễ/OT (local notification) |
| 👤 **Profile** | Thông tin nhân viên, cài đặt, điều khoản sử dụng |
| 📰 **News** | Tin tức nội bộ doanh nghiệp |

### 1.2 Tech Stack tóm tắt

```
Flutter 3.x  +  Dart 3.x
Architecture: Clean Architecture + BLoC Pattern
DI:           GetIt (Service Locator)
Network:      Dio + Retrofit
State:        flutter_bloc / hydrated_bloc
Firebase:     Core / Messaging / Analytics / Crashlytics
Notification: flutter_local_notifications
```

---

## 2. Kiến trúc dự án — Clean Architecture

### 2.1 Sơ đồ 3 Layer

```
┌─────────────────────────────────────────────────────┐
│                  PRESENTATION LAYER                  │
│   Pages / Widgets / BLoC / Cubit                    │
│   → Gửi Event → nhận State → render UI             │
└──────────────────────┬──────────────────────────────┘
                       │ calls UseCase
┌──────────────────────▼──────────────────────────────┐
│                   DOMAIN LAYER                       │
│   Entities / Repository Interfaces / UseCases        │
│   → Không phụ thuộc UI hay Data implementation      │
└──────────────────────┬──────────────────────────────┘
                       │ implements
┌──────────────────────▼──────────────────────────────┐
│                    DATA LAYER                        │
│   Models / Repository Implementations / API Services │
│   → Gọi API, parse JSON → trả Entity về Domain      │
└─────────────────────────────────────────────────────┘
```

### 2.2 Nguyên tắc áp dụng

- **Dependency Rule**: Domain không phụ thuộc bất kỳ layer nào khác
- **Repository Interface** nằm ở Domain, **Implementation** nằm ở Data
- **Entity** (Domain) tách biệt hoàn toàn với **Model** (Data/JSON)
- Presentation chỉ giao tiếp với Domain qua **UseCase**, không gọi API trực tiếp
- Một số page cũ vẫn gọi trực tiếp service (technical debt — đang refactor)

### 2.3 Ví dụ cụ thể: Timesheet Module

```
TimesheetPage (UI)
    ↓ add(GetTimesheet event)
RemoteTimesheetBloc
    ↓ call
GetTimesheetUseCase (Domain)
    ↓ call
TimesheetRepository (interface - Domain)
    ↓ implemented by
TimesheetRepositoryImpl (Data)
    ↓ call
TimesheetApiService (Data)
    ↓ HTTP POST
/api/employee/timeesheet
    ↓ parse
TimesheetModel → TimesheetEntity
    ↑ DataSuccess<TimesheetEntity>
RemoteTimesheetBloc → emit(TimesheetLoaded)
    ↑ build()
TimesheetPage renders UI
```

---

## 3. Cấu trúc Folder chi tiết

```
lib/
├── main.dart              # Entry point chính — startup flow
├── main_dev.dart          # Load .env.dev → runApp
├── main_prod.dart         # Load .env.prod → runApp
├── firebase_options.dart  # Auto-generated bởi FlutterFire CLI
├── injection_container.dart # DI wiring toàn app (GetIt)
│
├── core/
│   └── configs/
│       ├── app_config.dart         # Đọc env vars: baseUrl, timeout, env name
│       ├── api_error_config.dart   # Map HTTP status → dialog config
│       └── theme/
│           ├── app_theme.dart      # Light/Dark ThemeData
│           ├── app_colors.dart     # Color palette
│           └── app_text_styles.dart
│
├── constants/
│   └── constants.dart     # App-wide constants (newsAPIKey — technical debt)
│
├── domain/
│   ├── entities/
│   │   ├── auth/user.dart
│   │   ├── news/article_entity.dart
│   │   └── timesheet/timesheet_entity.dart  # TimesheetEntity, TimeSheetDataEntity, CheckingPointEntity
│   ├── repository/
│   │   ├── auth/auth.dart
│   │   ├── news/article_repository.dart
│   │   ├── notification/notification_repository.dart
│   │   └── timesheet/timesheet_repository.dart
│   └── usecases/
│       ├── usecase.dart                    # Abstract base: call({Params}) → Future<Type>
│       ├── get_article.dart
│       ├── get_timesheet.dart              # GetTimesheetParams(year, month)
│       ├── submit_adjustment_report_usecase.dart
│       └── register_device_usecase.dart
│
├── data/
│   ├── sources/
│   │   ├── datastate.dart    # DataState<T>, DataSuccess<T>, DataFailed<T>
│   │   └── status.dart
│   ├── models/
│   │   ├── auth/login_model.dart
│   │   ├── news/ArticleModel.dart
│   │   ├── notification/notification_model.dart
│   │   ├── request_history/request_history_model.dart
│   │   ├── timesheet/
│   │   │   ├── timesheet_model.dart         # fromApiResponse(), fromJson()
│   │   │   └── adjustment_report_model.dart
│   │   └── work_schedule/work_schedule_model.dart
│   ├── data_sources/remote/
│   │   ├── login_api_service.dart
│   │   ├── news_api_service.dart (+ .g.dart)
│   │   ├── timesheet_api_service.dart
│   │   ├── notification_api_service.dart
│   │   ├── adjustment_report_api_service.dart
│   │   └── request_history_api_service.dart
│   └── repositories/
│       ├── news/article_repository_impl.dart
│       ├── timesheet/timesheet_repository_impl.dart
│       ├── notification/notification_repository_impl.dart
│       └── request_history/request_history_repository_impl.dart
│
├── presentation/
│   ├── choose_mode/bloc/
│   │   ├── theme_cubit.dart    # HydratedCubit<ThemeMode>
│   │   └── locale_cubit.dart   # HydratedCubit<Locale>
│   ├── bloc/
│   │   ├── article/remote/     # RemoteArticlesBloc
│   │   └── timesheet/remote/   # RemoteTimesheetBloc ← module phức tạp nhất
│   ├── auth/pages/
│   │   ├── sign_in.dart
│   │   └── signup_or_signin.dart
│   ├── pages/
│   │   ├── main/main_screen.dart      # BottomNavBar 4 tab (IndexedStack)
│   │   ├── home/home_page.dart
│   │   ├── timesheet/
│   │   │   ├── timesheet_page.dart
│   │   │   └── adjustment_report_page.dart
│   │   ├── notification/notification_page.dart
│   │   ├── work_schedule/work_schedule_setup_page.dart
│   │   ├── request_history/
│   │   ├── profile/
│   │   └── service/service_page.dart
│   └── widgets/
│       ├── network/network_status_banner.dart
│       └── dialog/DialogService.dart
│
├── services/
│   ├── auth_service.dart             # SharedPreferences: token, session
│   ├── firebase_service.dart         # Singleton: FCM, Analytics, Crashlytics
│   ├── work_schedule_notification_service.dart
│   ├── network_service.dart
│   ├── localization_service.dart
│   ├── navigation_service.dart       # Global NavigatorKey
│   ├── api_error_handler.dart
│   └── analytics_observer.dart      # RouteObserver → auto screen tracking
│
└── utils/
    ├── in_memory_storage.dart        # HydratedStorage fallback (implements Storage)
    ├── network_test_helper.dart
    └── helpers/pref_manager.dart
```

---

## 4. Design Patterns

### 4.1 Clean Architecture (Partial)

| Layer | Thành phần | Ví dụ trong project |
|-------|-----------|---------------------|
| Domain | Entity, UseCase, Repo Interface | `TimesheetEntity`, `GetTimesheetUseCase`, `TimesheetRepository` |
| Data | Model, Repo Impl, API Service | `TimesheetModel`, `TimesheetRepositoryImpl`, `TimesheetApiService` |
| Presentation | Page, Widget, BLoC | `TimesheetPage`, `RemoteTimesheetBloc` |

### 4.2 BLoC Pattern (Business Logic Component)

```dart
// Event → Bloc → State
abstract class TimesheetEvent {}
class GetTimesheet extends TimesheetEvent { final int year, month; }
class ChangeMonth extends TimesheetEvent { ... }
class SelectDay extends TimesheetEvent { ... }
class RestoreTimesheetFromCache extends TimesheetEvent {}

// States
class TimesheetInitial extends TimesheetState {}
class TimesheetLoading extends TimesheetState {}
class TimesheetRefreshing extends TimesheetState { // giữ UI cũ + overlay loading
  final TimesheetEntity? timesheet;
  final DateTime? selectedDate;
}
class TimesheetLoaded extends TimesheetState {
  final TimesheetEntity? timesheet;
  final DateTime? selectedDate;
}
class TimesheetError extends TimesheetState { final DioException error; }
```

### 4.3 Repository Pattern

```dart
// Domain: Interface
abstract class TimesheetRepository {
  Future<DataState<TimesheetEntity>> getTimesheet(int year, int month);
}

// Data: Implementation
class TimesheetRepositoryImpl implements TimesheetRepository {
  final TimesheetApiService _timesheetApiService;
  // ... try/catch DioException → DataSuccess / DataFailed
}
```

### 4.4 UseCase Pattern

```dart
// Base abstract class
abstract class UseCase<Type, Params> {
  Future<Type> call({Params params});
}

// Concrete implementation
class GetTimesheetUseCase implements UseCase<DataState<TimesheetEntity>, GetTimesheetParams> {
  final TimesheetRepository repository;
  @override
  Future<DataState<TimesheetEntity>> call({GetTimesheetParams? params}) =>
      repository.getTimesheet(params!.year, params.month);
}
```

### 4.5 Singleton Pattern

```dart
// FirebaseService — Singleton
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();
  bool _initialized = false;
  // ...
}

// WorkScheduleNotificationService — Singleton
class WorkScheduleNotificationService {
  WorkScheduleNotificationService._();
  static final WorkScheduleNotificationService instance = ...;
}
```

### 4.6 Observer Pattern

- `AppFirebaseAnalyticsObserver` — RouteObserver → tự động log screen_view
- `ConnectivityPlus` — stream network state → `NetworkStatusBanner`

### 4.7 DataState Pattern (Result Wrapper)

```dart
// Thay vì throw Exception, dùng sealed-like class
abstract class DataState<T> {
  final T? data;
  final DioException? error;
}
class DataSuccess<T> extends DataState<T> { DataSuccess(T data) : super(data: data); }
class DataFailed<T> extends DataState<T> { DataFailed(DioException error) : super(error: error); }

// Usage trong BLoC
final dataState = await _getTimesheetUseCase(params: ...);
if (dataState is DataSuccess && dataState.data != null) {
  emit(TimesheetLoaded(timesheet: dataState.data!));
} else if (dataState is DataFailed) {
  emit(TimesheetError(dataState.error!));
}
```

---

## 5. Startup Flow — Khởi động App

### 5.1 Sequence diagram

```
main() được gọi
    │
    ├─① WidgetsFlutterBinding.ensureInitialized()
    │   FlutterNativeSplash.preserve()   ← giữ native splash
    │
    ├─② _initHydratedStorage()  [TUẦN TỰ - PHẢI trước HydratedCubit]
    │   ├── Documents Dir → HydratedStorage.build()
    │   ├── (fallback) Temp Dir → HydratedStorage.build()
    │   └── (fallback) InMemoryStorage()   ← không crash app
    │
    ├─③ Future.wait([...]) timeout 30s  [SONG SONG]
    │   ├── FirebaseService.initialize()  timeout 20s
    │   │   ├── Firebase.initializeApp()
    │   │   ├── _initCrashlytics()
    │   │   ├── _initAnalytics()
    │   │   └── _initFCM()
    │   ├── initializeDependencies()   ← DI registration
    │   └── NetworkService().init()
    │
    ├─④ Post-init
    │   ├── inject NotificationApiService → FirebaseService
    │   ├── AuthService.isLoggedIn()
    │   ├── (nếu đã login) FirebaseService.registerCurrentDevice()
    │   └── FlutterNativeSplash.remove()
    │
    └─⑤ runApp(MyApp(isLoggedIn: ...))
```

### 5.2 Tại sao thiết kế như vậy?

| Vấn đề | Giải pháp |
|--------|-----------|
| HydratedCubit crash nếu storage = null | Init HydratedStorage TUẦN TỰ trước |
| Firebase/FCM có thể hang (simulator, offline) | timeout 20s + fallback |
| Splash trắng nếu init chậm | FlutterNativeSplash.preserve() giữ splash đến khi remove() |
| DI chưa sẵn sàng khi FCM cần gửi token | inject NotificationApiService sau khi DI xong |
| File system không truy cập được | Fallback InMemoryStorage — app chạy bình thường |

### 5.3 HydratedBloc Storage fallback chain

```
getApplicationDocumentsDirectory()
    ↓ (thất bại)
getTemporaryDirectory()
    ↓ (thất bại)
InMemoryStorage()  ← state không persist nhưng app không crash
```

---

## 6. Dependency Injection (GetIt)

### 6.1 Registration order

```dart
final sl = GetIt.instance;

// 1. Dio instance (generic)
sl.registerSingleton<Dio>(Dio());

// 2. THP Dio (với interceptor, base URL, auth header)
final thpDio = _buildThpDio();

// 3. API Services (data sources)
sl.registerSingleton<LoginApiService>(LoginApiService(thpDio));
sl.registerSingleton<TimesheetApiService>(TimesheetApiService(thpDio));
sl.registerSingleton<NotificationApiService>(NotificationApiService(thpDio));
sl.registerSingleton<AdjustmentReportApiService>(...);
sl.registerSingleton<RequestHistoryApiService>(...);

// 4. Repositories (implementations)
sl.registerSingleton<TimesheetRepository>(TimesheetRepositoryImpl(sl()));
sl.registerSingleton<NotificationRepository>(NotificationRepositoryImpl(sl()));
// ...

// 5. UseCases
sl.registerSingleton<GetTimesheetUseCase>(GetTimesheetUseCase(sl()));
sl.registerSingleton<SubmitAdjustmentReportUseCase>(...);
sl.registerSingleton<RegisterDeviceUseCase>(...);

// 6. BLoCs
sl.registerSingleton<RemoteTimesheetBloc>(RemoteTimesheetBloc(sl()));
sl.registerSingleton<RemoteArticlesBloc>(RemoteArticlesBloc(sl()));
```

### 6.2 Hot restart guard

```dart
Future<void> initializeDependencies() async {
  // Nếu đã đăng ký rồi (hot restart), bỏ qua tránh duplicate
  if (sl.isRegistered<LoginApiService>()) {
    debugPrint('[DI] Already initialized — skipping.');
    return;
  }
  // ... registration
}
```

### 6.3 Late injection (post-init)

```dart
// FirebaseService.notificationApiService được inject SAU khi DI xong
// vì FirebaseService.initialize() chạy song song với initializeDependencies()
FirebaseService.instance.notificationApiService = sl<NotificationApiService>();
```

---

## 7. Networking — Dio Strategy

### 7.1 THP Dio Configuration

```dart
Dio _buildThpDio() {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.baseUrl,   // từ .env file
    connectTimeout: timeout,
    receiveTimeout: timeout,
    sendTimeout: timeout,
    headers: {'Accept': 'application/json'},
  ));

  dio.interceptors.add(InterceptorsWrapper(
    onRequest: ...,   // Auto-attach Bearer token
    onResponse: ...,  // Catch 4xx errors (validateStatus < 500)
    onError: ...,     // Handle network/timeout errors
  ));
}
```

### 7.2 Interceptor — Request

```dart
onRequest: (options, handler) async {
  final token = await AuthService.getToken();
  if (token != null) {
    options.headers['Authorization'] = 'Bearer $token';
  }
  handler.next(options);
},
```

### 7.3 Interceptor — Response (4xx handling)

```dart
onResponse: (response, handler) {
  if (statusCode >= 400) {
    final skip = response.requestOptions.extra['skipErrorDialog'] == true;
    if (!skip) {
      // Extract server message từ body
      String? serverMessage = data['Message'] ?? data['message'] ?? data['error'];
      ApiErrorHandler.handleHttpError(statusCode, serverMessage: serverMessage);
    }
    // Reject để BLoC nhận được lỗi
    handler.reject(DioException(...), false);
    return;
  }
  handler.next(response);
},
```

### 7.4 Interceptor — Error (network/timeout)

```dart
onError: (error, handler) {
  final skip = error.requestOptions.extra['skipErrorDialog'] == true;
  if (!skip) {
    final networkErrors = {connectionTimeout, receiveTimeout, sendTimeout, connectionError};
    if (networkErrors.contains(error.type)) {
      ApiErrorHandler.handleNetworkError();
    }
  }
  handler.next(error);
},
```

### 7.5 API Error Dialog Config (HTTP Status Mapping)

| Status | Title | Action |
|--------|-------|--------|
| 401 | Phiên đăng nhập hết hạn | → logout + navigate SigninPage |
| 403 | Không có quyền truy cập | Đóng |
| 404 | Không tìm thấy dữ liệu | Đóng |
| 500 | Lỗi máy chủ | Đóng |
| 503 | Dịch vụ tạm ngừng | Đóng |

### 7.6 opt-out dialog cho request cụ thể

```dart
// Login không dùng dialog chung (cần custom error UX)
await dio.post('/api/account/internallogin',
  options: Options(extra: {'skipErrorDialog': true}),
);
```

### 7.7 Environment config

```
.env.dev:
  API_BASE_URL=https://mobile-app-dev.thp.com.vn
  ENVIRONMENT=development
  API_TIMEOUT_MS=30000

.env.prod:
  API_BASE_URL=https://mobile-app.thp.com.vn
  ENVIRONMENT=production
  API_TIMEOUT_MS=30000
```

---

## 8. State Management — BLoC/Cubit

### 8.1 BLoC vs Cubit — khi nào dùng cái nào?

| Loại | Dùng cho | Ví dụ trong project |
|------|----------|---------------------|
| **BLoC** | Business logic phức tạp, nhiều event | `RemoteTimesheetBloc`, `RemoteArticlesBloc` |
| **Cubit** | State đơn giản, ít transition | `ThemeCubit`, `LocaleCubit` |
| **HydratedCubit** | State cần persist qua reboot | `ThemeCubit`, `LocaleCubit` |

### 8.2 ThemeCubit (HydratedCubit)

```dart
class ThemeCubit extends HydratedCubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.light);

  void updateTheme(ThemeMode themeMode) => emit(themeMode);
  void toggleTheme() => emit(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);

  // Serialize/Deserialize để persist vào storage
  @override
  ThemeMode? fromJson(Map<String, dynamic> json) { ... }
  @override
  Map<String, dynamic>? toJson(ThemeMode state) { ... }
}
```

### 8.3 RemoteTimesheetBloc — Chi tiết

#### Events

```dart
class GetTimesheet extends TimesheetEvent {
  final int year, month;  // Lần đầu load / force refresh
}
class ChangeMonth extends TimesheetEvent {
  final int year, month;  // User bấm mũi tên tháng
}
class SelectDay extends TimesheetEvent {
  final DateTime? selectedDate;  // User tap vào ngày trên calendar
}
class RestoreTimesheetFromCache extends TimesheetEvent {
  // Gọi trong initState của TimesheetPage
}
```

#### Cache Strategy (In-Memory)

```dart
final Map<String, TimesheetEntity> _cache = {};
// Key: "2025-1", "2025-12", ...

// Cache hit → không gọi API
final cached = _cache[_key(event.year, event.month)];
if (cached != null) {
  emit(TimesheetLoaded(timesheet: cached, ...));
  return;
}

// Tháng tương lai → trả entity rỗng, không gọi API
if (_isFutureMonth(year, month)) {
  emit(TimesheetLoaded(timesheet: _emptyEntity(year, month)));
  return;
}

// Có state cũ → emit Refreshing (giữ UI cũ + overlay loading)
// Chưa có state → emit Loading (shimmer)
```

#### UX States

```
TimesheetInitial → (restore from cache)
    ↓
TimesheetLoading → (shimmer hiển thị, lần đầu không có data)
    OR
TimesheetRefreshing → (user đổi tháng, giữ UI cũ + overlay spinner)
    ↓
TimesheetLoaded (timesheet, selectedDate)
    OR
TimesheetError (DioException)
```

#### Selected month persistence

```dart
// Lưu tháng đang xem vào SharedPreferences
Future<void> _saveSelectedMonth(int year, int month) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setInt('ts_selected_year', year);
  await prefs.setInt('ts_selected_month', month);
}
```

#### App restart behavior

```dart
Future<void> _onRestoreFromCache(RestoreTimesheetFromCache event, ...) async {
  if (state is TimesheetLoaded) return;  // Bloc còn sống → giữ nguyên
  // App restart → in-memory cache rỗng → luôn call API tháng hiện tại
  final now = DateTime.now();
  add(GetTimesheet(year: now.year, month: now.month));
}
```

### 8.4 MultiBlocProvider setup

```dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => ThemeCubit()),
    BlocProvider(create: (_) => LocaleCubit()),
    BlocProvider(create: (_) => sl<RemoteArticlesBloc>()..add(const GetArticles())),
    BlocProvider(create: (_) => sl<RemoteTimesheetBloc>()),
  ],
  child: BlocBuilder<ThemeCubit, ThemeMode>(
    builder: (context, themeMode) => BlocBuilder<LocaleCubit, Locale>(
      builder: (context, locale) => MaterialApp(...)
    ),
  ),
)
```

---

## 9. Data Flow từng Module

### 9.1 Login Flow

```
1. User nhập email + password → tap "Đăng nhập"
2. sign_in.dart → LoginApiService.login()
   POST /api/account/internallogin
   (options.extra['skipErrorDialog'] = true → tự handle lỗi)
3. Parse response → LoginModel
4. AuthService.setLoggedIn(email, name, token, employeeId, ...)
   → SharedPreferences: is_logged_in, auth_token, employee_id, ...
5. FirebaseService.registerCurrentDevice()
   → getFCMToken() → NotificationApiService.registerDevice()
6. Navigator.pushReplacement(MainScreen)
```

### 9.2 Timesheet Flow

```
1. TimesheetPage.initState()
   → add(RestoreTimesheetFromCache())
2. RemoteTimesheetBloc._onRestoreFromCache()
   → add(GetTimesheet(year, month))
3. _onGetTimesheet():
   - Check future month → emit empty entity
   - Check cache hit → emit Loaded
   - No cache → emit Loading/Refreshing → call API
4. GetTimesheetUseCase.call(params)
5. TimesheetRepositoryImpl.getTimesheet(year, month)
6. TimesheetApiService.getTimesheet(year, month)
   POST /api/employee/timeesheet?employeeid=43950&year=2025&month=1
7. Parse JSON → TimesheetModel.fromApiResponse(raw)
8. return DataSuccess(timesheetModel)  [model implements entity]
9. Bloc → _cache["2025-1"] = data → emit TimesheetLoaded
10. TimesheetPage BlocBuilder rebuild UI
```

### 9.3 Notification Flow

```
HOME (badge unread):
  NotificationRepository.getUnreadCount()
  GET /api/employee/getmessage?mode=UNREAD&page=1&pagesize=1
  → extract total → hiển thị badge số

NOTIFICATION LIST:
  NotificationPage → getMessages(mode, page, pageSize)
  GET /api/employee/getmessage
  → NotificationListResponse { total, items: [NotificationItem] }
  → Infinite scroll paging

MARK AS READ:
  markAsRead(messageId)
  PUT/POST /api/employee/readmessage
  → Optimistic UI: cập nhật local state ngay → sync lại unread count

FCM TOKEN:
  FirebaseService._initFCM()
  → messaging.requestPermission()
  → messaging.getToken() (iOS: kiểm tra APNS token trước)
  → NotificationApiService.registerDevice(token, deviceType)
    POST /api/account/RegisterNotification
  → onTokenRefresh → re-register
```

### 9.4 Work Schedule Local Notification Flow

```
1. WorkScheduleSetupPage → user thay đổi cài đặt
2. Debounce 700ms → autosave
3. Save WorkScheduleModel → SharedPreferences (JSON)
4. WorkScheduleNotificationService.scheduleFromWorkSchedule(model)
5. _notifications.cancelAll()   ← xóa tất cả lịch cũ
6. Loop 7 ngày tới:
   → _scheduleCheckInReminder()   (trước giờ check-in X phút)
   → _scheduleCheckOutReminder()  (trước giờ check-out X phút)
   → _scheduleLateAlert()         (+5 phút sau giờ check-in)
   → _scheduleOvertimeAlert()     (+15 phút sau giờ check-out)
7. Timezone: Asia/Ho_Chi_Minh (tz.setLocalLocation)
8. scheduleNotification type: zonedSchedule
```

---

## 10. Firebase Integration

### 10.1 FirebaseService — Singleton

```dart
class FirebaseService {
  FirebaseService._();
  static final FirebaseService instance = FirebaseService._();
  bool _initialized = false;  // guard chống init 2 lần

  late FirebaseAnalytics analytics;
  late FirebaseCrashlytics crashlytics;
  late FirebaseMessaging messaging;

  NotificationApiService? notificationApiService;  // inject sau DI
}
```

### 10.2 Crashlytics Setup

```dart
await crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

// Bắt Flutter framework errors
FlutterError.onError = crashlytics.recordFlutterFatalError;

// Bắt async errors (Zone)
PlatformDispatcher.instance.onError = (error, stack) {
  crashlytics.recordError(error, stack, fatal: true);
  return true;
};
```

### 10.3 FCM — Foreground vs Background

```dart
// Background handler — PHẢI là top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) await Firebase.initializeApp(...);
  // Không show UI — hệ thống tự hiện notification
}

// Foreground handler
void _handleForegroundMessage(RemoteMessage message) {
  // Android: phải dùng flutter_local_notifications để hiện
  if (Platform.isAndroid) {
    _localNotifications.show(notification.hashCode, title, body, ...);
  }
  // iOS: setForegroundNotificationPresentationOptions() handle natively
  // KHÔNG gọi localNotifications.show() trên iOS → sẽ bị duplicate!
}
```

### 10.4 FCM Token lifecycle

```dart
Future<String?> getFCMToken() async {
  if (Platform.isIOS) {
    // Kiểm tra APNS token trước (iOS require APNs)
    final apns = await messaging.getAPNSToken().timeout(10s);
    if (apns == null) return null;  // simulator/offline → skip
  }
  return await messaging.getToken().timeout(15s);
}

// Token refresh → re-register
messaging.onTokenRefresh.listen((newToken) {
  registerCurrentDevice();
});
```

### 10.5 Analytics Screen Tracking

```dart
// NavigatorObserver tự động log screen_view
navigatorObservers: [
  AppFirebaseAnalyticsObserver(analytics: FirebaseService.instance.analytics),
],
```

---

## 11. Work Schedule & Local Notification

### 11.1 WorkScheduleModel

```dart
class WorkScheduleModel {
  bool isActive;           // Ca làm việc có active không
  TimeOfDay checkInTime;   // Giờ check-in
  TimeOfDay checkOutTime;  // Giờ check-out
  bool isOvernight;        // Ca đêm (check-out sang ngày hôm sau)
  List<int> repeatDays;   // [1,2,3,4,5] = T2-T6
  bool checkInReminderEnabled;
  int checkInReminderMinutes;
  bool checkOutReminderEnabled;
  int checkOutReminderMinutes;
  bool lateAlertEnabled;
  bool overtimeAlertEnabled;
}
```

### 11.2 Notification ID scheme

```
1000-1006: Check-in reminders (7 ngày tiếp theo)
2000-2006: Check-out reminders
3000-3006: Late alerts (5 phút sau giờ check-in)
4000-4006: Overtime alerts (15 phút sau giờ check-out)
```

### 11.3 Timezone handling

```dart
tz.initializeTimeZones();
tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

// Schedule notification tại thời điểm cụ thể
await _notifications.zonedSchedule(
  id,
  title,
  body,
  tz.TZDateTime.from(scheduledTime, tz.local),
  ...
);
```

---

## 12. Localization & Theme

### 12.1 i18n Setup

```dart
// lib/l10n/en.json + vi.json
// AppLocalizations.delegate (custom generated)

// MaterialApp
localizationsDelegates: [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
],
supportedLocales: [Locale('en', ''), Locale('vi', '')],
locale: locale,  // từ LocaleCubit state
```

### 12.2 LocaleCubit (HydratedCubit)

```dart
class LocaleCubit extends HydratedCubit<Locale> {
  LocaleCubit() : super(const Locale('vi', ''));  // Mặc định tiếng Việt
  void changeLocale(Locale locale) => emit(locale);
  // fromJson/toJson để persist
}
```

### 12.3 Theme

- `AppTheme.lightTheme` và `AppTheme.darkTheme` — `ThemeData`
- Font chính: **Be Vietnam Pro** (300/400/500/600/700 + italic)
- Font phụ: Satoshi (legacy)
- `ThemeCubit` emit `ThemeMode` → `MaterialApp.themeMode`

---

## 13. Platform Configuration

### 13.1 Android

```gradle
// android/app/build.gradle
compileSdk 36
minSdkVersion flutter.minSdkVersion
targetSdkVersion 35

flavorDimensions "environment"
productFlavors {
  dev {
    applicationIdSuffix ".dev"
    // applicationId = "com.digital.thp.my_thp.dev"
  }
  prod {
    // applicationId = "com.digital.thp.my_thp"
  }
}

// Plugins
apply plugin: 'com.google.gms.google-services'
apply plugin: 'com.google.firebase.crashlytics'
```

**Android 12+ patch**: Auto patch cho `flutter_local_notifications` compile API 35

### 13.2 iOS

```ruby
# ios/Podfile
platform :ios, '17.0'

post_install do |installer|
  # Firebase Messaging + Crashlytics patch
end
```

- APNS integration: `firebase_messaging`
- Background modes: `remote-notification` in Info.plist

### 13.3 Build Commands

```bash
# Run Dev
flutter run --flavor dev -t lib/main_dev.dart

# Run Prod
flutter run --flavor prod -t lib/main_prod.dart

# Build APK Prod (release)
flutter build apk --flavor prod -t lib/main_prod.dart --release

# Build iOS Prod
flutter build ipa --flavor prod -t lib/main_prod.dart
```

### 13.4 Native Splash

```yaml
flutter_native_splash:
  color: "#FFFFFF"
  image: assets/images/splash_logo.png
  android_12:
    # Logo trong vùng 66% trung tâm (1152x1152px)
    image: assets/images/splash_logo.png

# Generate:
dart run flutter_native_splash:create
```

---

## 14. Third-party Libraries & SDK

### 14.1 State Management

| Package | Version | Mục đích |
|---------|---------|----------|
| `bloc` | 8.1.4 | Core BLoC library |
| `flutter_bloc` | 8.1.6 | Flutter widgets cho BLoC |
| `hydrated_bloc` | 9.1.5 | Persist BLoC/Cubit state |
| `equatable` | 2.0.8 | So sánh object (dùng trong Entity, State) |
| `get_it` | 9.2.1 | Service Locator / Dependency Injection |

### 14.2 Network & Data

| Package | Version | Mục đích |
|---------|---------|----------|
| `dio` | 5.9.2 | HTTP client với interceptor |
| `retrofit` | 4.5.0 | Type-safe REST client (dùng cho NewsApi) |
| `json_serializable` | 6.8.0 | Code generation JSON serialization |
| `json_annotation` | 4.9.0 | Annotations cho json_serializable |
| `http` | 0.13.6 | Simple HTTP (legacy, ít dùng) |
| `shared_preferences` | 2.2.3 | Key-value local storage (session, prefs) |
| `path_provider` | 2.1.4 | App directory paths (HydratedBloc storage) |
| `floor` | 1.5.0 | SQLite ORM (dependency hiện có, chưa active) |

### 14.3 Firebase

| Package | Version | Mục đích |
|---------|---------|----------|
| `firebase_core` | 2.32.0 | Firebase initialization |
| `firebase_messaging` | 14.9.4 | Push notifications (FCM) |
| `firebase_analytics` | 10.10.7 | Analytics + screen tracking |
| `firebase_crashlytics` | 3.5.7 | Crash reporting |

### 14.4 Notification, UI, Utils

| Package | Version | Mục đích |
|---------|---------|----------|
| `flutter_local_notifications` | 16.3.3 | Local notifications (work schedule + FCM foreground) |
| `timezone` | 0.9.4 | Timezone support cho scheduled notifications |
| `flutter_native_splash` | 2.4.0 | Native splash screen (Android/iOS) |
| `flutter_svg` | 2.0.9 | SVG rendering |
| `cached_network_image` | 3.3.1 | Network image với cache |
| `shimmer` | 3.0.0 | Loading skeleton effect |
| `intl` | 0.18.1 | Internationalization, date/number formatting |
| `connectivity_plus` | 5.0.2 | Network status monitoring |
| `pretty_dio_logger` | 1.4.0 | Request/response logging (debug) |
| `flutter_dotenv` | 6.0.0 | Load environment variables từ .env file |

---

## 15. API Endpoints

### 15.1 Base URL

| Environment | URL |
|-------------|-----|
| Dev | `https://mobile-app-dev.thp.com.vn` |
| Prod | `https://mobile-app.thp.com.vn` |

### 15.2 Endpoints

| Method | Path | Mục đích |
|--------|------|----------|
| POST | `/api/account/internallogin` | Đăng nhập nội bộ |
| POST | `/api/account/RegisterNotification` | Đăng ký FCM token |
| POST | `/api/employee/timeesheet` | Lấy bảng công theo tháng |
| POST | `/api/employee/requestadjust` | Gửi yêu cầu điều chỉnh công |
| GET | `/api/employee/getmessage` | Danh sách thông báo (paging) |
| GET/POST | `/api/employee/readmessage` | Đánh dấu đã đọc thông báo |
| GET | `/api/employee/myrequest` | Lịch sử yêu cầu |

### 15.3 Request/Response pattern

```json
// Request: /api/employee/timeesheet
POST ?employeeid=43950&year=2025&month=1
Authorization: Bearer <token>

// Response envelope
{
  "status": "success",
  "data": {
    "employeeId": "43950",
    "year": 2025,
    "month": 1,
    "dayOfWeek": 3,
    "sumDayOfMonth": 31,
    "timeSheetData": [...]
  }
}
```

---

## 16. Technical Debt & Cải tiến

### 16.1 Những vấn đề hiện tại

| Vấn đề | Mức độ | Giải pháp |
|--------|--------|-----------|
| Test coverage gần 0% (widget_test.dart là template mặc định) | 🔴 High | Viết unit test cho UseCase, BLoC, Repository |
| `constants.dart` hardcode `newsAPIKey` | 🟡 Medium | Chuyển vào `.env` + secure storage |
| Một số page gọi service/repo trực tiếp, không qua UseCase | 🟡 Medium | Chuẩn hóa qua UseCase |
| `floor` dependency không được sử dụng | 🟢 Low | Xóa hoặc implement |
| Không có CI/CD pipeline | 🟡 Medium | Setup GitHub Actions: lint → test → build |

### 16.2 Nếu làm tiếp

1. **Unit Test**: `bloc_test` cho RemoteTimesheetBloc, mockito/mocktail cho Repository
2. **Secure Storage**: `flutter_secure_storage` cho API keys, token
3. **CI/CD**: GitHub Actions: `flutter analyze` + `flutter test` + build APK
4. **Error monitoring**: Custom error codes + structured logging
5. **Offline mode**: SQFlite cache cho timesheet/notification

---

## 17. Câu hỏi phỏng vấn thường gặp

### Q1: Tại sao chọn BLoC thay vì Provider/Riverpod/GetX?

**Trả lời:**
- App có business logic phức tạp (timesheet có nhiều event: load, đổi tháng, chọn ngày, restore cache)
- BLoC buộc tách biệt hoàn toàn UI ↔ Business Logic qua Event/State
- Dễ test: BLoC test không cần Flutter (pure Dart)
- Team quen với pattern này, dễ onboard thành viên mới
- `hydrated_bloc` giúp persist state dễ dàng

### Q2: Clean Architecture có overhead không? Tại sao vẫn dùng?

**Trả lời:**
- Có overhead ban đầu (nhiều file hơn), nhưng:
- Khi scale lên nhiều module, không bị spaghetti code
- Dễ test từng layer độc lập
- Backend thay đổi API chỉ cần sửa Data layer, Domain/Presentation không đổi
- Trong project này áp dụng "practical clean architecture" — không hoàn toàn strict

### Q3: Tại sao Timesheet dùng in-memory cache thay vì database?

**Trả lời:**
- Dữ liệu chấm công có thể thay đổi trong ngày → không nên cache dài hạn
- In-memory đủ nhanh cho UX đổi tháng (không cần gọi API lại)
- App restart → luôn fetch tháng hiện tại đảm bảo data mới nhất
- Không cần persistence phức tạp như SQLite

### Q4: Giải thích Refreshing state trong Timesheet Bloc?

**Trả lời:**
- Khi user đổi sang tháng chưa có cache → cần call API
- Nếu emit `Loading` → UI xóa data cũ, hiển thị shimmer → UX giật
- `Refreshing` state giữ `timesheet` cũ trong state → UI giữ layout cũ
- Overlay loading spinner nhỏ thay vì full-screen shimmer
- UX mượt hơn nhiều khi đổi tháng liên tục

### Q5: FCM token registration lifecycle như thế nào?

**Trả lời:**
```
App launch (đã login) → main() → registerCurrentDevice()
    ↓
Login thành công → AuthService.setLoggedIn() → registerCurrentDevice()
    ↓
Token refresh → messaging.onTokenRefresh → registerCurrentDevice()
    ↓
iOS: phải có APNS token trước mới lấy được FCM token
   → getAPNSToken() timeout 10s (tránh hang trên simulator)
```

### Q6: Làm thế nào handle lỗi API tập trung?

**Trả lời:**
- Dio Interceptor bắt tất cả response ≥ 400
- Map HTTP status → `ApiErrorDialogConfig` (icon, title, message, actions)
- `ApiErrorHandler.handleHttpError()` hiển thị dialog từ NavigatorKey global
- Opt-out: `extra['skipErrorDialog'] = true` cho request cần custom handling (login)
- 401 tự động logout + navigate về SignIn

### Q7: Startup timeout và fallback storage giải quyết vấn đề gì?

**Trả lời:**
- Firebase init có thể hang trên thiết bị offline hoặc APNs không sẵn sàng
- Timeout 20s cho Firebase, 30s cho toàn bộ startup
- Nếu timeout → app vẫn chạy bình thường, chỉ thiếu Firebase features
- HydratedBloc fallback: documents → temp → InMemoryStorage
- Đảm bảo app không bao giờ bị stuck ở splash màn hình trắng

### Q8: Sự khác biệt giữa FCM foreground trên Android vs iOS?

**Trả lời:**
- **Android**: FCM foreground messages là silent → phải dùng `flutter_local_notifications` để show banner
- **iOS**: Đã có `setForegroundNotificationPresentationOptions()` → hệ thống tự show
- **QUAN TRỌNG**: Không gọi `localNotifications.show()` trên iOS → duplicate notification

### Q9: IndexedStack trong MainScreen có ưu điểm gì?

**Trả lời:**
- Giữ tất cả 4 tab trong memory → không rebuild khi switch tab
- TimesheetPage giữ nguyên state (BLoC không bị disposed)
- Nhược điểm: RAM cao hơn (4 widget tree cùng tồn tại)
- Phù hợp với app doanh nghiệp nơi performance > memory

### Q10: Bạn sẽ debug như thế nào nếu FCM không nhận được trên iOS production?

**Trả lời:**
1. Kiểm tra APNS certificate/provisioning profile có push notification entitlement
2. Check `getAPNSToken()` có trả về giá trị không
3. Kiểm tra device token đã được register lên server chưa
4. Verify Firebase Console: project settings → APNs key
5. Test bằng Firebase Console Test Message
6. Xem `docs/IOS_FCM_FIX_GUIDE.md` trong project

---

## 18. Checklist Ôn Tập

### 18.1 Architecture

- [ ] Giải thích được 3 layer và dependency rule
- [ ] Trình bày data flow của 1 use case (timesheet)
- [ ] Giải thích tại sao Entity ≠ Model
- [ ] Hiểu DataState<T> pattern (DataSuccess/DataFailed)

### 18.2 BLoC/State

- [ ] Giải thích Event → Bloc → State flow
- [ ] Giải thích Refreshing state và tại sao cần nó
- [ ] Hiểu HydratedCubit và cách serialize
- [ ] Biết khi nào dùng BLoC vs Cubit

### 18.3 Networking

- [ ] Giải thích được Dio interceptor flow
- [ ] Hiểu tại sao 4xx bị bắt trong onResponse (validateStatus < 500)
- [ ] Giải thích skipErrorDialog mechanism
- [ ] Biết được API error dialog mapping

### 18.4 Startup

- [ ] Giải thích 4 phase startup
- [ ] Tại sao HydratedStorage phải init trước (sequential)
- [ ] Giải thích InMemoryStorage fallback
- [ ] Hiểu timeout strategy

### 18.5 Firebase/Notification

- [ ] FCM foreground vs background handling
- [ ] iOS APNS token check trước FCM token
- [ ] Crashlytics: FlutterError + PlatformDispatcher
- [ ] Analytics: RouteObserver auto screen tracking

### 18.6 Technical

- [ ] Biết được tech stack + version chính
- [ ] Nêu được 3 technical debt và giải pháp
- [ ] Biết build command cho dev/prod flavor
- [ ] Giải thích Android 12 splash + iOS podfile patches

---

## 19. Quick Reference

### Files quan trọng nhất

```
lib/main.dart                          → Startup flow
lib/injection_container.dart           → DI wiring
lib/core/configs/app_config.dart       → Env config
lib/services/firebase_service.dart     → Firebase singleton
lib/services/auth_service.dart         → Session management
lib/presentation/bloc/timesheet/remote/remote_timesheet_bloc.dart → Core BLoC
lib/data/data_sources/remote/timesheet_api_service.dart           → API call
lib/data/repositories/timesheet/timesheet_repository_impl.dart    → Repo impl
lib/domain/usecases/get_timesheet.dart                            → UseCase
lib/domain/entities/timesheet/timesheet_entity.dart               → Entity
lib/data/sources/datastate.dart                                   → Result wrapper
```

### Run lệnh

```bash
# Dev mode
flutter run --flavor dev -t lib/main_dev.dart

# Prod APK
flutter build apk --flavor prod -t lib/main_prod.dart --release

# Generate code (models, retrofit)
dart run build_runner build --delete-conflicting-outputs

# Native splash
dart run flutter_native_splash:create
```

---

*📝 Tài liệu được tổng hợp từ 109 Dart files trong codebase thực tế của project flutter_core_project.*  
*Cập nhật: 20/04/2026*

