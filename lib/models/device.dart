import 'package:freezed_annotation/freezed_annotation.dart';
import 'connection_type.dart';

part 'device.freezed.dart';

@freezed
class Device with _$Device {
  const factory Device({
    required String serialNumber,
    required String status,
    required ConnectionType connectionType,
    String? model,
    String? androidVersion,
    @Default(false) bool isConnected,
  }) = _Device;
}
