// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'device.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$Device {
  String get serialNumber => throw _privateConstructorUsedError;
  String get status => throw _privateConstructorUsedError;
  ConnectionType get connectionType => throw _privateConstructorUsedError;
  String? get model => throw _privateConstructorUsedError;
  String? get androidVersion => throw _privateConstructorUsedError;
  bool get isConnected => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DeviceCopyWith<Device> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeviceCopyWith<$Res> {
  factory $DeviceCopyWith(Device value, $Res Function(Device) then) =
      _$DeviceCopyWithImpl<$Res, Device>;
  @useResult
  $Res call(
      {String serialNumber,
      String status,
      ConnectionType connectionType,
      String? model,
      String? androidVersion,
      bool isConnected});
}

/// @nodoc
class _$DeviceCopyWithImpl<$Res, $Val extends Device>
    implements $DeviceCopyWith<$Res> {
  _$DeviceCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? serialNumber = null,
    Object? status = null,
    Object? connectionType = null,
    Object? model = freezed,
    Object? androidVersion = freezed,
    Object? isConnected = null,
  }) {
    return _then(_value.copyWith(
      serialNumber: null == serialNumber
          ? _value.serialNumber
          : serialNumber // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      connectionType: null == connectionType
          ? _value.connectionType
          : connectionType // ignore: cast_nullable_to_non_nullable
              as ConnectionType,
      model: freezed == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String?,
      androidVersion: freezed == androidVersion
          ? _value.androidVersion
          : androidVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      isConnected: null == isConnected
          ? _value.isConnected
          : isConnected // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeviceImplCopyWith<$Res> implements $DeviceCopyWith<$Res> {
  factory _$$DeviceImplCopyWith(
          _$DeviceImpl value, $Res Function(_$DeviceImpl) then) =
      __$$DeviceImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String serialNumber,
      String status,
      ConnectionType connectionType,
      String? model,
      String? androidVersion,
      bool isConnected});
}

/// @nodoc
class __$$DeviceImplCopyWithImpl<$Res>
    extends _$DeviceCopyWithImpl<$Res, _$DeviceImpl>
    implements _$$DeviceImplCopyWith<$Res> {
  __$$DeviceImplCopyWithImpl(
      _$DeviceImpl _value, $Res Function(_$DeviceImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? serialNumber = null,
    Object? status = null,
    Object? connectionType = null,
    Object? model = freezed,
    Object? androidVersion = freezed,
    Object? isConnected = null,
  }) {
    return _then(_$DeviceImpl(
      serialNumber: null == serialNumber
          ? _value.serialNumber
          : serialNumber // ignore: cast_nullable_to_non_nullable
              as String,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as String,
      connectionType: null == connectionType
          ? _value.connectionType
          : connectionType // ignore: cast_nullable_to_non_nullable
              as ConnectionType,
      model: freezed == model
          ? _value.model
          : model // ignore: cast_nullable_to_non_nullable
              as String?,
      androidVersion: freezed == androidVersion
          ? _value.androidVersion
          : androidVersion // ignore: cast_nullable_to_non_nullable
              as String?,
      isConnected: null == isConnected
          ? _value.isConnected
          : isConnected // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$DeviceImpl implements _Device {
  const _$DeviceImpl(
      {required this.serialNumber,
      required this.status,
      required this.connectionType,
      this.model,
      this.androidVersion,
      this.isConnected = false});

  @override
  final String serialNumber;
  @override
  final String status;
  @override
  final ConnectionType connectionType;
  @override
  final String? model;
  @override
  final String? androidVersion;
  @override
  @JsonKey()
  final bool isConnected;

  @override
  String toString() {
    return 'Device(serialNumber: $serialNumber, status: $status, connectionType: $connectionType, model: $model, androidVersion: $androidVersion, isConnected: $isConnected)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeviceImpl &&
            (identical(other.serialNumber, serialNumber) ||
                other.serialNumber == serialNumber) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.connectionType, connectionType) ||
                other.connectionType == connectionType) &&
            (identical(other.model, model) || other.model == model) &&
            (identical(other.androidVersion, androidVersion) ||
                other.androidVersion == androidVersion) &&
            (identical(other.isConnected, isConnected) ||
                other.isConnected == isConnected));
  }

  @override
  int get hashCode => Object.hash(runtimeType, serialNumber, status,
      connectionType, model, androidVersion, isConnected);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DeviceImplCopyWith<_$DeviceImpl> get copyWith =>
      __$$DeviceImplCopyWithImpl<_$DeviceImpl>(this, _$identity);
}

abstract class _Device implements Device {
  const factory _Device(
      {required final String serialNumber,
      required final String status,
      required final ConnectionType connectionType,
      final String? model,
      final String? androidVersion,
      final bool isConnected}) = _$DeviceImpl;

  @override
  String get serialNumber;
  @override
  String get status;
  @override
  ConnectionType get connectionType;
  @override
  String? get model;
  @override
  String? get androidVersion;
  @override
  bool get isConnected;
  @override
  @JsonKey(ignore: true)
  _$$DeviceImplCopyWith<_$DeviceImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
