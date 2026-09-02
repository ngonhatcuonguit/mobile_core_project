import 'package:flutter/material.dart';
import 'package:flutter_core_project/app/construction_plan_app.dart';
import 'package:flutter_core_project/features/material_library/data/material_library_store.dart';
import 'package:flutter_core_project/features/projects/data/project_store.dart';
import 'package:flutter_core_project/utils/in_memory_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

void main() {
  testWidgets(
      'new project wizard saves a complete project to the home carousel',
      (tester) async {
    tester.view.physicalSize = const Size(430, 932);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    HydratedBloc.storage = InMemoryStorage();

    await tester.pumpWidget(
      ConstructionPlanApp(
        materialLibraryStore: InMemoryMaterialLibraryStore(),
        projectStore: InMemoryProjectStore(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('addProjectButton')));
    await tester.pumpAndSettle();

    final viewportHeight =
        tester.view.physicalSize.height / tester.view.devicePixelRatio;
    final nextButtonBottom = tester
        .getBottomRight(find.byKey(const Key('projectWizardNextButton')))
        .dy;
    expect(viewportHeight - nextButtonBottom, greaterThanOrEqualTo(20));

    await tester.enterText(
      find.byKey(const Key('projectNameField')),
      'Nhà phố kiểm thử',
    );
    await tester.tap(find.byKey(const Key('projectImagePicker')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('projectImageGalleryOption')), findsOneWidget);
    expect(find.byKey(const Key('projectImageCameraOption')), findsOneWidget);
    Navigator.of(
      tester.element(find.byKey(const Key('projectImageGalleryOption'))),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('projectLocationField')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('provinceSearchField')),
      'ho chi minh',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('province_ho_chi_minh_city')));
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('districtSearchField')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('districtSearchField')),
      'thu duc',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('district_769')));
    await tester.pumpAndSettle();
    expect(find.text('Thành phố Hồ Chí Minh'), findsOneWidget);
    expect(find.text('Thành phố Thủ Đức'), findsOneWidget);

    await tester.tap(find.byKey(const Key('projectLocationField')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('province_ho_chi_minh_city')),
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsOneWidget,
    );
    Navigator.of(
      tester.element(
        find.byKey(const Key('province_ho_chi_minh_city')),
      ),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('projectDistrictField')));
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('district_769')),
        matching: find.byIcon(Icons.check_circle_rounded),
      ),
      findsOneWidget,
    );
    Navigator.of(
      tester.element(find.byKey(const Key('district_769'))),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('projectWizardNextButton')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('floor1LengthField')),
      '10',
    );
    await tester.enterText(
      find.byKey(const Key('floor1WidthField')),
      '5',
    );
    await tester.enterText(
      find.byKey(const Key('floor1HeightField')),
      '3.3',
    );
    await tester.enterText(
      find.byKey(const Key('roofLengthField')),
      '10',
    );
    await tester.enterText(
      find.byKey(const Key('roofWidthField')),
      '5',
    );
    await tester.enterText(
      find.byKey(const Key('roofHeightField')),
      '0.3',
    );
    await tester.tap(find.byKey(const Key('projectWizardNextButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Móng băng'));
    await tester.pump();
    await tester.tap(find.text('Bê tông cốt thép'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('projectWizardNextButton')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(
      find.byKey(const Key('projectMaterial_catalog:brick')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('projectMaterial_catalog:brick')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('projectWizardNextButton')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('addFoundationSegmentButton')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('saveProjectButton')));
    await tester.pumpAndSettle();

    expect(find.text('Nhà phố kiểm thử'), findsOneWidget);
    expect(find.text('Thành phố Thủ Đức, Thành phố Hồ Chí Minh'), findsWidgets);
    expect(find.text('Đã tạo dự án mới.'), findsOneWidget);
  });
}
