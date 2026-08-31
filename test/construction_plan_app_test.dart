import 'package:flutter/material.dart';
import 'package:flutter_core_project/app/construction_plan_app.dart';
import 'package:flutter_core_project/utils/in_memory_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

void main() {
  testWidgets('Construction Plan home, profile and local preferences work',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    HydratedBloc.storage = InMemoryStorage();

    await tester.pumpWidget(const ConstructionPlanApp());
    await tester.pumpAndSettle();

    expect(find.text('Construction Plan'), findsOneWidget);
    expect(find.text('Nhà phố An Phú'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsNothing);
    expect(find.byKey(const Key('projectCarousel')), findsOneWidget);
    expect(find.byKey(const Key('serviceList')), findsOneWidget);

    await tester.tap(find.byKey(const Key('addProjectButton')));
    await tester.pump();
    expect(
      find.text('Tính năng đang được hoàn thiện cho phiên bản tiếp theo.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('profileNavigationButton')));
    await tester.pumpAndSettle();
    expect(find.text('Hồ sơ'), findsOneWidget);

    await tester.tap(find.byKey(const Key('languageSwitch')));
    await tester.pumpAndSettle();
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('English'), findsOneWidget);

    await tester.tap(find.byKey(const Key('themeSwitch')));
    await tester.pumpAndSettle();
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);
    expect(find.text('Dark mode'), findsOneWidget);
  });
}
