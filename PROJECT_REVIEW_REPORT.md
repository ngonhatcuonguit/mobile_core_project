# Bao cao review tong hop du an Flutter Core Project

Ngay review: 2026-06-08
Du an: `flutter_core_project`
Ten ung dung thuc te: My THP
Pham vi review: cau truc source, pubspec, entrypoint, DI, API services, auth, Firebase/notification, timesheet, work schedule, platform config, tai lieu va test hien co.

## 1. Ket luan nhanh

Du an da vuot xa mot Flutter starter project. Code hien tai la mot ung dung noi bo doanh nghiep cho nhan vien, gom dang nhap, bang cong, yeu cau dieu chinh cong, lich su yeu cau, notification center, FCM, local notification cho lich lam viec, da ngon ngu va dark mode.

Nen uu tien xu ly 4 nhom viec truoc khi goi la san sang production:

1. Bao mat cau hinh va secret: `.env.dev`, `.env.prod`, Firebase config, NewsAPI key va token dang nam trong repo hoac duoc luu bang `SharedPreferences`.
2. Sua loi compile/test co kha nang chan CI: `WorkScheduleNotificationService` dung `Int64List` nhung thieu import, test mac dinh goi sai constructor `MyApp`.
3. Don dep kien truc API/domain: hien co nhieu duong networking song song, domain layer con import nguoc data layer.
4. Cap nhat verify toolchain: `flutter analyze` va `dart analyze` dang crash o Dart VM tren may hien tai, nen chua the co ket qua analyzer chuan.

## 2. Phat hien quan trong

### P0 - Can xu ly ngay truoc khi release

| Muc | File | Van de | Tac dong | Huong xu ly |
|---|---|---|---|---|
| Secret/API key hard-code | `lib/constants/constants.dart:3-6` | NewsAPI base URL va API key nam truc tiep trong source. | Lo key, kho rotate, moi build deu cung key. | Chuyen sang `.env`, remote config hoac backend proxy; rotate key da lo neu key that. |
| Env/Firebase config dang duoc track | `.gitignore:1-47`, `pubspec.yaml:72-78`, `lib/firebase_options.dart:36-78` | `.env.dev`, `.env.prod`, Firebase Android/iOS config dang co trong git; `.gitignore` chua ignore `.env*`, `*.jks`, `*.pem`. | Ro ri cau hinh moi truong, tang rui ro lay nham config prod/dev. | Them ignore, dung file example, rotate secret neu can; xem lai cac file da track bang `git rm --cached`. |
| Token dang luu bang SharedPreferences | `lib/services/auth_service.dart:8`, `lib/services/auth_service.dart:29-43` | JWT/auth token luu plain trong SharedPreferences. | Thiet bi bi compromise co the doc token de truy cap API. | Chuyen token sang `flutter_secure_storage`/Keychain/Keystore; giu SharedPreferences cho setting khong nhay cam. |
| Test hien tai khong compile theo app moi | `test/widget_test.dart:11-17`, `lib/main.dart:130-132` | Test goi `const MyApp()` nhung constructor yeu cau `isLoggedIn`. | CI se fail khi chay test, khong con bao ve chat luong. | Viet lai smoke test bang `MyApp(isLoggedIn: false)` hoac tach `AppRoot` co DI mock. |
| Kiem tra tu dong bi chan boi SDK | Lenh `flutter analyze`, `dart analyze` | Dart VM crash voi `cpuinfo_macos.cc:42` truoc khi analyze. | Khong co ket qua analyzer/test chinh thuc trong review nay. | Cap nhat/doi Flutter SDK, dung dung FVM 3.41.6 neu co, hoac sua toolchain macOS/x64 hien tai. |

### P1 - Nen xu ly som

