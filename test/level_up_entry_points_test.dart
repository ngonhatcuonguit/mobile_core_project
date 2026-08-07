import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_core_project/data/data_sources/remote/level_up_api_service.dart';
import 'package:flutter_core_project/data/models/level_up/level_up_models.dart';
import 'package:flutter_core_project/injection_container.dart';
import 'package:flutter_core_project/presentation/pages/home/widgets/home_all_menu_sheet.dart';
import 'package:flutter_core_project/presentation/pages/level_up/level_up_exam_list_page.dart';
import 'package:flutter_core_project/presentation/pages/service/service_page.dart';
import 'package:flutter_core_project/services/level_up_local_store.dart';
import 'package:flutter_core_project/services/localization_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'user_email': 'assessor@thp.com.vn',
    });
    await sl.reset();
    sl.registerSingleton<LevelUpApiService>(_EntryPointApi());
    await LevelUpLocalStore().saveFilter(
      'assessor@thp.com.vn',
      const LevelUpFilter(
        factoryId: 10,
        factoryName: 'Bình Dương',
        levelId: 1,
        levelCode: 'level1',
        levelName: 'Cấp 1',
        lineId: 50,
        lineName: 'Line Aseptic',
        machineId: 726,
        machineName: 'Máy thổi',
      ),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('service card is localized and opens the LevelUp exam list',
      (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        locale: const Locale('vi'),
        home: const ServicePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chấm điểm LevelUp'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Chấm điểm LevelUp'));
    await tester.pumpAndSettle();

    expect(find.byType(LevelUpExamListPage), findsOneWidget);
    expect(find.text('Chưa có bài thi cần chấm'), findsOneWidget);
    expect(tester.takeException(), isNull);

    Navigator.of(tester.element(find.byType(LevelUpExamListPage))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(ServicePage), findsOneWidget);
  });

  testWidgets('service card uses its English entry label', (tester) async {
    await tester.pumpWidget(
      _localizedApp(
        locale: const Locale('en'),
        home: const ServicePage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LevelUp Grading'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'all-functions sheet stays usable on a small screen and routes correctly',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 480);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      _plainApp(
        textScale: 1.6,
        home: const _OpenAllFunctionsHost(),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('open_all_functions')));
    await tester.pumpAndSettle();

    expect(find.text('menu_levelup_grading'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('menu_levelup_grading'));
    await tester.pumpAndSettle();

    expect(find.byType(LevelUpExamListPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _OpenAllFunctionsHost extends StatelessWidget {
  const _OpenAllFunctionsHost();

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: ElevatedButton(
            key: const ValueKey('open_all_functions'),
            onPressed: () => showAllMenuSheet(context),
            child: const Text('Open'),
          ),
        ),
      );
}

Widget _localizedApp({
  required Locale locale,
  required Widget home,
  double textScale = 1,
}) {
  return MaterialApp(
    key: ValueKey('${locale.languageCode}-${home.runtimeType}'),
    locale: locale,
    supportedLocales: const [Locale('vi'), Locale('en')],
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: home,
  );
}

Widget _plainApp({
  required Widget home,
  double textScale = 1,
}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: home,
  );
}

class _EntryPointApi extends LevelUpApiService {
  _EntryPointApi() : super(Dio());

  @override
  Future<List<LevelUpFactory>> getFactories({required String email}) async =>
      const [
        LevelUpFactory(id: 10, code: 'BD', name: 'Bình Dương'),
      ];

  @override
  Future<List<LevelUpLevel>> getLevels() async => const [
        LevelUpLevel(id: 1, code: 'level1', name: 'Cấp 1'),
      ];

  @override
  Future<List<LevelUpLine>> getLines({required int factoryId}) async => const [
        LevelUpLine(
          id: 50,
          factoryId: 10,
          code: 'Line003',
          name: 'Line Aseptic',
        ),
      ];

  @override
  Future<List<LevelUpMachine>> getMachines({required int lineId}) async =>
      const [
        LevelUpMachine(
          id: 726,
          lineId: 50,
          code: 'Machine115',
          name: 'Máy thổi',
          levelApply: 'level1,level2,level3,level4',
          isActive: true,
        ),
      ];

  @override
  Future<List<LevelUpPracticalExam>> getPracticalExams({
    required LevelUpFilter filter,
    required LevelUpExamStatus status,
  }) async =>
      const [];
}
