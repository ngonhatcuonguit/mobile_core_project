import 'package:flutter/material.dart';
import 'package:flutter_core_project/presentation/pages/home/widgets/home_banner_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LevelUp capability banner fits a mobile viewport',
      (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: HomeBannerWidget()),
      ),
    );
    await tester.pump();

    expect(find.text('Thi đánh bậc năng lực chuyên môn'), findsOneWidget);
    expect(find.text('HƯỚNG TỚI OEE ≥ 95%'), findsOneWidget);
    expect(find.text('Con người là tài sản quý giá'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
  });
}