| Muc | File | Van de | Tac dong | Huong xu ly |
|---|---|---|---|---|
| Loi compile tiem an trong work schedule notification | `lib/services/work_schedule_notification_service.dart:1-7`, `lib/services/work_schedule_notification_service.dart:231` | `Int64List` duoc dung nhung chua import `dart:typed_data`. | Build/analyze co the fail o file nay. | Them `import 'dart:typed_data';`. |
| Hai he networking song song | `lib/injection_container.dart:35-170`, `lib/services/dio_ultil.dart:28-45` | DI dung `_buildThpDio()` + `AppConfig`, trong khi `DioUtil` cu hard-code `https://api.thp.vn`. | De goi sai domain, sai auth style, kho debug env dev/prod. | Chon mot HTTP client chinh; deprecate hoac xoa `DioUtil` neu khong con dung. |
| Domain layer phu thuoc data layer | `lib/domain/repository/notification/notification_repository.dart:1-3`, `lib/domain/usecases/register_device_usecase.dart:1-2`, `lib/domain/usecases/submit_adjustment_report_usecase.dart:1-12` | Domain import data source/model thay vi entity/interface thuan domain. | Clean Architecture bi pha, kho test usecase/doc lap data. | Tao enum/entity/domain request rieng; usecase goi repository interface, repository impl moi dung data source. |
| RequestHistory repository dat sai layer | `lib/data/repositories/request_history/request_history_repository_impl.dart:4-21`, `lib/injection_container.dart:17`, `lib/injection_container.dart:163` | Interface repository nam trong data layer va duoc import nguoc khi DI. | Kien truc khong nhat quan, kho mock/usecase. | Chuyen interface sang `lib/domain/repository/request_history/`. |
| Firebase dev dang dung chung app prod | `lib/firebase_options.dart:55-78` | Dev options co TODO va dung chung appId/projectId voi prod. | Du lieu analytics/push/dev co the lan vao prod. | Tao Firebase app rieng cho dev, truyen `--dart-define=FLAVOR=dev` trong script run/build. |
| Plugin dependency duoc patch truc tiep luc build | `android/build.gradle:21-43`, `pubspec.yaml:55` | Gradle auto sua source plugin `flutter_local_notifications` de workaround API 35. | Build phu thuoc side effect, kho lap lai, co the vo khi cache/plugin thay doi. | Nang `flutter_local_notifications` len ban tuong thich va xoa auto-patch. |

### P2 - Cai thien chat luong va bao tri

| Muc | File | Van de | Tac dong | Huong xu ly |
|---|---|---|---|---|
| README van la template | `README.md:1-16` | README chua mo ta My THP, flavor, env, build, feature. | Nguoi moi vao du an mat thoi gian doc nhieu tai lieu roi. | Rut gon tu file review nay thanh README chinh. |
| Dependency version de trong nhieu cho | `pubspec.yaml:24-44`, `pubspec.yaml:64-66` | Nhieu package khong pin version cu the. | Build co the thay doi khi `pub get` tren moi truong moi. | Pin version theo `pubspec.lock` hoac range co chu dich. |
| `print()` trong repository | `lib/data/repositories/news/article_repository_impl.dart:18-63` | Log bang `print`, co in prefix API key. | Vi pham lint, co rui ro log thong tin nhay cam. | Dung `debugPrint` trong debug va bo log key. |
| Main entrypoint trung lap | `lib/main.dart`, `lib/main_dev.dart`, `lib/main_prod.dart` | Nhieu code khoi tao lap lai; `main.dart` khong load `.env`, `main_dev/prod` khong init `NetworkService`. | De drift logic giua default/dev/prod. | Tao `bootstrap({envFile, showDebugBanner, wrapNetworkBanner})`. |
| Bloc dang register singleton | `lib/injection_container.dart:168-169`, `lib/main.dart:140-143` | Bloc la stateful object nhung duoc dang ky singleton. | De giu state qua man hinh/account, dong mo lifecycle kho kiem soat. | Dung `registerFactory` cho Bloc neu khong can global cache; neu can cache, tach cache service rieng. |
| Work schedule ignore state chua duoc dung | `lib/services/work_schedule_notification_service.dart:252-267` | `_isCheckInReminderIgnored()` duoc tao nhung khong tham gia logic schedule/show. | Chuc nang ignore co the khong co hieu qua that. | Tich hop check ignore vao luong hien notification hoac xoa neu chua dung. |

