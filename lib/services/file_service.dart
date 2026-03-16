import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../core/constants.dart';
import '../models/file_item.dart';
import 'adb_service.dart';

class FileService {
  final AdbService _adb;

  FileService(this._adb);

  Future<List<FileItem>> listDirectory(String serial, String path) async {
    // Ensure trailing slash so symlinks like /sdcard are followed
    final listPath = path.endsWith('/') ? path : '$path/';
    final output = await _adb.shell(serial, ['ls', '-la', listPath]);
    return _parseLsOutput(output, path);
  }

  List<FileItem> _parseLsOutput(String output, String parentPath) {
    final lines = output.trim().split('\n');
    final items = <FileItem>[];

    for (final line in lines) {
      if (line.startsWith('total ') || line.trim().isEmpty) continue;

      final item = _parseLsLine(line, parentPath);
      if (item != null && item.name != '.' && item.name != '..') {
        items.add(item);
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

  FileItem? _parseLsLine(String line, String parentPath) {
    final regex = RegExp(
      r'^([dlcbps\-][rwxsStT\-]{9})\s+\d+\s+\S+\s+\S+\s+(\d+)\s+'
      r'(\d{4}-\d{2}-\d{2})\s+(\d{2}:\d{2})\s+(.+)$',
    );

    final match = regex.firstMatch(line);
    if (match == null) return null;

    final permissions = match.group(1)!;
    final size = int.tryParse(match.group(2)!) ?? 0;
    final date = match.group(3)!;
    final time = match.group(4)!;
    var name = match.group(5)!;

    final isDirectory = permissions.startsWith('d');
    final isSymlink = permissions.startsWith('l');

    if (isSymlink && name.contains(' -> ')) {
      name = name.split(' -> ').first;
    }

    DateTime modified;
    try {
      modified = DateTime.parse('${date}T$time:00');
    } catch (_) {
      modified = DateTime.now();
    }

    final normalizedParent =
        parentPath.endsWith('/') ? parentPath : '$parentPath/';

    return FileItem(
      name: name,
      absolutePath: '$normalizedParent$name',
      isDirectory: isDirectory || isSymlink,
      sizeBytes: size,
      modified: modified,
      permissions: permissions,
      isSymlink: isSymlink,
    );
  }

  Future<void> pullFile(
      String serial, String remotePath, String localPath) async {
    await _adb.runAdbForDevice(
      serial,
      ['pull', remotePath, localPath],
      timeout: AdbConstants.longCommandTimeout,
    );
  }

  Future<void> pullFileWithProgress(
    String serial,
    String remotePath,
    String localPath, {
    void Function(int bytesTransferred)? onProgress,
  }) async {
    final adbPath = await _adb.getAdbPath();
    final process = await Process.start(
      adbPath,
      ['-s', serial, 'pull', remotePath, localPath],
    );

    Timer? pollTimer;
    if (onProgress != null) {
      pollTimer = Timer.periodic(
        AdbConstants.progressPollInterval,
        (_) {
          try {
            final file = File(localPath);
            if (file.existsSync()) {
              onProgress(file.lengthSync());
            }
          } catch (_) {}
        },
      );
    }

    final exitCode =
        await process.exitCode.timeout(AdbConstants.longCommandTimeout);
    pollTimer?.cancel();

    // Final size report
    if (onProgress != null) {
      try {
        final file = File(localPath);
        if (file.existsSync()) {
          onProgress(file.lengthSync());
        }
      } catch (_) {}
    }

    if (exitCode != 0) {
      final stderr = await process.stderr
          .transform(const SystemEncoding().decoder)
          .join();
      throw Exception('Pull failed: $stderr');
    }
  }

  Future<void> pushFile(
      String serial, String localPath, String remotePath) async {
    await _adb.runAdbForDevice(
      serial,
      ['push', localPath, remotePath],
      timeout: AdbConstants.longCommandTimeout,
    );
  }

  Future<void> pushFileWithProgress(
    String serial,
    String localPath,
    String remotePath, {
    void Function(int bytesTransferred)? onProgress,
  }) async {
    final adbPath = await _adb.getAdbPath();
    final process = await Process.start(
      adbPath,
      ['-s', serial, 'push', localPath, remotePath],
    );

    Timer? pollTimer;
    if (onProgress != null) {
      pollTimer = Timer.periodic(
        AdbConstants.progressPollInterval,
        (_) async {
          try {
            final output =
                await _adb.shell(serial, ['stat', '-c', '%s', remotePath]);
            final size = int.tryParse(output.trim()) ?? 0;
            onProgress(size);
          } catch (_) {}
        },
      );
    }

    final exitCode =
        await process.exitCode.timeout(AdbConstants.longCommandTimeout);
    pollTimer?.cancel();

    if (exitCode != 0) {
      final stderr = await process.stderr
          .transform(const SystemEncoding().decoder)
          .join();
      throw Exception('Push failed: $stderr');
    }
  }

  Future<void> delete(String serial, String path) async {
    await _adb.shell(serial, ['rm', '-rf', path]);
  }

  Future<void> rename(String serial, String oldPath, String newPath) async {
    await _adb.shell(serial, ['mv', oldPath, newPath]);
  }

  Future<void> move(String serial, String sourcePath, String destDir) async {
    await _adb.shell(serial, ['mv', sourcePath, '$destDir/']);
  }

  Future<void> copy(String serial, String sourcePath, String destDir) async {
    await _adb.shell(serial, ['cp', '-r', sourcePath, '$destDir/']);
  }

  Future<void> createDirectory(String serial, String path) async {
    await _adb.shell(serial, ['mkdir', '-p', path]);
  }

  Future<int> getFileSize(String serial, String path) async {
    final output = await _adb.shell(serial, ['stat', '-c', '%s', path]);
    return int.tryParse(output.trim()) ?? 0;
  }

  Future<bool> fileExistsOnDevice(String serial, String path) async {
    try {
      final output = await _adb
          .shell(serial, ['test', '-e', path, '&&', 'echo', '1', '||', 'echo', '0']);
      return output.trim() == '1';
    } catch (_) {
      return false;
    }
  }

  Future<bool> fileExistsLocally(String path) async {
    return File(path).exists();
  }

  Future<int> getDirectorySize(String serial, String path) async {
    try {
      final output = await _adb.shell(serial, ['du', '-sk', path]);
      final parts = output.trim().split('\t');
      final kb = int.tryParse(parts.first.trim()) ?? 0;
      return kb * 1024;
    } catch (_) {
      return 0;
    }
  }

  Stream<String> findFiles(String serial, String root, String pattern) async* {
    try {
      final adbPath = await _adb.getAdbPath();
      final process = await Process.start(adbPath, [
        '-s',
        serial,
        'shell',
        'find',
        root,
        '-iname',
        '*$pattern*',
        '-not',
        '-path',
        '*/proc/*',
        '-not',
        '-path',
        '*/sys/*',
      ]);
      int count = 0;
      await for (final line in process.stdout
          .transform(const SystemEncoding().decoder)
          .transform(const LineSplitter())) {
        final trimmed = line.trim();
        if (trimmed.isNotEmpty && !trimmed.startsWith('find:')) {
          yield trimmed;
          count++;
          if (count >= 500) break;
        }
      }
      process.kill();
    } catch (_) {}
  }
}
