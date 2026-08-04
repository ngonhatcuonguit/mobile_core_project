import 'dart:convert';

Object? _readValue(Map<String, dynamic> json, Iterable<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key) && _isMeaningful(json[key])) return json[key];
  }
  final normalized = <String, Object?>{
    for (final entry in json.entries) entry.key.toLowerCase(): entry.value,
  };
  for (final key in keys) {
    final value = normalized[key.toLowerCase()];
    if (_isMeaningful(value)) return value;
  }
  return null;
}

bool _isMeaningful(Object? value) {
  if (value == null) return false;
  if (value is String) {
    final text = value.trim();
    return text.isNotEmpty && text.toLowerCase() != 'null';
  }
  if (value is Map || value is Iterable) {
    return (value as dynamic).isNotEmpty == true;
  }
  return true;
}

String? _readString(Map<String, dynamic> json, Iterable<String> keys) {
  final value = _readValue(json, keys);
  if (value == null) return null;
  final text = value.toString().trim();
  return text.isEmpty || text.toLowerCase() == 'null' ? null : text;
}

int? _readInt(Map<String, dynamic> json, Iterable<String> keys) {
  final value = _readValue(json, keys);
  if (value is int) return value;
  if (value is num) return value.isFinite ? value.toInt() : null;
  return int.tryParse(value?.toString().trim() ?? '');
}

double? _readDouble(Map<String, dynamic> json, Iterable<String> keys) {
  final value = _readValue(json, keys);
  final parsed = value is num
      ? value.toDouble()
      : double.tryParse(
          value?.toString().replaceAll(',', '.').trim() ?? '',
        );
  return parsed?.isFinite == true ? parsed : null;
}

bool? _readBool(Map<String, dynamic> json, Iterable<String> keys) {
  final value = _readValue(json, keys);
  if (value is bool) return value;
  if (value is num) return value != 0;
  switch (value?.toString().trim().toLowerCase()) {
    case 'true':
    case '1':
      return true;
    case 'false':
    case '0':
      return false;
  }
  return null;
}

Map<String, dynamic>? _readMap(
  Map<String, dynamic> json,
  Iterable<String> keys,
) {
  final value = _readValue(json, keys);
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}

List<Map<String, dynamic>> _readMapList(
  Map<String, dynamic> json,
  Iterable<String> keys,
) {
  for (final key in keys) {
    final value = _readValue(json, [key]);
    if (value is! List) continue;
    final items = value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
    if (items.isNotEmpty) return items;
  }
  return const [];
}

class LevelUpFactory {
  final int id;
  final String code;
  final String name;
  final String? rolePermission;

  const LevelUpFactory({
    required this.id,
    required this.code,
    required this.name,
    this.rolePermission,
  });

  factory LevelUpFactory.fromJson(Map<String, dynamic> json) => LevelUpFactory(
        id: _readInt(json, const ['FactoryId', 'id']) ?? 0,
        code: _readString(json, const ['FactoryCode', 'code']) ?? '',
        name: _readString(json, const ['FactoryName', 'name']) ??
            _readString(json, const ['FactoryCode', 'code']) ??
            'Nhà máy',
        rolePermission:
            _readString(json, const ['RolePermission', 'permission', 'role']),
      );
}

class LevelUpLevel {
  final int id;
  final String code;
  final String name;
  final String? description;

  const LevelUpLevel({
    required this.id,
    required this.code,
    required this.name,
    this.description,
  });

  factory LevelUpLevel.fromJson(Map<String, dynamic> json) => LevelUpLevel(
        id: _readInt(json, const ['LevelId', 'id']) ?? 0,
        code: _readString(json, const ['LevelCode', 'code']) ?? '',
        name: _readString(json, const ['LevelName', 'name']) ??
            _readString(json, const ['LevelCode', 'code']) ??
            'Cấp bậc',
        description: _readString(json, const ['Description', 'description']),
      );
}

class LevelUpLine {
  final int id;
  final int factoryId;
  final String code;
  final String name;

  const LevelUpLine({
    required this.id,
    required this.factoryId,
    required this.code,
    required this.name,
  });

