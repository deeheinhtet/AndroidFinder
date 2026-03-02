import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'file_service.dart';

enum FileCategory {
  image,
  video,
  audio,
  text,
  pdf,
  apk,
  unsupported,
}

class PreviewService {
  final FileService _fileService;

  PreviewService(this._fileService);

  static const int maxInlineImageBytes = 50 * 1024 * 1024; // 50 MB
  static const int maxInlineTextBytes = 5 * 1024 * 1024; // 5 MB

  static const _imageExtensions = {
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp', 'ico', 'svg',
  };
  static const _videoExtensions = {
    'mp4', 'mkv', 'avi', 'mov', 'wmv', 'flv', 'webm', '3gp',
  };
  static const _audioExtensions = {
    'mp3', 'wav', 'flac', 'aac', 'ogg', 'wma', 'm4a',
  };
  static const _textExtensions = {
    'txt', 'log', 'md', 'json', 'xml', 'yaml', 'yml', 'csv',
    'dart', 'js', 'ts', 'py', 'java', 'kt', 'c', 'cpp', 'h',
    'html', 'css', 'scss', 'sh', 'bash', 'zsh', 'bat', 'ps1',
    'rb', 'go', 'rs', 'swift', 'gradle', 'properties', 'cfg',
    'ini', 'toml', 'env', 'gitignore', 'dockerfile',
  };

  FileCategory classifyFile(String fileName) {
    final ext = _getExtension(fileName);
    if (ext.isEmpty) return FileCategory.text; // no extension → try as text
    if (_imageExtensions.contains(ext)) return FileCategory.image;
    if (_videoExtensions.contains(ext)) return FileCategory.video;
    if (_audioExtensions.contains(ext)) return FileCategory.audio;
    if (_textExtensions.contains(ext)) return FileCategory.text;
    if (ext == 'pdf') return FileCategory.pdf;
    if (ext == 'apk') return FileCategory.apk;
    return FileCategory.unsupported;
  }

  String _getExtension(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot < 0 || dot == fileName.length - 1) return '';
    return fileName.substring(dot + 1).toLowerCase();
  }

  /// Returns the cached file path. Skips re-pull if already cached.
  Future<String> pullToCache(
    String serial,
    String remotePath,
    DateTime modified, {
    void Function(int bytesTransferred)? onProgress,
  }) async {
    final cacheDir = await _getCacheDir();
    final fileName = p.basename(remotePath);
    final pathHash = remotePath.hashCode.toUnsigned(32).toRadixString(16);
    final modMs = modified.millisecondsSinceEpoch;
    final ext = _getExtension(fileName);
    final cacheKey = '${serial}_${pathHash}_$modMs${ext.isNotEmpty ? '.$ext' : ''}';
    final cachedFile = File(p.join(cacheDir.path, cacheKey));

    if (cachedFile.existsSync()) {
      return cachedFile.path;
    }

    await _fileService.pullFileWithProgress(
      serial,
      remotePath,
      cachedFile.path,
      onProgress: onProgress,
    );

    return cachedFile.path;
  }

  Future<String> readTextContent(String localPath) async {
    final file = File(localPath);
    return file.readAsString();
  }

  Future<void> openWithSystem(String localPath) async {
    if (Platform.isMacOS) {
      await Process.run('open', [localPath]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [localPath]);
    } else if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', localPath]);
    }
  }

  Future<Directory> _getCacheDir() async {
    final tempDir = await getTemporaryDirectory();
    final cacheDir = Directory(p.join(tempDir.path, 'android_finder_preview'));
    if (!cacheDir.existsSync()) {
      await cacheDir.create(recursive: true);
    }
    return cacheDir;
  }
}