## 3. Tong quan san pham

My THP la ung dung noi bo, huong den nhan vien doanh nghiep. Cac nhom tinh nang chinh:

- Auth: dang nhap noi bo bang username/password, luu session va token.
- Timesheet: xem bang cong theo thang, cache in-memory, chon ngay, xem checking points.
- Adjustment Report: gui yeu cau dieu chinh cong len API.
- Request History: xem lich su yeu cau, phan trang, xem chi tiet.
- Notification Center: danh sach thong bao, unread count, mark as read.
- Push notification: Firebase Messaging, foreground/background/terminated handling, register device token len backend.
- Work Schedule: cau hinh ca lam viec va nhac check-in/check-out/di tre/tang ca bang local notification.
- UI setting: dark mode, ngon ngu Anh/Viet, splash/native branding.
- Observability: Firebase Analytics va Crashlytics.

## 4. Stack ky thuat

| Nhom | Cong nghe |
|---|---|
| Framework | Flutter, Dart |
| State management | `bloc`, `flutter_bloc`, `hydrated_bloc` |
| DI | `get_it` |
| Networking | `dio`, `retrofit`, mot phan legacy `http`/`DioUtil` |
| Local persistence | `shared_preferences`, `hydrated_bloc`, local JSON |
| Firebase | Core, Messaging, Analytics, Crashlytics |
| Notification | `flutter_local_notifications`, `timezone` |
| UI/assets | SVG, custom fonts Be Vietnam Pro/Satoshi, native splash |
| Platform | Android flavor dev/prod, iOS schemes dev/prod |

## 5. Cau truc thu muc dang co

```text
lib/
  main.dart
  main_dev.dart
  main_prod.dart
  injection_container.dart
  firebase_options.dart
  core/configs/
  constants/
  data/
    data_sources/remote/
    models/
    repositories/
    sources/
  domain/
    entities/
    repository/
    usecases/
  presentation/
    auth/
    bloc/
    choose_mode/
    pages/
    widgets/
  services/
  utils/
  l10n/

docs/
android/
ios/
assets/
test/
```

Nhan xet:

- Y tuong Clean Architecture da co: `data`, `domain`, `presentation`.
- DI tap trung o `injection_container.dart`, giup khoi tao service/repository/usecase/bloc tu mot diem.
- Mot so ranh gioi layer chua sach: domain import data, usecase goi data source truc tiep, interface repository cua request history nam trong data.

## 6. Luong khoi dong ung dung

Luong chinh cua `main_dev.dart` va `main_prod.dart`:

1. `WidgetsFlutterBinding.ensureInitialized()`.
2. Giu native splash bang `FlutterNativeSplash.preserve`.
3. Load `.env.dev` hoac `.env.prod`.
4. Khoi tao `HydratedBloc.storage` truoc khi tao `ThemeCubit`/`LocaleCubit`.
5. Khoi tao Firebase va DI song song.
6. Inject `NotificationApiService` vao `FirebaseService`.
7. Kiem tra `AuthService.isLoggedIn()`.
8. Neu da dang nhap, dang ky lai FCM token.
9. Remove splash va render `MyApp`.

Luong `main.dart` co them `NetworkService().init()` va `NetworkStatusBanner`, nhung khong load `.env`. Neu team dung flavor, nen can nhac bo `main.dart` khoi duong production hoac bien no thanh wrapper goi `bootstrap`.

## 7. Networking va API

### Client chinh

`_buildThpDio()` trong `injection_container.dart` la client nen xem la chuan hien tai:

- Base URL lay tu `AppConfig.baseUrl`.
- Timeout lay tu `AppConfig.timeoutMs`.
- Tu dong gan `Authorization: Bearer <token>`.
- Tap trung xu ly HTTP 4xx/5xx va network error.
- Cho phep request opt-out dialog bang `options.extra['skipErrorDialog']`.

### API services chinh

