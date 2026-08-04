import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_core_project/data/data_sources/remote/level_up_api_service.dart';
import 'package:flutter_core_project/data/models/level_up/level_up_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LevelUpApiService request contract', () {
    test('uses the expected paths and query parameters for every endpoint',
        () async {
      final harness = _ApiHarness((request) {
        switch (request.uri.path) {
          case '/api/exam/listFactorys':
            return _jsonResponse({
              'status': 'success',
              'data': [
                {
                  'FactoryId': 10,
                  'FactoryCode': 'BD',
                  'FactoryName': 'Bình Dương',
                  'RolePermission': 'SupperAdmin',
                },
              ],
            });
          case '/api/exam/listLevels':
            return _jsonResponse({
              'status': 'success',
              'data': [
                {
                  'LevelId': 3,
                  'LevelCode': 'level3',
                  'LevelName': 'Cấp 3',
                },
              ],
            });
          case '/api/exam/listLines':
            return _jsonResponse({
              'status': 'success',
              'data': [
                {
                  'LineId': 50,
                  'FactoryId': 10,
                  'LineCode': 'Line003',
                  'LineName': 'Line Aseptic',
                },
              ],
            });
          case '/api/exam/listMachines':
            return _jsonResponse({
              'status': 'success',
              'data': [
                {
                  'MachineId': 71,
                  'LineId': 50,
                  'MachineCode': 'ACTIVE-1',
                  'MachineName': 'Máy active 1',
                  'Active': 1,
                },
                {
                  'MachineId': 72,
                  'LineId': 50,
                  'MachineCode': 'INACTIVE',
                  'MachineName': 'Máy ngưng hoạt động',
                  'Active': 0,
                },
                {
                  'MachineId': 73,
                  'LineId': 50,
                  'MachineCode': 'ACTIVE-DEFAULT',
                  'MachineName': 'Máy active mặc định',
                },
                {
                  'MachineId': 0,
                  'LineId': 50,
                  'MachineName': 'Bản ghi không hợp lệ',
                  'Active': 1,
                },
              ],
            });
          case '/api/exam/listPractical':
            return _jsonResponse({
              'status': 'success',
              'data': {
                'Candidates': [
                  {
                    'PracticalExamId': 9001,
                    'CandidateCode': '43950',
                    'CandidateName': 'Nguyễn Văn A',
                  },
                ],
              },
            });
          default:
            throw StateError('Unexpected request: ${request.uri}');
        }
      });
      addTearDown(harness.close);

      final factories = await harness.service.getFactories(
        email: ' assessor@thp.com.vn ',
      );
      final levels = await harness.service.getLevels();
      final lines = await harness.service.getLines(factoryId: 10);
      final machines = await harness.service.getMachines(lineId: 50);
      final exams = await harness.service.getPracticalExams(
        filter: const LevelUpFilter(
          factoryId: 10,
          factoryName: 'Bình Dương',
          levelId: 3,
          levelName: 'Cấp 3',
          lineId: 50,
          lineName: 'Line Aseptic',
          machineId: 73,
          machineName: 'Máy active mặc định',
        ),
      );

      expect(factories.single.id, 10);
      expect(levels.single.id, 3);
      expect(lines.single.id, 50);
      expect(machines.map((machine) => machine.id), [71, 73]);
      expect(exams.single.id, '9001');

      expect(harness.adapter.requests, hasLength(5));
      _expectRequest(
        harness.adapter.requests[0],
        path: '/api/exam/listFactorys',
        query: const {'email': 'assessor@thp.com.vn'},
      );
      _expectRequest(
        harness.adapter.requests[1],
        path: '/api/exam/listLevels',
        query: const {},
      );
      _expectRequest(
        harness.adapter.requests[2],
        path: '/api/exam/listLines',
        query: const {'FactoryId': 10},
      );
      _expectRequest(
        harness.adapter.requests[3],
        path: '/api/exam/listMachines',
        query: const {'LineId': 50},
      );
      _expectRequest(
        harness.adapter.requests[4],
        path: '/api/exam/listPractical',
        query: const {
          'FactoryId': 10,
          'LevelId': 3,
          'LineId': 50,
          'MachineId': 73,
        },
      );
    });
  });

  group('LevelUpApiService response validation', () {
    test('keeps an empty authoritative practical list empty', () async {
      final harness = _ApiHarness(
        (_) => _jsonResponse({
          'Status': 'success',
          'Data': {
            'Practicals': <Object>[],
            'Candidates': [
              {
                'PracticalExamId': 9999,
                'CandidateName': 'Không được dùng làm bài thi',
              },
            ],
          },
        }),
      );
      addTearDown(harness.close);

      final exams = await harness.service.getPracticalExams(
        filter: const LevelUpFilter(
          factoryId: 10,
          levelId: 1,
          lineId: 50,
          machineId: 73,
        ),
      );

      expect(exams, isEmpty);
    });

    test('throws the envelope message when HTTP succeeds but status is error',
        () async {
      final harness = _ApiHarness(
        (_) => _jsonResponse({
          'Status': 'error',
          'Message': 'Tài khoản không có quyền chấm thi.',
          'Data': <Object>[],
        }),
      );
      addTearDown(harness.close);

      await expectLater(
        harness.service.getLevels(),
        throwsA(
          isA<LevelUpApiException>().having(
            (error) => error.message,
            'message',
            'Tài khoản không có quyền chấm thi.',
          ),
        ),
      );
      expect(harness.adapter.requests, hasLength(1));
    });

    test('rejects every incomplete practical filter before transport',
        () async {
      final harness = _ApiHarness(
        (request) => throw StateError('Transport must not be called: $request'),
      );
      addTearDown(harness.close);
      const incompleteFilters = <LevelUpFilter>[
        LevelUpFilter(levelId: 3, lineId: 50, machineId: 73),
        LevelUpFilter(factoryId: 10, lineId: 50, machineId: 73),
        LevelUpFilter(factoryId: 10, levelId: 3, machineId: 73),
        LevelUpFilter(factoryId: 10, levelId: 3, lineId: 50),
      ];

      for (final filter in incompleteFilters) {
        await expectLater(
          harness.service.getPracticalExams(filter: filter),
          throwsA(
            isA<LevelUpApiException>().having(
              (error) => error.message,
              'message',
              contains('Vui lòng chọn đủ'),
            ),
          ),
        );
      }

      expect(harness.adapter.requests, isEmpty);
    });
  });
}

typedef _RequestHandler = ResponseBody Function(RequestOptions request);

class _ApiHarness {
  _ApiHarness(_RequestHandler handler)
      : adapter = _FakeHttpClientAdapter(handler),
        dio = Dio(
          BaseOptions(baseUrl: 'https://mobile-app.thp.com.vn'),
        ) {
    dio.httpClientAdapter = adapter;
    service = LevelUpApiService(dio);
  }

  final Dio dio;
  final _FakeHttpClientAdapter adapter;
  late final LevelUpApiService service;

  void close() => dio.close(force: true);
}

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this._handler);

  final _RequestHandler _handler;
  final List<RequestOptions> requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    return _handler(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody _jsonResponse(Object body, {int statusCode = 200}) {
  return ResponseBody.fromString(
    jsonEncode(body),
    statusCode,
    headers: const {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void _expectRequest(
  RequestOptions request, {
  required String path,
  required Map<String, dynamic> query,
}) {
  expect(request.method, 'GET');
  expect(request.uri.path, path);
  expect(request.queryParameters, query);
  expect(request.extra['skipErrorDialog'], isTrue);
}
