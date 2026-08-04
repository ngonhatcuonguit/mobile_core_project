import 'package:flutter_core_project/data/models/level_up/level_up_models.dart';
import 'package:flutter_core_project/services/level_up_local_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LevelUpLocalStore store;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    store = LevelUpLocalStore();
  });

  group('LevelUpLocalStore filters', () {
    test('round-trips the latest complete filter for a normalized account',
        () async {
      const filter = LevelUpFilter(
        factoryId: 10,
        factoryName: 'Bình Dương',
        levelId: 3,
        levelCode: 'level3',
        levelName: 'Cấp 3',
        lineId: 50,
        lineName: 'Line Aseptic',
        machineId: 73,
        machineName: 'Máy chiết',
      );
      final beforeSave = DateTime.now();

      await store.saveFilter(' Assessor@THP.com.vn ', filter);
      final restored = await store.loadFilter('assessor@thp.com.vn');
      final afterLoad = DateTime.now();

      expect(restored, isNotNull);
      expect(restored!.factoryId, filter.factoryId);
      expect(restored.factoryName, filter.factoryName);
      expect(restored.levelId, filter.levelId);
      expect(restored.levelCode, filter.levelCode);
      expect(restored.levelName, filter.levelName);
      expect(restored.lineId, filter.lineId);
      expect(restored.lineName, filter.lineName);
      expect(restored.machineId, filter.machineId);
      expect(restored.machineName, filter.machineName);
      expect(restored.canLoadExams, isTrue);
      expect(restored.savedAt, isNotNull);
      expect(restored.savedAt!.isBefore(beforeSave), isFalse);
      expect(restored.savedAt!.isAfter(afterLoad), isFalse);
    });

    test('returns null and removes a malformed filter snapshot', () async {
      const email = 'assessor@thp.com.vn';
      const key = 'level_up_filter_v1::$email';
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(key, '{not-valid-json');

      final restored = await store.loadFilter(email);

      expect(restored, isNull);
      expect(preferences.containsKey(key), isFalse);
    });

    test('keeps filters isolated between examiner accounts', () async {
      const firstFilter = LevelUpFilter(
        factoryId: 10,
        factoryName: 'Bình Dương',
        levelId: 1,
        levelName: 'Cấp 1',
        lineId: 48,
        lineName: 'Bao bì thứ cấp',
      );
      const secondFilter = LevelUpFilter(
        factoryId: 20,
        factoryName: 'Hà Nam',
        levelId: 4,
        levelName: 'Cấp 4',
        lineId: 81,
        lineName: 'Động lực',
        machineId: 99,
        machineName: 'Máy nén',
      );

      await store.saveFilter('first@thp.com.vn', firstFilter);
      await store.saveFilter('second@thp.com.vn', secondFilter);

      final first = await store.loadFilter('first@thp.com.vn');
      final second = await store.loadFilter('second@thp.com.vn');
      final unknown = await store.loadFilter('unknown@thp.com.vn');

      expect(first!.factoryId, 10);
      expect(first.machineId, isNull);
      expect(second!.factoryId, 20);
      expect(second.machineId, 99);
      expect(unknown, isNull);
    });
  });

  group('LevelUpLocalStore score drafts', () {
    test('round-trips a draft and scopes it by account and exam', () async {
      final draft = LevelUpScoreSubmission(
        examId: 'exam-9001',
        candidateId: 'employee-43950',
        examinerEmail: 'Assessor@THP.com.vn',
        items: const [
          LevelUpScoreItem(
            criterionId: '101',
            criterionName: 'An toàn',
            score: 4,
            maxScore: 5,
            note: 'Cần kiểm tra lại',
          ),
        ],
        totalScore: 4,
        overallNote: 'Bản nháp',
        gradedAt: DateTime.utc(2026, 8, 4, 2, 30),
      );

      await store.saveDraft(draft);

      final restored =
          await store.loadDraft(' assessor@thp.com.vn ', 'exam-9001');
      final otherAccount =
          await store.loadDraft('other@thp.com.vn', 'exam-9001');
      final otherExam =
          await store.loadDraft('assessor@thp.com.vn', 'exam-9002');

      expect(restored, isNotNull);
      expect(restored!.examId, draft.examId);
      expect(restored.candidateId, draft.candidateId);
      expect(restored.examinerEmail, draft.examinerEmail);
      expect(restored.totalScore, draft.totalScore);
      expect(restored.overallNote, draft.overallNote);
      expect(restored.gradedAt, draft.gradedAt);
      expect(restored.items, hasLength(1));
      expect(restored.items.single.criterionId, '101');
      expect(restored.items.single.note, 'Cần kiểm tra lại');
      expect(otherAccount, isNull);
      expect(otherExam, isNull);
    });

    test('deletes only the requested score draft', () async {
      LevelUpScoreSubmission draft(String examId) => LevelUpScoreSubmission(
            examId: examId,
            examinerEmail: 'assessor@thp.com.vn',
            items: const <LevelUpScoreItem>[],
            totalScore: 0,
            gradedAt: DateTime.utc(2026, 8, 4),
          );

      await store.saveDraft(draft('exam-1'));
      await store.saveDraft(draft('exam-2'));
      await store.deleteDraft('assessor@thp.com.vn', 'exam-1');

      expect(await store.loadDraft('assessor@thp.com.vn', 'exam-1'), isNull);
      expect(await store.loadDraft('assessor@thp.com.vn', 'exam-2'), isNotNull);
    });

    test('removes a draft whose payload identity does not match its key',
        () async {
      const email = 'assessor@thp.com.vn';
      const examId = 'exam-expected';
      const key = 'level_up_score_draft_v1::$email::$examId';
      final preferences = await SharedPreferences.getInstance();
      final wrongDraft = LevelUpScoreSubmission(
        examId: 'exam-other',
        examinerEmail: email,
        items: const [],
        totalScore: 0,
        gradedAt: DateTime.utc(2026, 8, 4),
      );
      await preferences.setString(
        key,
        '{"version":1,"draft":${wrongDraft.encode()}}',
      );

      expect(await store.loadDraft(email, examId), isNull);
      expect(preferences.containsKey(key), isFalse);
    });

    test('removes a draft stored with an unsupported schema version', () async {
      const email = 'assessor@thp.com.vn';
      const examId = 'exam-versioned';
      const key = 'level_up_score_draft_v1::$email::$examId';
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        key,
        '{"version":999,"draft":{"ExamId":"$examId"}}',
      );

      expect(await store.loadDraft(email, examId), isNull);
      expect(preferences.containsKey(key), isFalse);
    });
  });
}