| Service | Vai tro |
|---|---|
| `LoginApiService` | POST `/api/account/internallogin` |
| `TimesheetApiService` | POST `/api/employee/timeesheet` |
| `NotificationApiService` | get message, unread count, mark read, register FCM token |
| `AdjustmentReportApiService` | POST `/api/employee/requestadjust` |
| `RequestHistoryApiService` | lay lich su yeu cau |
| `NewsApiService` | Retrofit client toi NewsAPI |

### Diem can chuan hoa

- `DioUtil` cu hard-code domain rieng va auth bang query token, khac client chinh.
- NewsAPI dung endpoint/constant rieng, khong qua `AppConfig`.
- Mot so API service tra fallback rong khi loi, vi du notification. Cach nay giup UI khong crash nhung co the che mat loi backend.

## 8. Authentication va session

Luong dang nhap:

1. `SigninPage` validate username/password.
2. Goi `LoginApiService.login`.
3. Neu thanh cong, luu thong tin vao `AuthService`.
4. Goi `FirebaseService.registerCurrentDevice()` de bind FCM token voi account.
5. Navigate sang `MainScreen`.

Diem tot:

- Password duoc mask khi log request.
- Login opt-out global error dialog de UI tu hien loi credentials.
- Co bat cac loi Dio, TLS, Socket, IO khac nhau.

Diem can sua:

- Token dang luu bang SharedPreferences.
- `AuthService.clearAll()` xoa toan bo SharedPreferences, co the xoa ca setting/language/theme neu bi goi nham.
- Nen tach `SessionStorage` bao mat va `UserPreferenceStorage` khong bao mat.

## 9. Timesheet

Luong du lieu:

```text
TimesheetPage
  -> RemoteTimesheetBloc
  -> GetTimesheetUseCase
  -> TimesheetRepository
  -> TimesheetRepositoryImpl
  -> TimesheetApiService
  -> THP API
```

Diem tot:

- Bloc co cache in-memory theo key `year-month`.
- Khong goi API cho thang tuong lai, tra entity rong.
- Co state `TimesheetRefreshing` de giu UI cu khi reload.
- Model parse duoc envelope API long nhau `{status, data: {status, data}}`.

Rui ro:

- Cache nam trong singleton Bloc, co the giu data qua user session neu dang xuat/dang nhap lai khong reset.
- Parsing DateTime trong `TimeSheetDataModel` van co diem hard fail voi `DATE_WORKING` neu backend tra null/sai format.
- Log raw response body co the rat dai va co du lieu nhan vien, can gate theo debug.

## 10. Firebase, FCM va local notification

Firebase service hien gom:

- Firebase Core init.
- Crashlytics error hooks.
- Analytics screen tracking.
- FCM permission, foreground/background handlers.
- Local notification foreground tren Android.
- Register FCM token len backend.

Diem tot:

- Co guard duplicate init.
- iOS kiem tra APNs token truoc khi lay FCM token.
- Foreground notification tranh duplicate tren iOS.
- Token refresh duoc lang nghe.

Rui ro:

- Dev/prod Firebase dang dung chung options.
- `notificationApiService` duoc inject thu cong vao singleton Firebase, de tao race condition neu init thay doi.
- FCM token dang duoc log day du o debug; nen rut gon hoac an.
- Tap notification moi TODO, chua route theo payload.

Work schedule local notification:

- Schedule check-in/check-out/late/overtime cho 7 ngay.
- Dung timezone `Asia/Ho_Chi_Minh`.
- Dung exact alarm tren Android.

Can sua truoc:

- Them import `dart:typed_data` cho `Int64List`.
- Kiem tra resource `alert_sound` tren Android/iOS co ton tai khong, neu khong alert sound co the fail/silent.
- Tich hop ignore state vao luong notification thuc su.

## 11. UI, navigation va localization

Diem tot:

- Co `ThemeCubit` va `LocaleCubit` persist bang HydratedBloc.
- `MaterialApp` co localization delegate rieng va support `en`, `vi`.
- UI dang nhap co xu ly loi ro, loading state, focus state.
- Navigation hien tai don gian, dung `Navigator` truc tiep va `NavigationService` cho global redirect.

