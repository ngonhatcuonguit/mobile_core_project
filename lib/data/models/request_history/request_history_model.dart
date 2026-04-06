import 'package:intl/intl.dart';

// ─── Trạng thái phản hồi ──────────────────────────────────────────────────────
enum RequestStatus { pending, approved }

extension RequestStatusExt on RequestStatus {
  String get labelVi {
    switch (this) {
      case RequestStatus.pending:  return 'Đang chờ';
      case RequestStatus.approved: return 'Đã duyệt';
    }
  }

  String get labelEn {
    switch (this) {
      case RequestStatus.pending:  return 'Pending';
      case RequestStatus.approved: return 'Approved';
    }
  }
}

/// 0 → Đang chờ  |  1 → Đã duyệt  |  other → Đang chờ (fallback)
RequestStatus statusFromInt(int? v) {
  return v == 1 ? RequestStatus.approved : RequestStatus.pending;
}

// ─── Loại yêu cầu parse từ NOTE field ────────────────────────────────────────
const Map<String, String> _typeCodeLabelVi = {
  'NOT_YET':        'Chưa lấy vân tay',
  'FORGOTEN':       'Quên quét vân tay',
  'MCC_ERROR':      'Quét VT nhưng MCC không ghi nhận',
  'SHIFT_SWAPPING': 'Đảo ca',
  'NIGHT_SHIFT':    'Ca đêm',
  'DAY_BUSINESS':   'Công tác trong ngày',
  'OTHER':          'Khác',
};
const Map<String, String> _typeCodeLabelEn = {
  'NOT_YET':        'Fingerprint not yet registered',
  'FORGOTEN':       'Forgotten to scan fingerprint',
  'MCC_ERROR':      'Fingerprint scanned but MCC not recorded',
  'SHIFT_SWAPPING': 'Shift Swapping',
  'NIGHT_SHIFT':    'Night Shift',
  'DAY_BUSINESS':   'Day Business',
  'OTHER':          'Other',
};

// ─── Model ───────────────────────────────────────────────────────────────────
/// Map từ JSON trả về bởi GET /api/employee/myrequest
class RequestHistoryItem {
  final int id;
  final String employeeId;
  final DateTime dateWorking;
  final RequestStatus status;
  final DateTime? timeIn;
  final DateTime? timeOut;

  /// Raw NOTE field: "TYPE\nReason\n Ngày yêu cầu: dd/MM/yyyy HH:mm"
  final String? rawNote;
  final String? hrbpNote;
  final int? priority;
  final DateTime? createAt;
  final DateTime? updateAt;
  final String? orgId;

  const RequestHistoryItem({
    required this.id,
    required this.employeeId,
    required this.dateWorking,
    required this.status,
    this.timeIn,
    this.timeOut,
    this.rawNote,
    this.hrbpNote,
    this.priority,
    this.createAt,
    this.updateAt,
    this.orgId,
  });

  // ── Parse NOTE field ──────────────────────────────────────────────────────

  static final _dtParser = DateFormat("yyyy-MM-dd'T'HH:mm:ss");

  /// Type code từ dòng đầu của NOTE ("NOT_YET", "FORGOTEN", …)
  String get typeCode {
    if (rawNote == null || rawNote!.isEmpty) return 'OTHER';
    final lines = rawNote!.trim().split('\n');
    return lines.first.trim().toUpperCase();
  }

  String get typeLabelVi => _typeCodeLabelVi[typeCode] ?? rawNote?.split('\n').first ?? typeCode;
  String get typeLabelEn => _typeCodeLabelEn[typeCode] ?? rawNote?.split('\n').first ?? typeCode;

  /// Lý do: dòng thứ 2 của NOTE
  String get reason {
    if (rawNote == null) return '';
    final lines = rawNote!.trim().split('\n');
    if (lines.length < 2) return '';
    return lines[1].trim();
  }

  /// Ngày yêu cầu: parse từ dòng cuối "Ngày yêu cầu: dd/MM/yyyy HH:mm"
  DateTime? get requestedAt {
    if (rawNote == null) return null;
    final lines = rawNote!.trim().split('\n');
    final last = lines.last;
    final match = RegExp(r'(\d{2}/\d{2}/\d{4} \d{2}:\d{2})').firstMatch(last);
    if (match == null) return null;
    try {
      return DateFormat('dd/MM/yyyy HH:mm').parse(match.group(1)!);
    } catch (_) {
      return null;
    }
  }

  factory RequestHistoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(Object? v) {
      if (v == null) return null;
      try {
        final s = v.toString();
        // Trim fractional seconds beyond 3 digits for parse safety
        final trimmed = s.contains('.')
            ? s.substring(0, s.indexOf('.') + 4).padRight(s.indexOf('.') + 4, '0')
            : s;
        return _dtParser.parse(trimmed.length > 19 ? trimmed.substring(0, 19) : trimmed);
      } catch (_) {
        return null;
      }
    }

    return RequestHistoryItem(
      id:          (json['Id'] as num).toInt(),
      employeeId:  (json['EMPLOYEE_ID'] as String?) ?? '',
      dateWorking: parseDate(json['DATE_WORKING']) ?? DateTime.now(),
      status:      statusFromInt(json['Status'] as int?),
      timeIn:      parseDate(json['TimeIn']),
      timeOut:     parseDate(json['TimeOut']),
      rawNote:     json['NOTE'] as String?,
      hrbpNote:    json['HRBP_NOTE'] as String?,
      priority:    json['Priority'] as int?,
      createAt:    parseDate(json['CreateAt']),
      updateAt:    parseDate(json['UpdateAt']),
      orgId:       json['OrgId'] as String?,
    );
  }
}

/// Outer response của GET /api/employee/myrequest
class RequestHistoryResponse {
  final int total;
  final List<RequestHistoryItem> items;

  const RequestHistoryResponse({required this.total, required this.items});

  factory RequestHistoryResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final rawList = (data['Data'] as List<dynamic>?) ?? [];
    return RequestHistoryResponse(
      total: (data['Total'] as num?)?.toInt() ?? 0,
      items: rawList
          .map((e) => RequestHistoryItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

