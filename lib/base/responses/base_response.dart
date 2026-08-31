class BaseResponse<T> {
  const BaseResponse({this.success, this.message, this.data});

  final bool? success;
  final String? message;
  final T? data;

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) decode,
  ) {
    return BaseResponse<T>(
      success: json['success'] as bool?,
      message: json['message']?.toString(),
      data: json['data'] == null ? null : decode(json['data']),
    );
  }

  Map<String, dynamic> toJson() => {
        'success': success,
        'message': message,
        'data': data,
      };
}