Can cai thien:

- Navigation bang `Navigator.push` rai rac, kho trace luong man hinh lon. Nen gom route constants hoac routing package khi app lon hon.
- `NetworkStatusBanner` chi boc trong `main.dart`, khong co trong `main_dev.dart` va `main_prod.dart`.
- README va docs nen ghi ro entrypoint nao la chuan de tranh build sai.

## 12. Platform va build

Android:

- Namespace/app id: `com.digital.thp.my_thp`.
- Flavors: `dev` co suffix `.dev`, `prod` khong suffix.
- Compile SDK 36, target SDK 35.
- Co signing config doc tu `android/key.properties`.
- Co cau hinh 16 KB page size support.

iOS:

- Bundle id lay tu Xcode build setting.
- Co ATS exception cho `mobile-app.thp.com.vn`.
- Firebase swizzling tat, AppDelegate forward notification thu cong.
- Co background mode `fetch` va `remote-notification`.

Lenh chay/build nen dung:

```bash
flutter run --flavor dev -t lib/main_dev.dart --dart-define=FLAVOR=dev
flutter run --flavor prod -t lib/main_prod.dart --dart-define=FLAVOR=prod
flutter build appbundle --flavor prod -t lib/main_prod.dart --dart-define=FLAVOR=prod --release
```

Luu y: `firebase_options.dart` chon config theo `--dart-define=FLAVOR=dev|prod`; neu khong truyen, mac dinh la `prod`.

## 13. Trang thai tai lieu

Tai lieu dang co nhieu va kha phong phu:

- `docs/ENVIRONMENT_BUILD_GUIDE.md`: huong dan env/build.
- `docs/IOS_FCM_FIX_GUIDE.md`: FCM iOS.
- `docs/API_LOGGING.md`: logging API.
- `WORK_SCHEDULE_DOC.md`, `WORK_SCHEDULE_NOTIFICATION_DOC.md`: lich lam viec/notification.
- `TIMESHEET_*`: nhieu tai lieu timesheet.
- `docs/interview_review/flutter_project_review.md`: tai lieu ky thuat rat dai cho phong van.

Van de:

- README chinh van la template Flutter.
- Tai lieu bi phan manh, de trung lap va drift voi code.

De xuat:

- Bien file nay thanh index cap cao.
- README chi can gom quick start, build/run, cau truc, link den docs chuyen sau.

## 14. Trang thai test va verify

Da thu chay:

```text
flutter analyze
dart analyze
```

Ket qua:

```text
../../runtime/vm/cpuinfo_macos.cc: 42: error: unreachable code
version=3.3.0 (stable) ... on "macos_x64"
```

Nhan dinh:

- Analyzer/test khong chay duoc do Dart VM/Flutter SDK active bi crash truoc khi vao project.
- `.fvmrc` yeu cau Flutter `3.41.6`, nhung khong thay thu muc `.fvm` trong repo; `fvm flutter --version` cung crash vi dung Dart SDK hien tai.
- `test/widget_test.dart` dang la counter template va sai constructor, nen sau khi sua SDK van can viet lai test.

Test nen bo sung:

- Unit test cho `AuthService` voi SharedPreferences mock.
- Unit test cho `TimesheetModel.fromApiResponse`.
- Bloc test cho `RemoteTimesheetBloc`: future month, cache hit, failed API.
- Repository test voi Dio mock/fake response.
- Smoke widget test cho login screen va main navigation.
- Integration test login/timesheet neu co test backend hoac mock server.

## 15. Worktree va file nhay cam

Tai thoi diem review, `git status --short` co:

```text
 M .gitignore
?? assets/images/app_launcher_icon.png
?? new-upload-key.jks
?? upload_certificate.pem
```

Luu y:

