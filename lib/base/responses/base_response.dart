class BaseResponse {
  BaseResponse({this.success, this.message, this.data});

  final bool? success;
  final String? message;
  final dynamic data;

  factory BaseResponse.fromJson(Map<String, dynamic> json) => BaseResponse(
        success: json['success'],
        message: json['message'],
        data: json['data'],
      );

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data,
      };
}