  factory LevelUpLine.fromJson(Map<String, dynamic> json) => LevelUpLine(
        id: _readInt(json, const ['LineId', 'id']) ?? 0,
        factoryId: _readInt(json, const ['FactoryId', 'factoryId']) ?? 0,
        code: _readString(json, const ['LineCode', 'code']) ?? '',
        name: _readString(json, const ['LineName', 'name']) ??
            _readString(json, const ['LineCode', 'code']) ??
            'Line',
      );
}

class LevelUpMachine {
  final int id;
  final int lineId;
  final String code;
  final String name;
  final String? levelApply;
  final bool isActive;

  const LevelUpMachine({
    required this.id,
    required this.lineId,
    required this.code,
    required this.name,
    required this.isActive,
    this.levelApply,
  });

  bool appliesToLevelCode(String? levelCode) {
    final normalizedLevel = levelCode?.trim().toLowerCase();
    if (normalizedLevel == null || normalizedLevel.isEmpty) return true;
    final applied = levelApply;
    if (applied == null || applied.trim().isEmpty) return false;
    final tokens = applied
        .toLowerCase()
        .split(RegExp(r'[,;|\s]+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty);
    return tokens.contains(normalizedLevel);
  }

  factory LevelUpMachine.fromJson(Map<String, dynamic> json) {
    final active = _readBool(json, const ['Active', 'isActive']);
    return LevelUpMachine(
      id: _readInt(json, const ['MachineId', 'id']) ?? 0,
      lineId: _readInt(json, const ['LineId', 'lineId']) ?? 0,
      code: _readString(json, const ['MachineCode', 'code']) ?? '',
      name: _readString(json, const ['MachineName', 'name']) ??
          _readString(json, const ['MachineCode', 'code']) ??
          'Máy',
      levelApply: _readString(json, const ['LevelApply', 'levelApply']),
      isActive: active ?? true,
    );
  }
}

/// Snapshot của bộ lọc gần nhất. Label được lưu cùng ID để list có thể hiển thị
/// ngay trong lúc metadata mới đang được tải và kiểm tra lại quyền truy cập.
class LevelUpFilter {
  static const int currentVersion = 1;

  final int? factoryId;
  final String? factoryName;
  final int? levelId;
  final String? levelCode;
  final String? levelName;
  final int? lineId;
  final String? lineName;
  final int? machineId;
  final String? machineName;
  final DateTime? savedAt;

  const LevelUpFilter({
    this.factoryId,
    this.factoryName,
    this.levelId,
    this.levelCode,
    this.levelName,
    this.lineId,
    this.lineName,
    this.machineId,
    this.machineName,
    this.savedAt,
  });

  bool get canLoadExams =>
      (factoryId ?? 0) > 0 &&
      (levelId ?? 0) > 0 &&
      (lineId ?? 0) > 0 &&
      (machineId ?? 0) > 0;

  LevelUpFilter copyWith({
    int? factoryId,
    String? factoryName,
    int? levelId,
    String? levelCode,
    String? levelName,
    int? lineId,
    String? lineName,
    int? machineId,
    String? machineName,
    DateTime? savedAt,
    bool clearFactory = false,
    bool clearLevel = false,
    bool clearLine = false,
    bool clearMachine = false,
  }) {
    return LevelUpFilter(
      factoryId: clearFactory ? null : factoryId ?? this.factoryId,
      factoryName: clearFactory ? null : factoryName ?? this.factoryName,
      levelId: clearLevel ? null : levelId ?? this.levelId,
      levelCode: clearLevel ? null : levelCode ?? this.levelCode,
      levelName: clearLevel ? null : levelName ?? this.levelName,
      lineId: clearLine ? null : lineId ?? this.lineId,
      lineName: clearLine ? null : lineName ?? this.lineName,
      machineId: clearMachine ? null : machineId ?? this.machineId,
      machineName: clearMachine ? null : machineName ?? this.machineName,
      savedAt: savedAt ?? this.savedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': currentVersion,
        'factoryId': factoryId,
        'factoryName': factoryName,
        'levelId': levelId,
        'levelCode': levelCode,
        'levelName': levelName,
        'lineId': lineId,
        'lineName': lineName,
        'machineId': machineId,
        'machineName': machineName,
        'savedAt': (savedAt ?? DateTime.now()).toIso8601String(),
      };

  factory LevelUpFilter.fromJson(Map<String, dynamic> json) {
    final savedAtText = _readString(json, const ['savedAt']);
    return LevelUpFilter(
      factoryId: _readInt(json, const ['factoryId']),
      factoryName: _readString(json, const ['factoryName']),
      levelId: _readInt(json, const ['levelId']),
      levelCode: _readString(json, const ['levelCode']),
      levelName: _readString(json, const ['levelName']),
      lineId: _readInt(json, const ['lineId']),
      lineName: _readString(json, const ['lineName']),
      machineId: _readInt(json, const ['machineId']),
      machineName: _readString(json, const ['machineName']),
      savedAt: savedAtText == null ? null : DateTime.tryParse(savedAtText),
    );
  }
}

class LevelUpScoreCriterion {
  final String id;
  final bool hasStableId;
  final String title;
  final String? description;
  final double minScore;
  final double? maxScore;
  final double? existingScore;
  final List<String> imageUrls;
  final Map<String, dynamic> rawData;

  const LevelUpScoreCriterion({
    required this.id,
    this.hasStableId = true,
    required this.title,
    required this.minScore,
    required this.maxScore,
    required this.imageUrls,
    required this.rawData,
    this.description,
    this.existingScore,
  });

  factory LevelUpScoreCriterion.fromJson(
    Map<String, dynamic> json, {
    required int index,
  }) {
    final max = _readDouble(json, const [
      'MaxScore',
      'MaximumScore',
      'ScoreMax',
    ]);
    final stableId = _readString(json, const [
      'CriteriaId',
      'CriterionId',
      'QuestionId',
      'DetailId',
      'KnowledgeId',
      'Id',
    ]);
    return LevelUpScoreCriterion(
      id: stableId ?? '${index + 1}',
      hasStableId: stableId != null,
      title: _readString(json, const [
            'CriteriaName',
            'CriterionName',
            'QuestionName',
            'Question',
            'KnowledgeName',
            'Content',
            'Title',
            'Name',
          ]) ??
          'Tiêu chí ${index + 1}',
      description: _readString(json, const [
        'Description',
        'Instruction',
        'Requirement',
        'Note',
      ]),
      minScore: _readDouble(json, const ['MinScore', 'ScoreMin']) ?? 0,
      maxScore: max != null && max > 0 ? max : null,
      existingScore:
          _readDouble(json, const ['Score', 'ActualScore', 'ResultScore']),
      imageUrls: _extractImageUrls(json),
      rawData: Map.unmodifiable(json),
    );
  }
}

class LevelUpPracticalExam {
  final String id;
  final bool hasStableId;
  final String? candidateId;
  final String candidateCode;
  final String candidateName;
  final String title;
  final String? examCode;
  final String? examDate;
  final String status;
  final double? score;
  final double? maxScore;
  final String? factoryName;
  final String? lineName;
  final String? machineName;
  final String? levelName;
  final List<String> imageUrls;
  final List<LevelUpScoreCriterion> criteria;
  final Map<String, dynamic> rawData;

  const LevelUpPracticalExam({
    required this.id,
    required this.hasStableId,
    required this.candidateCode,
    required this.candidateName,
    required this.title,
    required this.status,
    required this.imageUrls,
    required this.criteria,
    required this.rawData,
    this.candidateId,
    this.examCode,
    this.examDate,
    this.score,
    this.maxScore,
    this.factoryName,
    this.lineName,
    this.machineName,
    this.levelName,
  });

  bool get isScored {
    final normalized = status.toLowerCase();
    final compact = normalized.replaceAll(RegExp(r'[\s_-]+'), '');
    if (normalized.contains('chưa chấm') ||
        normalized.contains('chưa hoàn thành') ||
        compact.contains('pending') ||
        compact.contains('waiting') ||
        compact.contains('notscored') ||
        compact.contains('unscored') ||
        compact.contains('notgraded') ||
        compact.contains('ungraded')) {
      return false;
    }
    return score != null ||
        normalized.contains('completed') ||
        normalized.contains('scored') ||
        normalized.contains('đã chấm') ||
        normalized.contains('hoàn thành');
  }

  factory LevelUpPracticalExam.fromJson(
    Map<String, dynamic> json, {
    LevelUpFilter? fallbackFilter,
    int index = 0,
  }) {
    final candidate =
        _readMap(json, const ['Candidate', 'Employee']) ?? const {};
    final config =
        _readMap(json, const ['ExamConfig', 'Config', 'Exam']) ?? const {};
    final criteriaJson = _findCriteria(json);
    final criteria = <LevelUpScoreCriterion>[
      for (var i = 0; i < criteriaJson.length; i++)
        LevelUpScoreCriterion.fromJson(criteriaJson[i], index: i),
    ];

    final candidateId = _readString(json, const [
          'CandidateId',
          'EmployeeId',
          'StaffId',
        ]) ??
        _readString(candidate, const ['CandidateId', 'EmployeeId', 'Id']);
    final candidateCode = _readString(json, const [
          'CandidateCode',
          'EmployeeCode',
          'EmployeeId',
          'StaffCode',
          'MSNV',
        ]) ??
        _readString(candidate, const [
          'CandidateCode',
          'EmployeeCode',
          'EmployeeId',
          'Code',
        ]) ??
        '';
    final directExamId = _readString(json, const [
      'PracticalExamId',
      'PracticalId',
      'CandidateExamId',
      'ExamId',
    ]);
    final configId =
        _readString(config, const ['ExamConfigId', 'ExamId', 'Id']);
    final fallbackIdentity = <String>[
      if (configId != null) 'config-$configId',
      if (candidateId != null)
        'candidate-$candidateId'
      else if (candidateCode.isNotEmpty)
        'candidate-$candidateCode',
    ];
    final examId = directExamId ??
        (fallbackIdentity.isEmpty
            ? 'exam-${index + 1}'
            : fallbackIdentity.join('::'));

    final declaredMaxScore = _readDouble(json, const [
      'MaxScore',
      'TotalMaxScore',
      'MaximumScore',
    ]);
    final maxScore = declaredMaxScore != null && declaredMaxScore > 0
        ? declaredMaxScore
        : (criteria.isEmpty || criteria.any((item) => item.maxScore == null)
            ? null
            : criteria.fold<double>(
                0,
                (sum, item) => sum + item.maxScore!,
              ));
    final score = _readDouble(
      json,
      const ['TotalScore', 'Score', 'PracticalScore', 'ResultScore'],
    );
    final explicitStatus = _readString(json, const [
      'StatusName',
      'ExamStatus',
      'Status',
      'State',
    ]);

    return LevelUpPracticalExam(
      id: examId,
      hasStableId: directExamId != null,
      candidateId: candidateId,
      candidateCode: candidateCode,
      candidateName: _readString(json, const [
            'CandidateName',
            'EmployeeName',
            'FullName',
          ]) ??
          _readString(candidate, const [
            'CandidateName',
            'EmployeeName',
            'FullName',
            'Name',
          ]) ??
          'Thí sinh chưa có tên',
      title: _readString(json, const [
            'ExamName',
            'ExamTitle',
            'PracticalName',
            'Title',
          ]) ??
          _readString(config, const [
            'ExamName',
            'ConfigName',
            'Title',
            'Name',
          ]) ??
          'Bài thi thực hành',
      examCode: _readString(json, const ['ExamCode', 'PracticalCode']) ??
          _readString(config, const ['ExamCode', 'ConfigCode', 'Code']),
      examDate: _readString(json, const [
        'ExamDate',
        'PracticalDate',
        'Date',
        'CreatedDate',
        'CreatedAt',
      ]),
      status: explicitStatus ?? (score == null ? 'Chưa chấm' : 'Đã chấm'),
      score: score,
      maxScore: maxScore,
      factoryName: _readString(json, const ['FactoryName']) ??
          fallbackFilter?.factoryName,
      lineName:
          _readString(json, const ['LineName']) ?? fallbackFilter?.lineName,
      machineName: _readString(json, const ['MachineName']) ??
          fallbackFilter?.machineName,
      levelName:
          _readString(json, const ['LevelName']) ?? fallbackFilter?.levelName,
      imageUrls: _extractImageUrls(json),
      criteria: List.unmodifiable(criteria),
      rawData: Map.unmodifiable(json),
    );
  }
}

List<Map<String, dynamic>> _findCriteria(Map<String, dynamic> json) {
  const criterionKeys = [
    'PracticalDetails',
    'ExamDetails',
    'ScoreDetails',
    'Criteria',
    'Criterias',
    'Questions',
    'Details',
  ];
  const groupKeys = [
    'KnowledgeGroups',
    'Groups',
    'Sections',
  ];
  const containerKeys = [
    'Payload',
    'Practical',
    'PracticalExam',
    'ExamData',
    'ScoreData',
    'Result',
    'Data',
    'Content',
    'ExamConfig',
    'Config',
    'Exam',
  ];

  Object? valueForKey(Map<String, dynamic> node, String key) {
    if (node.containsKey(key)) return node[key];
    final normalizedKey = key.toLowerCase();
    for (final entry in node.entries) {
      if (entry.key.toLowerCase() == normalizedKey) return entry.value;
    }
    return null;
  }

  List<Map<String, dynamic>>? mapListForKey(
    Map<String, dynamic> node,
    String key,
  ) {
    final value = valueForKey(node, key);
    if (value is! List) return null;
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  List<Map<String, dynamic>>? visit(
    Map<String, dynamic> node, [
    int depth = 0,
  ]) {
    if (depth > 6) return null;
    List<Map<String, dynamic>>? emptyFallback;

    for (final key in criterionKeys) {
      final criteria = mapListForKey(node, key);
      if (criteria == null) continue;
      if (criteria.isNotEmpty) return criteria;
      emptyFallback ??= criteria;
    }

    for (final key in groupKeys) {
      final groups = mapListForKey(node, key);
      if (groups == null) continue;
      final flattened = <Map<String, dynamic>>[];
      for (final group in groups) {
        final nested = visit(group, depth + 1);
        if (nested?.isNotEmpty == true) flattened.addAll(nested!);
      }
      if (flattened.isNotEmpty) return flattened;
      emptyFallback ??= const [];
    }

    for (final key in containerKeys) {
      final value = valueForKey(node, key);
      if (value is! Map) continue;
      final nested = visit(Map<String, dynamic>.from(value), depth + 1);
      if (nested?.isNotEmpty == true) return nested;
      if (nested != null) emptyFallback ??= nested;
    }
    return emptyFallback;
  }

  return visit(json) ?? const [];
}

List<String> _extractImageUrls(Object? value) {
  final urls = <String>{};

  bool looksLikeImageKey(String key) =>
      key.contains('image') ||
      key.contains('photo') ||
      key.contains('picture') ||
      key.contains('attachment');

  bool excludesIdentityAsset(String key, String parentKey) {
    if (key.contains('avatar') ||
        key.contains('logo') ||
        key.contains('signature') ||
        key.contains('profilephoto') ||
        key.contains('profilepicture')) {
      return true;
    }
    const identityContainers = {
      'candidate',
      'employee',
      'examiner',
      'grader',
      'user',
      'profile',
      'factory',
      'line',
      'machine',
    };
    const genericAssetKeys = {
      'photo',
      'image',
      'picture',
      'imageurl',
      'photourl',
      'pictureurl',
    };
    return identityContainers.contains(parentKey) &&
        genericAssetKeys.contains(key);
  }

  void visit(Object? node, [String parentKey = '']) {
    if (node is Map) {
      for (final entry in node.entries) {
        final key = entry.key.toString().toLowerCase();
        if (excludesIdentityAsset(key, parentKey)) continue;
        final isImageLocation = looksLikeImageKey(parentKey) &&
            (key == 'url' ||
                key == 'uri' ||
                key == 'path' ||
                key == 'file' ||
                key == 'filepath' ||
                key == 'source' ||
                key == 'src');
        if (looksLikeImageKey(key) || isImageLocation) {
          visit(entry.value, key);
        } else if (entry.value is Map || entry.value is List) {
          visit(entry.value, key);
        }
      }
      return;
    }
    if (node is List) {
      for (final item in node) {
        visit(item, parentKey);
      }
      return;
    }
    if (node is String && parentKey.isNotEmpty) {
      final wholeValue = node.trim();
      if (wholeValue.contains('|')) {
        for (final part in wholeValue.split('|')) {
          visit(part, parentKey);
        }
        return;
      }
      if (!wholeValue.contains('?')) {
        final legacyParts = wholeValue.split(
          RegExp(
            r'[,;](?=\s*(?:https?://|/|[^,;|\s?#]+\.(?:jpg|jpeg|png|webp|gif)(?:[?#]|$)))',
            caseSensitive: false,
          ),
        );
        if (legacyParts.length > 1) {
          for (final part in legacyParts) {
            visit(part, parentKey);
          }
          return;
        }
      }
      final schemeMatches = RegExp(
        r'https?://',
        caseSensitive: false,
      ).allMatches(wholeValue);
      final parsed = Uri.tryParse(wholeValue);
      if (schemeMatches.length == 1 &&
          schemeMatches.first.start == 0 &&
          parsed != null &&
          (parsed.scheme == 'http' || parsed.scheme == 'https') &&
          parsed.host.isNotEmpty) {
        urls.add(wholeValue);
        return;
      }
      for (final part in node.split(RegExp(r'[,;]'))) {
        final url = part.trim();
        if (url.startsWith('http://') || url.startsWith('https://')) {
          urls.add(url);
        } else if (url.startsWith('/') ||
            RegExp(r'\.(jpg|jpeg|png|webp|gif)(\?.*)?$', caseSensitive: false)
                .hasMatch(url)) {
          urls.add(url);
        }
      }
    }
  }

  visit(value);
  return List.unmodifiable(urls);
}

class LevelUpScoreItem {
  final String criterionId;
  final String criterionName;
  final double score;
  final double maxScore;
  final String? note;

  const LevelUpScoreItem({
    required this.criterionId,
    required this.criterionName,
    required this.score,
    required this.maxScore,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'CriterionId': criterionId,
        'CriterionName': criterionName,
        'Score': score,
        'MaxScore': maxScore,
        'Note': note,
      };

  factory LevelUpScoreItem.fromJson(Map<String, dynamic> json) =>
      LevelUpScoreItem(
        criterionId:
            _readString(json, const ['CriterionId', 'criterionId']) ?? '',
        criterionName:
            _readString(json, const ['CriterionName', 'criterionName']) ?? '',
        score: _readDouble(json, const ['Score', 'score']) ?? 0,
        maxScore: _readDouble(json, const ['MaxScore', 'maxScore']) ?? 0,
        note: _readString(json, const ['Note', 'note']),
      );
}

/// Payload sẵn sàng cho API POST điểm trong tương lai. Chưa gắn endpoint khi
/// backend chưa cung cấp contract để tránh gửi nhầm dữ liệu thật.
class LevelUpScoreSubmission {
  final String examId;
  final String? candidateId;
  final String examinerEmail;
  final List<LevelUpScoreItem> items;
  final double totalScore;
  final String? overallNote;
  final DateTime gradedAt;

  const LevelUpScoreSubmission({
    required this.examId,
    required this.examinerEmail,
    required this.items,
    required this.totalScore,
    required this.gradedAt,
    this.candidateId,
    this.overallNote,
  });

  Map<String, dynamic> toJson() => {
        'ExamId': examId,
        'CandidateId': candidateId,
        'ExaminerEmail': examinerEmail,
        'TotalScore': totalScore,
        'OverallNote': overallNote,
        'GradedAt': gradedAt.toUtc().toIso8601String(),
        'Details': items.map((item) => item.toJson()).toList(growable: false),
      };

  String encode() => jsonEncode(toJson());

  factory LevelUpScoreSubmission.fromJson(Map<String, dynamic> json) {
    final details = _readMapList(json, const ['Details', 'items']);
    return LevelUpScoreSubmission(
      examId: _readString(json, const ['ExamId', 'examId']) ?? '',
      candidateId: _readString(json, const ['CandidateId', 'candidateId']),
      examinerEmail:
          _readString(json, const ['ExaminerEmail', 'examinerEmail']) ?? '',
      totalScore: _readDouble(json, const ['TotalScore', 'totalScore']) ?? 0,
      overallNote: _readString(json, const ['OverallNote', 'overallNote']),
      gradedAt: DateTime.tryParse(
            _readString(json, const ['GradedAt', 'gradedAt']) ?? '',
          ) ??
          DateTime.now(),
      items: details.map(LevelUpScoreItem.fromJson).toList(growable: false),
    );
  }
}
