import 'package:freezed_annotation/freezed_annotation.dart';

part 'file_item.freezed.dart';

@freezed
class FileItem with _$FileItem {
  const factory FileItem({
    required String name,
    required String absolutePath,
    required bool isDirectory,
    required int sizeBytes,
    required DateTime modified,
    String? permissions,
    @Default(false) bool isSymlink,
  }) = _FileItem;
}
