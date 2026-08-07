import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_core_project/data/data_sources/remote/level_up_api_service.dart';
import 'package:flutter_core_project/data/models/level_up/level_up_models.dart';
import 'package:flutter_core_project/presentation/pages/level_up/level_up_exam_detail_page.dart';
import 'package:flutter_core_project/presentation/pages/level_up/level_up_exam_list_page.dart';
import 'package:flutter_core_project/presentation/pages/level_up/level_up_filter_page.dart';
import 'package:flutter_core_project/presentation/pages/level_up/level_up_practical_detail_page.dart';
import 'package:flutter_core_project/services/level_up_local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('filter flow enables apply only after all four selections',
      (tester) async {
    final api = _FakeLevelUpApiService();
    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpFilterPage(
          api: api,
          email: 'assessor@thp.com.vn',
          initialFilter: const LevelUpFilter(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    FilledButton applyButton() => tester.widget<FilledButton>(
          find.byKey(const ValueKey('levelup_apply_filter')),
        );

    expect(applyButton().onPressed, isNull);

    await tester.tap(find.byKey(const ValueKey('levelup_filter_1')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bình Dương').last);
    await tester.pumpAndSettle();

    // Mỗi lựa chọn đóng sheet hiện tại và tự mở sheet kế tiếp.
    await tester.tap(find.text('Line Aseptic').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Máy thổi').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cấp 1').last);
    await tester.pumpAndSettle();

    expect(applyButton().onPressed, isNotNull);
    expect(api.requestedFactoryId, 10);
    expect(api.requestedLineId, 50);
  });

  testWidgets('machine list is not filtered by the previously saved level',
      (tester) async {
    final api = _FakeLevelUpApiService();
    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpFilterPage(
          api: api,
          email: 'assessor@thp.com.vn',
          initialFilter: const LevelUpFilter(
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
        ),
      ),
    );
    await tester.pumpAndSettle();

    FilledButton applyButton() => tester.widget<FilledButton>(
          find.byKey(const ValueKey('levelup_apply_filter')),
        );
    expect(applyButton().onPressed, isNotNull);

    await tester.tap(find.byKey(const ValueKey('levelup_filter_3')));
    await tester.pumpAndSettle();
    expect(find.text('Máy thổi'), findsWidgets);
    expect(find.text('Máy đóng gói'), findsOneWidget);

    await tester.tap(find.text('Máy đóng gói'));
    await tester.pumpAndSettle();
    expect(find.text('Chọn cấp bậc'), findsOneWidget);
    await tester.tap(find.text('Cấp 2').last);
    await tester.pumpAndSettle();

    expect(applyButton().onPressed, isNotNull);
  });

  testWidgets('list uses status tabs, interactive tags, and remote detail',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'user_email': 'assessor@thp.com.vn',
    });
    final api = _FakeLevelUpApiService();
    final store = LevelUpLocalStore();
    await store.saveFilter(
      'assessor@thp.com.vn',
      const LevelUpFilter(
        factoryId: 10,
        factoryName: 'Bình Dương',
        lineId: 50,
        lineName: 'Line Aseptic',
        machineId: 562,
        machineName: 'Máy in màng',
        levelId: 1,
        levelCode: 'level1',
        levelName: 'Cấp 1',
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpExamListPage(api: api, localStore: store),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Bài thi #2SPR'), findsOneWidget);
    expect(find.text('ádasdasdasdasd'), findsOneWidget);
    expect(find.text('Lê Văn Tuấn'), findsOneWidget);
    expect(find.text('Mã thí sinh: 777'), findsOneWidget);
    expect(find.text('Máy in màng'), findsWidgets);
    expect(find.byType(TextField), findsNothing);
    expect(api.requestedStatuses, [LevelUpExamStatus.registered]);
    expect(find.byKey(const ValueKey('levelup_total_score')), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('levelup_status_SUBMITTED')),
    );
    await tester.pumpAndSettle();
    expect(api.requestedStatuses.last, LevelUpExamStatus.submitted);
    expect(find.byKey(const ValueKey('levelup_total_score')), findsOneWidget);
    expect(find.text('12.5'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('levelup_filter_tag_machine')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Chọn máy'), findsOneWidget);
    await tester.tap(find.text('Máy in màng').last);
    await tester.pumpAndSettle();
    expect(find.text('Chọn cấp bậc'), findsOneWidget);
    await tester.tap(find.text('Cấp 1').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('ádasdasdasdasd'));
    await tester.pumpAndSettle();

    expect(find.byType(LevelUpPracticalDetailPage), findsOneWidget);
    expect(find.text('Câu hỏi 1'), findsOneWidget);
    expect(find.text('Đáp án 1'), findsOneWidget);
    expect(find.text('Đáp án gợi ý'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('levelup_remote_score_6')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('levelup_question_body_6')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('levelup_question_body_7')),
      findsNothing,
    );
    final htmlImage = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('levelup_html_image_');
    });
    expect(htmlImage, findsOneWidget);

    await tester.drag(
      find.byType(Scrollable).first,
      const Offset(0, -180),
    );
    await tester.pumpAndSettle();
    final detailScroll = tester.state<ScrollableState>(
      find.byType(Scrollable).first,
    );
    final offsetBeforeViewer = detailScroll.position.pixels;
    expect(offsetBeforeViewer, greaterThan(0));
    await tester.tap(htmlImage);
    await tester.pumpAndSettle();
    expect(find.text('Xem hình ảnh'), findsOneWidget);
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(
      detailScroll.position.pixels,
      closeTo(offsetBeforeViewer, 0.5),
    );
  });

  testWidgets('remote detail warns about zero scores and blocks double submit',
      (tester) async {
    final api = _FakeLevelUpApiService();
    api.submitGate = Completer<void>();
    final summary = LevelUpPracticalExam.fromJson({
      'FixedExamPracticalID': 1,
      'CandidateName': 'Lê Văn Tuấn',
      'FixedExamPracticalName': 'Bài thực hành',
    });
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: FilledButton(
              key: const ValueKey('open_remote_detail'),
              onPressed: () => Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => LevelUpPracticalDetailPage(
                    api: api,
                    practicalId: 1,
                    summary: summary,
                  ),
                ),
              ),
              child: const Text('Mở chi tiết mới'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open_remote_detail')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('levelup_remote_score_6')),
      '5',
    );
    await tester.pump();
    expect(find.text('5 / 223'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('levelup_question_toggle_7')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(
      find.byKey(const ValueKey('levelup_question_toggle_7')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('levelup_question_body_6')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('levelup_question_body_7')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const ValueKey('levelup_remote_score_7')),
      '',
    );
    await tester.pump();
    expect(
      tester
          .state<ScrollableState>(find.byType(Scrollable).first)
          .position
          .pixels,
      greaterThan(0),
    );
    await tester.tap(find.byKey(const ValueKey('levelup_complete_grading')));
    await tester.pumpAndSettle();

    expect(find.text('1 câu có điểm 0'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('levelup_confirm_submit')));
    await tester.pump();

    expect(find.text('Đang gửi điểm bài thi...'), findsOneWidget);
    expect(api.submitCallCount, 1);
    expect(api.submittedScores, hasLength(2));
    expect(api.submittedScores.first.score, 5);
    expect(api.submittedScores.last.score, 0);

    await tester.tap(
      find.byKey(const ValueKey('levelup_complete_grading')),
      warnIfMissed: false,
    );
    await tester.pump();
    expect(api.submitCallCount, 1);

    api.submitGate!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Đã hoàn thành chấm bài'), findsOneWidget);
    await tester.tap(find.text('Đóng'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('open_remote_detail')), findsOneWidget);
  });

  testWidgets('detail validates score and stores a per-exam draft',
      (tester) async {
    final store = LevelUpLocalStore();
    final exam = LevelUpPracticalExam.fromJson({
      'PracticalExamId': 9001,
      'CandidateName': 'Nguyễn Văn A',
      'CandidateCode': '43950',
      'ExamName': 'Vận hành máy thổi',
      'Questions': [
        {
          'QuestionId': 101,
          'Question': 'Kiểm tra an toàn',
          'MaxScore': 5,
        },
      ],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpExamDetailPage(
          exam: exam,
          examinerEmail: 'assessor@thp.com.vn',
          localStore: store,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scoreField = find.byKey(const ValueKey('levelup_score_101'));
    await tester.enterText(scoreField, '6');
    await tester.tap(find.byKey(const ValueKey('levelup_save_draft')));
    await tester.pump();
    expect(find.textContaining('phải từ 0 đến 5'), findsOneWidget);
    expect(await store.loadDraft('assessor@thp.com.vn', '9001'), isNull);

    await tester.enterText(scoreField, '4.5');
    await tester.tap(find.byKey(const ValueKey('levelup_save_draft')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    final draft = await store.loadDraft('assessor@thp.com.vn', '9001');
    expect(draft, isNotNull);
    expect(draft!.totalScore, 4.5);
    expect(draft.items.single.criterionId, '101');
    expect(draft.items.single.score, 4.5);
  });

  testWidgets('tapping an exam image opens a zoomable fullscreen viewer',
      (tester) async {
    final exam = LevelUpPracticalExam.fromJson({
      'PracticalExamId': 9002,
      'CandidateName': 'Nguyễn Văn B',
      'ExamName': 'Bài thi có ảnh',
      'Images': ['https://example.invalid/evidence.jpg'],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpExamDetailPage(
          exam: exam,
          examinerEmail: 'assessor@thp.com.vn',
          localStore: LevelUpLocalStore(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byKey(const ValueKey('levelup_image_0')).first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(InteractiveViewer), findsOneWidget);
    expect(find.text('1/1'), findsOneWidget);
  });

  testWidgets('detail blocks draft scoring when backend omits the score scale',
      (tester) async {
    final exam = LevelUpPracticalExam.fromJson({
      'PracticalExamId': 9003,
      'CandidateName': 'Nguyễn Văn C',
      'Questions': [
        {'QuestionId': 201, 'Question': 'Tiêu chí chưa cấu hình'},
      ],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpExamDetailPage(
          exam: exam,
          examinerEmail: 'assessor@thp.com.vn',
          localStore: LevelUpLocalStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scoreField = tester.widget<TextField>(
      find.byKey(const ValueKey('levelup_score_201')),
    );
    final saveButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('levelup_save_draft')),
    );
    expect(scoreField.enabled, isFalse);
    expect(saveButton.onPressed, isNull);
    expect(find.textContaining('khóa để tránh chấm sai'), findsOneWidget);
  });

  testWidgets('detail does not drop a criterion note without its score',
      (tester) async {
    final store = LevelUpLocalStore();
    final exam = LevelUpPracticalExam.fromJson({
      'PracticalExamId': 9004,
      'Questions': [
        {'QuestionId': 301, 'Question': 'An toàn', 'MaxScore': 5},
      ],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpExamDetailPage(
          exam: exam,
          examinerEmail: 'assessor@thp.com.vn',
          localStore: store,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('levelup_note_301')),
      'Cần nhắc nhở',
    );
    await tester.tap(find.byKey(const ValueKey('levelup_save_draft')));
    await tester.pump();

    expect(find.textContaining('nhập điểm tiêu chí 1'), findsOneWidget);
    expect(await store.loadDraft('assessor@thp.com.vn', '9004'), isNull);
  });

  testWidgets('pending backend zero does not prefill a grading field',
      (tester) async {
    final exam = LevelUpPracticalExam.fromJson({
      'PracticalExamId': 9007,
      'Status': 'Pending',
      'Score': 0,
      'Questions': [
        {
          'QuestionId': 302,
          'Question': 'An toàn',
          'MaxScore': 5,
          'ActualScore': 0,
        },
      ],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpExamDetailPage(
          exam: exam,
          examinerEmail: 'assessor@thp.com.vn',
          localStore: LevelUpLocalStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scoreField = tester.widget<TextField>(
      find.byKey(const ValueKey('levelup_score_302')),
    );
    expect(exam.isScored, isFalse);
    expect(scoreField.controller!.text, isEmpty);
  });

  testWidgets('detail blocks drafts when criterion IDs are unstable',
      (tester) async {
    final exam = LevelUpPracticalExam.fromJson({
      'PracticalExamId': 9005,
      'Questions': [
        {'Question': 'Không có ID', 'MaxScore': 5},
      ],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpExamDetailPage(
          exam: exam,
          examinerEmail: 'assessor@thp.com.vn',
          localStore: LevelUpLocalStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final saveButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('levelup_save_draft')),
    );
    final scoreField = tester.widget<TextField>(
      find.byKey(const ValueKey('levelup_score_1')),
    );
    expect(scoreField.enabled, isFalse);
    expect(saveButton.onPressed, isNull);
    expect(
      find.textContaining('mã ổn định và duy nhất cho tất cả tiêu chí'),
      findsOneWidget,
    );
  });

  testWidgets('detail blocks drafts when criterion IDs are duplicated',
      (tester) async {
    final exam = LevelUpPracticalExam.fromJson({
      'PracticalExamId': 9008,
      'Questions': [
        {'QuestionId': 501, 'Question': 'Tiêu chí A', 'MaxScore': 5},
        {'QuestionId': 501, 'Question': 'Tiêu chí B', 'MaxScore': 5},
      ],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpExamDetailPage(
          exam: exam,
          examinerEmail: 'assessor@thp.com.vn',
          localStore: LevelUpLocalStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final saveButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('levelup_save_draft')),
    );
    expect(saveButton.onPressed, isNull);
    expect(
      find.textContaining('mã ổn định và duy nhất cho tất cả tiêu chí'),
      findsOneWidget,
    );
  });

  testWidgets('detail blocks scoring when exam and criterion totals differ',
      (tester) async {
    final exam = LevelUpPracticalExam.fromJson({
      'PracticalExamId': 9009,
      'TotalMaxScore': 10,
      'Questions': [
        {'QuestionId': 601, 'Question': 'Tiêu chí A', 'MaxScore': 6},
        {'QuestionId': 602, 'Question': 'Tiêu chí B', 'MaxScore': 6},
      ],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: LevelUpExamDetailPage(
          exam: exam,
          examinerEmail: 'assessor@thp.com.vn',
          localStore: LevelUpLocalStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final scoreField = tester.widget<TextField>(
      find.byKey(const ValueKey('levelup_score_601')),
    );
    final saveButton = tester.widget<FilledButton>(
      find.byKey(const ValueKey('levelup_save_draft')),
    );
    expect(scoreField.enabled, isFalse);
    expect(saveButton.onPressed, isNull);
    expect(find.textContaining('không khớp tổng các tiêu chí'), findsOneWidget);
  });

  testWidgets('detail confirms before discarding unsaved edits',
      (tester) async {
    final exam = LevelUpPracticalExam.fromJson({
      'PracticalExamId': 9006,
      'Questions': [
        {'QuestionId': 401, 'Question': 'An toàn', 'MaxScore': 5},
      ],
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                key: const ValueKey('open_exam_detail'),
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => LevelUpExamDetailPage(
                      exam: exam,
                      examinerEmail: 'assessor@thp.com.vn',
                      localStore: LevelUpLocalStore(),
                    ),
                  ),
                ),
                child: const Text('Mở bài thi'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('open_exam_detail')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('levelup_score_401')),
      '4',
    );
    await tester.pump();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.text('Bỏ thay đổi chưa lưu?'), findsOneWidget);
    await tester.tap(find.text('Tiếp tục chấm'));
    await tester.pumpAndSettle();
    expect(find.byType(LevelUpExamDetailPage), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bỏ thay đổi'));
    await tester.pumpAndSettle();

    expect(find.byType(LevelUpExamDetailPage), findsNothing);
    expect(find.byKey(const ValueKey('open_exam_detail')), findsOneWidget);
  });
}

class _FakeLevelUpApiService extends LevelUpApiService {
  _FakeLevelUpApiService() : super(Dio());

  int? requestedFactoryId;
  int? requestedLineId;
  final List<LevelUpExamStatus> requestedStatuses = [];
  final List<LevelUpPracticalScoreRequest> submittedScores = [];
  Completer<void>? submitGate;
  int submitCallCount = 0;

  @override
  Future<List<LevelUpFactory>> getFactories({required String email}) async =>
      const [
        LevelUpFactory(
          id: 10,
          code: 'BD',
          name: 'Bình Dương',
          rolePermission: 'SupperAdmin',
        ),
      ];

  @override
  Future<List<LevelUpLevel>> getLevels() async => const [
        LevelUpLevel(id: 1, code: 'level1', name: 'Cấp 1'),
        LevelUpLevel(id: 2, code: 'level2', name: 'Cấp 2'),
      ];

  @override
  Future<List<LevelUpLine>> getLines({required int factoryId}) async {
    requestedFactoryId = factoryId;
    return const [
      LevelUpLine(
        id: 50,
        factoryId: 10,
        code: 'Line003',
        name: 'Line Aseptic',
      ),
    ];
  }

  @override
  Future<List<LevelUpMachine>> getMachines({required int lineId}) async {
    requestedLineId = lineId;
    return const [
      LevelUpMachine(
        id: 562,
        lineId: 50,
        code: 'Machine001',
        name: 'Máy in màng',
        isActive: false,
      ),
      LevelUpMachine(
        id: 726,
        lineId: 50,
        code: 'Machine115',
        name: 'Máy thổi',
        levelApply: 'level1',
        isActive: true,
      ),
      LevelUpMachine(
        id: 727,
        lineId: 50,
        code: 'Machine116',
        name: 'Máy đóng gói',
        levelApply: 'level2',
        isActive: true,
      ),
    ];
  }

  @override
  Future<List<LevelUpPracticalExam>> getPracticalExams({
    required LevelUpFilter filter,
    required LevelUpExamStatus status,
  }) async {
    requestedStatuses.add(status);
    return [
      LevelUpPracticalExam.fromJson({
        'FactoryId': 10,
        'FactoryName': 'Bình Dương',
        'LevelId': 1,
        'LevelName': 'Cấp 1',
        'LineId': 50,
        'LineName': 'Line Aseptic',
        'MachineId': 562,
        'MachineName': 'Máy in màng',
        'CandidateId': 777,
        'CandidateName': 'Lê Văn Tuấn',
        'ExamNumber': '2SPR',
        'FixedExamPracticalID': 1,
        'FixedExamPracticalName': 'ádasdasdasdasd',
        'TotalScorePractical': status == LevelUpExamStatus.submitted ? 12.5 : 0,
      }),
    ];
  }

  @override
  Future<LevelUpPracticalDetail> getPracticalDetail({
    required int practicalId,
  }) async {
    return LevelUpPracticalDetail.fromJson(
      {
        'FactoryId': 10,
        'FactoryName': 'Bình Dương',
        'LevelId': 1,
        'LevelName': 'Cấp 1',
        'LineId': 50,
        'LineName': 'Line Aseptic',
        'MachineId': 562,
        'MachineName': 'Máy in màng',
        'CandidateId': 777,
        'CandidateName': 'Lê Văn Tuấn',
        'ExamNumber': '2SPR',
        'FixedExamPracticalID': 1,
        'FixedExamPracticalName': 'ádasdasdasdasd',
        'FixedExam': {
          'Id': 1,
          'ExamTitle': 'ádasdasdasdasd',
          'Description': '<p>Mô tả bài thi</p>',
          'Questions': [
            {
              'Id': 6,
              'PracticalID': 1,
              'QuestionContent':
                  '<p>Câu hỏi 1</p><img width="4000" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVQIHWP4z8DwHwAFgAI/ScLrWQAAAABJRU5ErkJggg==">',
              'QuestionAnswer': '<p>Đáp án 1</p>',
              'ScoreLimit': 100,
              'Score': null,
            },
            {
              'Id': 7,
              'PracticalID': 1,
              'QuestionContent': '<p>Câu hỏi 2</p>',
              'QuestionAnswer': '<p>Đáp án 2</p>',
              'ScoreLimit': 123,
              'Score': null,
            },
          ],
        },
      },
      examPracticalId: practicalId,
    );
  }

  @override
  Future<void> submitPracticalScores({
    required List<LevelUpPracticalScoreRequest> scores,
  }) async {
    submitCallCount++;
    submittedScores
      ..clear()
      ..addAll(scores);
    await submitGate?.future;
  }
}
