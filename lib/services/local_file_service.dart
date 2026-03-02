import 'dart:io';
import '../core/utils/platform_utils.dart';
import '../models/file_item.dart';

class LocalFileService {
  Future<List<FileItem>> listDirectory(String path) async {
    final dir = Directory(path);
    if (!await dir.exists()) {
      throw FileSystemException('Directory does not exist', path);
    }

    final items = <FileItem>[];
    await for (final entity in dir.list()) {
      try {
        final stat = await entity.stat();
        final name =
            entity.uri.pathSegments.where((s) => s.isNotEmpty).last;
        items.add(FileItem(
          name: name,
          absolutePath: entity.path,
          isDirectory: entity is Directory,
          sizeBytes: stat.size,
          modified: stat.modified,
          isSymlink: stat.type == FileSystemEntityType.link,
        ));
      } catch (_) {
        // Skip files we can't stat (permission denied, etc.)
      }
    }

    items.sort((a, b) {
      if (a.isDirectory != b.isDirectory) {
        return a.isDirectory ? -1 : 1;
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return items;
  }

  String getHomeDirectory() => PlatformUtils.homeDirectory;

  List<String> getRoots() => PlatformUtils.fileSystemRoots;
}
