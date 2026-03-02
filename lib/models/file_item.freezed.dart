// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'file_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$FileItem {
  String get name => throw _privateConstructorUsedError;
  String get absolutePath => throw _privateConstructorUsedError;
  bool get isDirectory => throw _privateConstructorUsedError;
  int get sizeBytes => throw _privateConstructorUsedError;
  DateTime get modified => throw _privateConstructorUsedError;
  String? get permissions => throw _privateConstructorUsedError;
  bool get isSymlink => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $FileItemCopyWith<FileItem> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FileItemCopyWith<$Res> {
  factory $FileItemCopyWith(FileItem value, $Res Function(FileItem) then) =
      _$FileItemCopyWithImpl<$Res, FileItem>;
  @useResult
  $Res call(
      {String name,
      String absolutePath,
      bool isDirectory,
      int sizeBytes,
      DateTime modified,
      String? permissions,
      bool isSymlink});
}

/// @nodoc
class _$FileItemCopyWithImpl<$Res, $Val extends FileItem>
    implements $FileItemCopyWith<$Res> {
  _$FileItemCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? absolutePath = null,
    Object? isDirectory = null,
    Object? sizeBytes = null,
    Object? modified = null,
    Object? permissions = freezed,
    Object? isSymlink = null,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      absolutePath: null == absolutePath
          ? _value.absolutePath
          : absolutePath // ignore: cast_nullable_to_non_nullable
              as String,
      isDirectory: null == isDirectory
          ? _value.isDirectory
          : isDirectory // ignore: cast_nullable_to_non_nullable
              as bool,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      modified: null == modified
          ? _value.modified
          : modified // ignore: cast_nullable_to_non_nullable
              as DateTime,
      permissions: freezed == permissions
          ? _value.permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as String?,
      isSymlink: null == isSymlink
          ? _value.isSymlink
          : isSymlink // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FileItemImplCopyWith<$Res>
    implements $FileItemCopyWith<$Res> {
  factory _$$FileItemImplCopyWith(
          _$FileItemImpl value, $Res Function(_$FileItemImpl) then) =
      __$$FileItemImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String absolutePath,
      bool isDirectory,
      int sizeBytes,
      DateTime modified,
      String? permissions,
      bool isSymlink});
}

/// @nodoc
class __$$FileItemImplCopyWithImpl<$Res>
    extends _$FileItemCopyWithImpl<$Res, _$FileItemImpl>
    implements _$$FileItemImplCopyWith<$Res> {
  __$$FileItemImplCopyWithImpl(
      _$FileItemImpl _value, $Res Function(_$FileItemImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? absolutePath = null,
    Object? isDirectory = null,
    Object? sizeBytes = null,
    Object? modified = null,
    Object? permissions = freezed,
    Object? isSymlink = null,
  }) {
    return _then(_$FileItemImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      absolutePath: null == absolutePath
          ? _value.absolutePath
          : absolutePath // ignore: cast_nullable_to_non_nullable
              as String,
      isDirectory: null == isDirectory
          ? _value.isDirectory
          : isDirectory // ignore: cast_nullable_to_non_nullable
              as bool,
      sizeBytes: null == sizeBytes
          ? _value.sizeBytes
          : sizeBytes // ignore: cast_nullable_to_non_nullable
              as int,
      modified: null == modified
          ? _value.modified
          : modified // ignore: cast_nullable_to_non_nullable
              as DateTime,
      permissions: freezed == permissions
          ? _value.permissions
          : permissions // ignore: cast_nullable_to_non_nullable
              as String?,
      isSymlink: null == isSymlink
          ? _value.isSymlink
          : isSymlink // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc

class _$FileItemImpl implements _FileItem {
  const _$FileItemImpl(
      {required this.name,
      required this.absolutePath,
      required this.isDirectory,
      required this.sizeBytes,
      required this.modified,
      this.permissions,
      this.isSymlink = false});

  @override
  final String name;
  @override
  final String absolutePath;
  @override
  final bool isDirectory;
  @override
  final int sizeBytes;
  @override
  final DateTime modified;
  @override
  final String? permissions;
  @override
  @JsonKey()
  final bool isSymlink;

  @override
  String toString() {
    return 'FileItem(name: $name, absolutePath: $absolutePath, isDirectory: $isDirectory, sizeBytes: $sizeBytes, modified: $modified, permissions: $permissions, isSymlink: $isSymlink)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FileItemImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.absolutePath, absolutePath) ||
                other.absolutePath == absolutePath) &&
            (identical(other.isDirectory, isDirectory) ||
                other.isDirectory == isDirectory) &&
            (identical(other.sizeBytes, sizeBytes) ||
                other.sizeBytes == sizeBytes) &&
            (identical(other.modified, modified) ||
                other.modified == modified) &&
            (identical(other.permissions, permissions) ||
                other.permissions == permissions) &&
            (identical(other.isSymlink, isSymlink) ||
                other.isSymlink == isSymlink));
  }

  @override
  int get hashCode => Object.hash(runtimeType, name, absolutePath, isDirectory,
      sizeBytes, modified, permissions, isSymlink);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$FileItemImplCopyWith<_$FileItemImpl> get copyWith =>
      __$$FileItemImplCopyWithImpl<_$FileItemImpl>(this, _$identity);
}

abstract class _FileItem implements FileItem {
  const factory _FileItem(
      {required final String name,
      required final String absolutePath,
      required final bool isDirectory,
      required final int sizeBytes,
      required final DateTime modified,
      final String? permissions,
      final bool isSymlink}) = _$FileItemImpl;

  @override
  String get name;
  @override
  String get absolutePath;
  @override
  bool get isDirectory;
  @override
  int get sizeBytes;
  @override
  DateTime get modified;
  @override
  String? get permissions;
  @override
  bool get isSymlink;
  @override
  @JsonKey(ignore: true)
  _$$FileItemImplCopyWith<_$FileItemImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
