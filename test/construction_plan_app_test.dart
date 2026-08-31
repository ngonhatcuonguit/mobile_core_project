import 'package:flutter/material.dart';
import 'package:flutter_core_project/app/construction_plan_app.dart';
import 'package:flutter_core_project/features/material_library/data/material_library_store.dart';
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
    final materialStore = InMemoryMaterialLibraryStore();

    await tester.pumpWidget(
      ConstructionPlanApp(materialLibraryStore: materialStore),
    );
    await tester.pumpAndSettle();

    expect(find.text('Construction Plan'), findsOneWidget);
    expect(find.text('Nhà phố An Phú'), findsOneWidget);
    expect(find.text('Đăng nhập'), findsNothing);
    expect(find.byKey(const Key('projectCarousel')), findsOneWidget);
    expect(find.byKey(const Key('serviceList')), findsOneWidget);
    expect(find.byKey(const Key('materialsNavigationButton')), findsOneWidget);
    expect(find.byKey(const Key('quantityNavigationButton')), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Biệt thự vườn xanh'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addProjectButton')));
    await tester.pump();
    expect(
      find.text('Tính năng đang được hoàn thiện cho phiên bản tiếp theo.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const Key('materialsNavigationButton')));
    await tester.pumpAndSettle();
    expect(find.text('Thư viện vật liệu & nhân công'), findsOneWidget);
    expect(find.text('Thư viện đang trống'), findsOneWidget);

    await tester.tap(find.byKey(const Key('addLibraryItemButton')));
    await tester.pumpAndSettle();
    expect(find.text('Thêm vật liệu / nhân công'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('libraryNameField')),
      'Gạch xây',
    );
    await tester.enterText(
      find.byKey(const Key('libraryPriceField')),
      '1250',
    );
    await tester.tap(find.byKey(const Key('libraryUnitField')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tùy chỉnh...').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('libraryCustomUnitField')),
      'thùng',
    );
    await tester.ensureVisible(find.byKey(const Key('saveLibraryItemButton')));
    await tester.tap(find.byKey(const Key('saveLibraryItemButton')));
    await tester.pumpAndSettle();

    expect(find.text('Gạch xây'), findsOneWidget);
    expect(find.textContaining('1.250 ₫'), findsOneWidget);
    expect(find.text('Vật liệu'), findsWidgets);

    await tester.tap(find.text('Gạch xây'));
    await tester.pumpAndSettle();
    expect(find.text('#1'), findsOneWidget);
    expect(find.text('thùng'), findsOneWidget);

    await tester.tap(find.byKey(const Key('editFromDetailButton')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('libraryNameField')),
      'Gạch xây mới',
    );
    await tester.ensureVisible(find.byKey(const Key('saveLibraryItemButton')));
    await tester.tap(find.byKey(const Key('saveLibraryItemButton')));
    await tester.pumpAndSettle();
    expect(find.text('Gạch xây mới'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert_rounded));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa').last);
    await tester.pumpAndSettle();
    expect(find.text('Xóa khỏi thư viện?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();
    expect(find.text('Thư viện đang trống'), findsOneWidget);

    await tester.tap(find.byKey(const Key('quantityNavigationButton')));
    await tester.pumpAndSettle();
    expect(find.text('Tính khối lượng'), findsWidgets);

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

    await tester.tap(find.byKey(const Key('materialsNavigationButton')));
    await tester.pumpAndSettle();
    expect(find.text('Materials & labor library'), findsOneWidget);
    expect(find.text('Your library is empty'), findsOneWidget);
    expect(find.byKey(const Key('addLibraryItemButton')), findsOneWidget);
  });
}
