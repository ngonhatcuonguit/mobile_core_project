import 'dart:convert';

import 'package:flutter_core_project/data/models/level_up/level_up_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LevelUp metadata models', () {
    test('parses the provided factory schema', () {
      final factory = LevelUpFactory.fromJson({
        'Candidates': <Object>[],
        'ExamConfigs': <Object>[],
        'Lines': <Object>[],
        'FactoryId': 10,
        'FactoryCode': 'BD',
        'FactoryName': 'Bình Dương',
        'RolePermission': 'SupperAdmin',
      });

      expect(factory.id, 10);
      expect(factory.code, 'BD');
      expect(factory.name, 'Bình Dương');
      expect(factory.rolePermission, 'SupperAdmin');
    });

    test('parses the provided level schema including a null description', () {
      final level = LevelUpLevel.fromJson({
        'Candidates': <Object>[],
        'ExamConfigs': <Object>[],
        'KnowledgeGroups': <Object>[],
        'LevelId': 4,
        'LevelCode': 'level4',
        'LevelName': 'Cấp 4',
        'Description': null,
      });

      expect(level.id, 4);
      expect(level.code, 'level4');
      expect(level.name, 'Cấp 4');
      expect(level.description, isNull);
    });

    test('parses the provided line schema', () {
      final line = LevelUpLine.fromJson({
        'Candidates': <Object>[],
        'ExamConfigs': <Object>[],
        'Factory': null,
        'Machines': <Object>[],
        'LineId': 50,
        'FactoryId': 10,
        'LineCode': 'Line003',
        'LineName': 'Line Aseptic',
      });

      expect(line.id, 50);
      expect(line.factoryId, 10);
      expect(line.code, 'Line003');
      expect(line.name, 'Line Aseptic');
    });

    test('parses machine values tolerantly and falls back to its code', () {
      final machine = LevelUpMachine.fromJson({
        'MACHINEID': ' 73 ',
        'lineid': 50.0,
        'machinecode': ' M-ASEPTIC-01 ',
        'MachineName': null,
      });

      expect(machine.id, 73);
      expect(machine.lineId, 50);
      expect(machine.code, 'M-ASEPTIC-01');
      expect(machine.name, 'M-ASEPTIC-01');
    });

    test('rejects zero IDs as an incomplete practical filter', () {
      const filter = LevelUpFilter(
        factoryId: 10,
        levelId: 3,
        lineId: 50,
        machineId: 0,
      );

      expect(filter.canLoadExams, isFalse);
    });

    test('honors boolean Active values', () {
      final inactive = LevelUpMachine.fromJson({
        'MachineId': 73,
        'LineId': 50,
        'MachineName': 'Máy dừng',
        'Active': false,
      });

      expect(inactive.isActive, isFalse);
    });

    test('matches LevelApply by exact level-code token', () {
      const machine = LevelUpMachine(
        id: 73,
        lineId: 50,
        code: 'M-01',
        name: 'Máy 01',
        levelApply: 'level1, level10;level3',
        isActive: true,
      );

      expect(machine.appliesToLevelCode('LEVEL1'), isTrue);
      expect(machine.appliesToLevelCode('level3'), isTrue);
      expect(machine.appliesToLevelCode('level2'), isFalse);
      expect(machine.appliesToLevelCode('level'), isFalse);
    });
  });

  group('LevelUpPracticalExam', () {
    test('parses nested candidate, config, criteria, and image data', () {
      const fallbackFilter = LevelUpFilter(
        factoryId: 10,
        factoryName: 'Bình Dương',
        levelId: 3,
        levelName: 'Cấp 3',
        lineId: 50,
        lineName: 'Line Aseptic',
        machineId: 73,
        machineName: 'Máy chiết',
      );
      final exam = LevelUpPracticalExam.fromJson(
        {
          'PracticalExamId': 9001,
          'Candidate': {
            'Id': 'employee-43950',
            'Code': '43950',
            'Name': 'Nguyễn Văn A',
          },
          'ExamConfig': {
            'ExamCode': 'TH-L3-001',
            'Name': 'Vận hành máy chiết',
          },
          'ExamDate': '2026-08-04T09:30:00+07:00',
          'Status': 'Chưa chấm',
          'Photos': [
            'https://cdn.example.com/exam-overview.jpg',
            'https://cdn.example.com/shared.jpg',
          ],
          'Payload': {
            'Questions': [
              {
                'QuestionId': 101,
                'Question': 'Kiểm tra an toàn trước khi vận hành',
                'Instruction': 'Chấm theo checklist an toàn',
                'MinScore': '0',
                'MaxScore': '4,5',
                'ActualScore': '3,5',
                'Pictures':
                    'https://cdn.example.com/safety-1.jpg|https://cdn.example.com/shared.jpg',
              },
              {
                'KnowledgeId': 'K-102',
                'KnowledgeName': 'Thao tác vận hành',
                'MaxScore': 6,
                'Attachments': [
                  'https://cdn.example.com/operation-1.jpg',
                ],
              },
            ],
          },
        },
        fallbackFilter: fallbackFilter,
      );

      expect(exam.id, '9001');
      expect(exam.hasStableId, isTrue);
      expect(exam.candidateId, 'employee-43950');
      expect(exam.candidateCode, '43950');
      expect(exam.candidateName, 'Nguyễn Văn A');
      expect(exam.title, 'Vận hành máy chiết');
      expect(exam.examCode, 'TH-L3-001');
      expect(exam.factoryName, 'Bình Dương');
      expect(exam.levelName, 'Cấp 3');
      expect(exam.lineName, 'Line Aseptic');
      expect(exam.machineName, 'Máy chiết');
      expect(exam.isScored, isFalse);
      expect(exam.maxScore, 10.5);

      expect(exam.criteria, hasLength(2));
      final safety = exam.criteria.first;
      expect(safety.id, '101');
      expect(safety.title, 'Kiểm tra an toàn trước khi vận hành');
      expect(safety.description, 'Chấm theo checklist an toàn');
      expect(safety.minScore, 0);
      expect(safety.maxScore, 4.5);
      expect(safety.existingScore, 3.5);
      expect(safety.imageUrls, [
        'https://cdn.example.com/safety-1.jpg',
        'https://cdn.example.com/shared.jpg',
      ]);

      final operation = exam.criteria.last;
      expect(operation.id, 'K-102');
      expect(operation.title, 'Thao tác vận hành');
      expect(operation.maxScore, 6);
      expect(operation.existingScore, isNull);
      expect(operation.imageUrls, [
        'https://cdn.example.com/operation-1.jpg',
      ]);

      expect(exam.imageUrls, hasLength(4));
      expect(
        exam.imageUrls,
        containsAll(<String>[
          'https://cdn.example.com/exam-overview.jpg',
          'https://cdn.example.com/shared.jpg',
          'https://cdn.example.com/safety-1.jpg',
          'https://cdn.example.com/operation-1.jpg',
        ]),
      );
    });

    test('skips null aliases and creates a collision-safe fallback identity',
        () {
      final first = LevelUpPracticalExam.fromJson({
        'PracticalExamId': null,
        'PracticalId': null,
        'CandidateName': null,
        'EmployeeName': 'Nguyễn Văn A',
        'Candidate': {'Id': 101, 'Code': 'NV101'},
        'ExamConfig': {'ExamConfigId': 77, 'Name': 'Vận hành máy'},
      });
      final second = LevelUpPracticalExam.fromJson({
        'Candidate': {'Id': 102, 'Code': 'NV102', 'Name': 'Nguyễn Văn B'},
        'ExamConfig': {'ExamConfigId': 77, 'Name': 'Vận hành máy'},
      });

      expect(first.candidateName, 'Nguyễn Văn A');
      expect(first.id, 'config-77::candidate-101');
      expect(second.id, 'config-77::candidate-102');
      expect(first.id, isNot(second.id));
      expect(first.hasStableId, isFalse);
      expect(second.hasStableId, isFalse);
    });

    test('extracts image URLs from attachment objects', () {
      final exam = LevelUpPracticalExam.fromJson({
        'PracticalExamId': 9010,
        'Photos': [
          {'Url': '/uploads/evidence-1.jpg'},
          {'FilePath': 'uploads/evidence-2.png'},
        ],
      });

      expect(
        exam.imageUrls,
        ['/uploads/evidence-1.jpg', 'uploads/evidence-2.png'],
      );
    });

    test('keeps delimiters inside one signed absolute image URL', () {
      const signedUrl =
          'https://cdn.example.com/evidence.jpg?signature=abc,def;ghi';
      final exam = LevelUpPracticalExam.fromJson({
        'PracticalExamId': 9017,
        'ImageUrl': signedUrl,
      });

      expect(exam.imageUrls, [signedUrl]);
    });

    test('flattens question rows nested inside knowledge groups', () {
      final exam = LevelUpPracticalExam.fromJson({
        'PracticalExamId': 9018,
        'KnowledgeGroups': [
          {
            'KnowledgeId': 'group-1',
            'KnowledgeName': 'Nhóm an toàn',
            'Questions': [
              {
                'QuestionId': 501,
                'Question': 'Kiểm tra khóa an toàn',
                'MaxScore': 5,
              },
            ],
          },
          {
            'KnowledgeId': 'group-2',
            'KnowledgeName': 'Nhóm vận hành',
            'Details': [
              {
                'DetailId': 502,
                'Content': 'Khởi động đúng trình tự',
                'MaxScore': 5,
              },
            ],
          },
        ],
      });

      expect(exam.criteria.map((item) => item.id), ['501', '502']);
      expect(exam.criteria.first.title, 'Kiểm tra khóa an toàn');
      expect(exam.criteria.last.title, 'Khởi động đúng trình tự');
    });

    test('continues past empty criteria containers to nested criteria', () {
      final exam = LevelUpPracticalExam.fromJson({
        'PracticalExamId': 9019,
        'PracticalDetails': <Object>[],
        'Payload': {
          'Questions': [
            {
              'QuestionId': 601,
              'Question': 'Tiêu chí lồng nhau',
              'MaxScore': 5,
            },
          ],
        },
      });

      expect(exam.criteria.single.id, '601');
    });

    test('splits pipe-delimited absolute and relative image paths', () {
      final exam = LevelUpPracticalExam.fromJson({
        'PracticalExamId': 9020,
        'Images': 'https://cdn.example.com/a.jpg|/uploads/b.jpg',
      });

      expect(
        exam.imageUrls,
        ['https://cdn.example.com/a.jpg', '/uploads/b.jpg'],
      );
    });

    test('splits comma-delimited absolute and relative image paths', () {
      final exam = LevelUpPracticalExam.fromJson({
        'PracticalExamId': 9023,
        'Images': 'https://cdn.example.com/a.jpg,/uploads/b.jpg',
      });

      expect(
        exam.imageUrls,
        ['https://cdn.example.com/a.jpg', '/uploads/b.jpg'],
      );
    });

    test('excludes profile assets while retaining exam evidence images', () {
      final exam = LevelUpPracticalExam.fromJson({
        'PracticalExamId': 9022,
        'Candidate': {
          'Photo': 'https://cdn.example.com/avatar.jpg',
          'EvidencePhotos': ['https://cdn.example.com/evidence.jpg'],
        },
        'Machine': {'Logo': 'https://cdn.example.com/machine-logo.png'},
      });

      expect(exam.imageUrls, ['https://cdn.example.com/evidence.jpg']);
    });

    test('does not trust a generic row Id as a stable exam identity', () {
      final exam = LevelUpPracticalExam.fromJson({
        'Id': 9021,
        'Candidate': {'Id': 77},
        'ExamConfig': {'Id': 88},
      });

      expect(exam.id, 'config-88::candidate-77');
      expect(exam.hasStableId, isFalse);
    });

    test('does not invent a score scale when backend omits it', () {
      final exam = LevelUpPracticalExam.fromJson({
        'PracticalExamId': 9011,
        'Questions': [
          {'QuestionId': 1, 'Question': 'Tiêu chí chưa có thang điểm'},
        ],
      });

      expect(exam.criteria.single.maxScore, isNull);
      expect(exam.maxScore, isNull);
    });

    test('explicit pending status overrides a default numeric zero score', () {
      final pending = LevelUpPracticalExam.fromJson({
        'PracticalExamId': 9012,
        'Status': 'Chưa chấm',
        'Score': 0,
      });
      final completed = LevelUpPracticalExam.fromJson({
        'PracticalExamId': 9013,
        'Status': 'Hoàn thành',
        'Score': 0,
      });

      expect(pending.isScored, isFalse);
      expect(completed.isScored, isTrue);
    });

    test('derives a completed status when score exists but status is absent',
        () {
      final exam = LevelUpPracticalExam.fromJson({
        'PracticalExamId': 9015,
        'Score': 8,
      });

      expect(exam.status, 'Đã chấm');
      expect(exam.isScored, isTrue);
    });

    test('recognizes compact negative status values before scored suffixes',
        () {
      for (final status in ['NotScored', 'not_scored', 'Unscored']) {
        final exam = LevelUpPracticalExam.fromJson({
          'PracticalExamId': 'negative-$status',
          'Status': status,
          'Score': 0,
        });
        expect(exam.isScored, isFalse, reason: status);
      }

      final incomplete = LevelUpPracticalExam.fromJson({
        'PracticalExamId': 9016,
        'Status': 'Chưa hoàn thành',
        'Score': 0,
      });
      expect(incomplete.isScored, isFalse);
    });

    test('marks fallback criterion indexes as unstable draft identities', () {
      final exam = LevelUpPracticalExam.fromJson({
        'PracticalExamId': 9014,
        'Questions': [
          {'Question': 'Không có ID', 'MaxScore': 5},
        ],
      });

      expect(exam.criteria.single.id, '1');
      expect(exam.criteria.single.hasStableId, isFalse);
    });
  });

  group('LevelUpScoreSubmission', () {
    test('round-trips the API-ready score payload without losing data', () {
      final gradedAt = DateTime.parse('2026-08-04T09:30:00+07:00');
      final submission = LevelUpScoreSubmission(
        examId: '9001',
        candidateId: 'employee-43950',
        examinerEmail: 'assessor@thp.com.vn',
        totalScore: 8.75,
        overallNote: 'Đạt yêu cầu',
        gradedAt: gradedAt,
        items: const [
          LevelUpScoreItem(
            criterionId: '101',
            criterionName: 'An toàn',
            score: 3.75,
            maxScore: 4.5,
            note: 'Thao tác đúng',
          ),
          LevelUpScoreItem(
            criterionId: 'K-102',
            criterionName: 'Vận hành',
            score: 5,
            maxScore: 6,
          ),
        ],
      );

      final encoded = submission.encode();
      final payload = jsonDecode(encoded) as Map<String, dynamic>;
      final restored = LevelUpScoreSubmission.fromJson(payload);

      expect(payload['GradedAt'], '2026-08-04T02:30:00.000Z');
      expect(payload['Details'], isA<List<dynamic>>());
      expect(restored.examId, submission.examId);
      expect(restored.candidateId, submission.candidateId);
      expect(restored.examinerEmail, submission.examinerEmail);
      expect(restored.totalScore, submission.totalScore);
      expect(restored.overallNote, submission.overallNote);
      expect(restored.gradedAt, gradedAt.toUtc());
      expect(restored.items, hasLength(2));
      expect(restored.items.first.criterionId, '101');
      expect(restored.items.first.criterionName, 'An toàn');
      expect(restored.items.first.score, 3.75);
      expect(restored.items.first.maxScore, 4.5);
      expect(restored.items.first.note, 'Thao tác đúng');
      expect(restored.items.last.criterionId, 'K-102');
      expect(restored.items.last.note, isNull);
    });
  });
}