- Khong nen commit `new-upload-key.jks` hoac `upload_certificate.pem`.
- `.gitignore` hien chua ignore `.env*`, `*.jks`, `*.pem`, `android/key.properties`.
- `.env.dev`, `.env.prod`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist` va `lib/constants/constants.dart` dang duoc git track.

Checklist bao mat:

```text
[ ] Them `.env*.example` va bo track `.env.dev`, `.env.prod` neu chua can commit.
[ ] Them ignore cho `*.jks`, `*.pem`, `android/key.properties`, `ios/Runner/*.p8`.
[ ] Rotate NewsAPI key neu day la key that.
[ ] Xem lai Firebase config dev/prod va tao app dev rieng.
[ ] Chuyen JWT token sang secure storage.
```

## 16. De xuat roadmap

### Ngay 1 - Sua loi chan build/CI

1. Sua `WorkScheduleNotificationService` import `dart:typed_data`.
2. Sua/xoa `test/widget_test.dart` template.
3. Sua Flutter/Dart SDK de `flutter analyze` chay duoc.
4. Chay lai `flutter analyze` va `flutter test`.

### Ngay 2 - Bao mat va cau hinh

1. Dua NewsAPI key ra env/backend.
2. Them `.gitignore` cho env/keystore/certificate.
3. Xem lai file da track va secret da lo.
4. Chuyen token sang secure storage.

### Tuan 1 - Don kien truc

1. Hop nhat networking vao mot Dio client.
2. Chuyen request history repository interface sang domain.
3. Loai domain import data layer.
4. Bien Bloc singleton thanh factory hoac tach cache service.
5. Tach bootstrap chung cho `main_dev`, `main_prod`, `main`.

### Tuan 2 - Tang do tin cay san pham

1. Them test model/repository/bloc.
2. Them mock API hoac staging test cho login/timesheet.
3. Hoan thien notification tap routing.
4. Tao Firebase dev app rieng.
5. Cap nhat README chinh va gom link tai lieu.

## 17. Danh gia tong the

| Tieu chi | Danh gia |
|---|---|
| Do day tinh nang | Kha day du cho app noi bo HR/attendance |
| Kien truc | Co nen Clean Architecture nhung can lam sach boundary |
| Networking | Co central Dio tot, nhung con legacy client |
| Auth/security | Dang chay duoc, can nang cap bao mat token/secret |
| Notification | Da xu ly nhieu case FCM, can hoan thien route/payload/dev-prod |
| Test | Yeu, test hien tai la template va dang sai voi app hien tai |
| Documentation | Nhieu tai lieu, nhung README chinh chua dai dien cho du an |
| Release readiness | Chua nen release production truoc khi xu ly P0/P1 |

## 18. File nen doc dau tien khi onboard

1. `PROJECT_REVIEW_REPORT.md` - file tong hop nay.
2. `docs/ENVIRONMENT_BUILD_GUIDE.md` - env va build flavor.
3. `lib/main_dev.dart`, `lib/main_prod.dart` - entrypoint.
4. `lib/injection_container.dart` - DI va Dio interceptor.
5. `lib/services/firebase_service.dart` - Firebase/FCM.
6. `lib/presentation/bloc/timesheet/remote/remote_timesheet_bloc.dart` - logic timesheet.
7. `lib/data/data_sources/remote/*_api_service.dart` - API contract.
8. `docs/interview_review/flutter_project_review.md` - ban giai thich ky thuat rat chi tiet.

## 19. Checklist truoc khi ban giao/release

```text
[ ] `flutter analyze` pass.
[ ] `flutter test` pass.
[ ] Khong con test template counter.
[ ] Khong commit keystore/certificate/env secret.
[ ] API key/token khong log ra console.
[ ] Dev/prod Firebase tach biet.
[ ] Build dev/prod dung `--dart-define=FLAVOR`.
[ ] Dang nhap, bang cong, submit adjustment, notification center da test tren device that.
[ ] iOS FCM da test APNs tren device that, khong chi simulator.
[ ] Android exact alarm/notification permission da test tren Android 13+.
[ ] README duoc cap nhat de nguoi moi co the run app trong 10 phut.
```

