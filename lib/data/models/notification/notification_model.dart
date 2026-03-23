/// Model ánh xạ từ response API:
/// GET /api/employee/getmessage?mode=ALL&page=1&pagesize=10
class NotificationModel {
  final int id;
  final String message;
  final String messageTitle;
  final DateTime created;
  final String toUser;
  final String messageType;
  final DateTime modified;
  final bool isRead;
  final String? deeplink;

  const NotificationModel({
    required this.id,
    required this.message,
    required this.messageTitle,
    required this.created,
    required this.toUser,
    required this.messageType,
    required this.modified,
    required this.isRead,
    this.deeplink,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['Id'] as int,
      message: json['Message'] as String? ?? '',
      messageTitle: json['MessageTitle'] as String? ?? '',
      created: DateTime.parse(json['Created'] as String),
      toUser: json['ToUser'] as String? ?? '',
      messageType: json['MessageType'] as String? ?? '',
      modified: DateTime.parse(json['Modifired'] as String),
      isRead: (json['IsRead'] as int? ?? 0) == 1,
      deeplink: json['Deeplink'] as String?,
    );
  }

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        message: message,
        messageTitle: messageTitle,
        created: created,
        toUser: toUser,
        messageType: messageType,
        modified: modified,
        isRead: isRead ?? this.isRead,
        deeplink: deeplink,
      );
}

/// Model bao bọc toàn bộ response data
class NotificationListResponse {
  final int total;
  final List<NotificationModel> items;

  const NotificationListResponse({
    required this.total,
    required this.items,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    // Structure: {"status":"success","data":{"Total":10,"Data":[...]}}
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final total = data['Total'] as int? ?? 0;
    final rawList = data['Data'] as List<dynamic>? ?? [];
    final items = rawList
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return NotificationListResponse(total: total, items: items);
  }
}

