import 'package:equatable/equatable.dart';

class DeviceTokenEntity extends Equatable {
  const DeviceTokenEntity({
    required this.token,
    required this.platform,
  });

  final String token;
  final String platform;

  @override
  List<Object?> get props => [token, platform];
}
