import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_core_project/data/data_sources/remote/login_api_service.dart';
import 'package:flutter_core_project/data/models/auth/login_model.dart';
import 'package:flutter_core_project/presentation/auth/pages/sign_in.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('login loading overlay locks the whole form', (tester) async {
    final api = _PendingLoginApiService();
    await tester.pumpWidget(
      MaterialApp(home: SigninPage(apiService: api)),
    );
    await tester.pumpAndSettle();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '43950');
    await tester.enterText(fields.at(1), 'secret');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.pump();

    expect(api.callCount, 1);
    expect(
      find.byKey(const ValueKey('login_loading_overlay')),
      findsOneWidget,
    );
    expect(tester.widget<TextField>(fields.at(0)).focusNode!.hasFocus, isFalse);
    expect(tester.widget<TextField>(fields.at(1)).focusNode!.hasFocus, isFalse);

    await tester.tap(fields.at(0), warnIfMissed: false);
    await tester.pump();
    expect(tester.widget<TextField>(fields.at(0)).focusNode!.hasFocus, isFalse);
    expect(tester.widget<TextField>(fields.at(0)).controller!.text, '43950');

    api.complete(
      const LoginResponse(isSuccess: false, message: 'Sai thông tin'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('login_loading_overlay')), findsNothing);
    expect(find.text('Sai thông tin'), findsOneWidget);
  });
}

class _PendingLoginApiService extends LoginApiService {
  _PendingLoginApiService() : super(Dio());

  final Completer<LoginResponse> _completer = Completer<LoginResponse>();
  int callCount = 0;

  @override
  Future<LoginResponse> login({
    required String userName,
    required String password,
  }) {
    callCount++;
    return _completer.future;
  }

  void complete(LoginResponse response) => _completer.complete(response);
}
