import 'dart:io';

class PlatformUtils {
  static bool get isWindows => Platform.isWindows;
  static bool get isMacOS => Platform.isMacOS;
  static bool get isLinux => Platform.isLinux;

  static String get adbExecutable => isWindows ? 'adb.exe' : 'adb';

  static String get homeDirectory {
    if (isWindows) {
      return Platform.environment['USERPROFILE'] ?? 'C:\\';
    }
    return Platform.environment['HOME'] ?? '/';
  }

  static List<String> get fileSystemRoots {
    if (isWindows) {
      // Common Windows drive letters
      final roots = <String>[];
      for (var letter = 'A'.codeUnitAt(0); letter <= 'Z'.codeUnitAt(0); letter++) {
        final drive = '${String.fromCharCode(letter)}:\\';
        if (Directory(drive).existsSync()) {
          roots.add(drive);
        }
      }
      return roots.isEmpty ? ['C:\\'] : roots;
    }
    return ['/'];
  }
}
