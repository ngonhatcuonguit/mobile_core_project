import 'package:flutter/material.dart';
import 'package:flutter_core_project/presentation/pages/leave_request/leave_request_page.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('unavailable leave request page only allows going back',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(builder: (_) => const LeaveRequestPage()),
              ),
              child: const Text('Mở yêu cầu nghỉ phép'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở yêu cầu nghỉ phép'));
    await tester.pumpAndSettle();

    expect(find.text('Chức năng chưa khả dụng'), findsOneWidget);
    expect(find.byKey(const ValueKey('leave_unavailable_go_back')),
        findsOneWidget);

    // Chạm ra ngoài không thể đóng warning để thao tác form phía sau.
    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();
    expect(find.text('Chức năng chưa khả dụng'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('leave_unavailable_go_back')));
    await tester.pumpAndSettle();

    expect(find.byType(LeaveRequestPage), findsNothing);
    expect(find.text('Mở yêu cầu nghỉ phép'), findsOneWidget);
  });
}
