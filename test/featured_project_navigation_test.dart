import 'package:flutter/material.dart';
import 'package:flutter_core_project/app/construction_plan_app.dart';
import 'package:flutter_core_project/features/material_library/data/material_library_store.dart';
import 'package:flutter_core_project/features/projects/data/project_store.dart';
import 'package:flutter_core_project/utils/in_memory_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

void main() {
  testWidgets('opens and edits featured slider projects', (tester) async {
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

    expect(find.text('Nhà phố An Phú'), findsOneWidget);
    await tester.tap(find.text('Nhà phố An Phú'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('projectDetailPage')), findsOneWidget);
    expect(find.text('Nhà phố An Phú'), findsWidgets);
    expect(find.text('Tổng quan công trình'), findsOneWidget);
    expect(find.byIcon(Icons.edit_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Chỉnh sửa công trình'), findsOneWidget);
    expect(find.byKey(const Key('projectNameField')), findsOneWidget);
  });
}
