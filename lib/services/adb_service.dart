import 'dart:io';
import 'dart:typed_data';
import '../core/constants.dart';
import '../core/exceptions.dart';
import '../core/utils/platform_utils.dart';

class AdbService {
  String? _adbPath;

  Future<String> getAdbPath() async {
    if (_adbPath != null) return _adbPath!;

    // Check ANDROID_HOME first
    final androidHome = Platform.environment['ANDROID_HOME'] ??
        Platform.environment['ANDROID_SDK_ROOT'];
    if (androidHome != null) {
      final adbInSdk = PlatformUtils.isWindows
          ? '$androidHome\\platform-tools\\${PlatformUtils.adbExecutable}'
          : '$androidHome/platform-tools/${PlatformUtils.adbExecutable}';
      if (await File(adbInSdk).exists()) {
        _adbPath = adbInSdk;
        return _adbPath!;
      }
    }

    // Try which/where
    try {
      final result = await Process.run(
        PlatformUtils.isWindows ? 'where' : 'which',
        [PlatformUtils.adbExecutable],
      );
      if (result.exitCode == 0) {
        _adbPath = (result.stdout as String).trim().split('\n').first;
        return _adbPath!;
      }
    } catch (_) {}

    throw AdbNotFoundException();
  }

  Future<String> runAdb(
    List<String> args, {
    Duration timeout = AdbConstants.commandTimeout,
  }) async {
    final adbPath = await getAdbPath();
    final result = await Process.run(adbPath, args).timeout(timeout);
    if (result.exitCode != 0) {
      throw AdbCommandException(
        'adb ${args.join(' ')}',
        result.exitCode,
        result.stderr as String,
      );
    }
    return result.stdout as String;
  }

  Future<String> runAdbForDevice(
    String serial,
    List<String> args, {
    Duration timeout = AdbConstants.commandTimeout,
  }) {
    return runAdb(['-s', serial, ...args], timeout: timeout);
  }

  /// Runs a shell command on the device.
  /// Splits the command string into separate arguments so that
  /// `Process.run` passes them correctly to `adb shell`.
  /// Does not throw on non-zero exit codes because `adb shell` returns
  /// the remote command's exit code (e.g., `ls` on a restricted dir returns 1
  /// but still produces valid output).
  Future<String> shell(
    String serial,
    List<String> commandArgs, {
    Duration timeout = AdbConstants.commandTimeout,
    bool throwOnError = false,
  }) async {
    final adbPath = await getAdbPath();
    final args = ['-s', serial, 'shell', ...commandArgs];
    final result = await Process.run(adbPath, args).timeout(timeout);
    final stdout = result.stdout as String;
    final stderr = result.stderr as String;

    if (throwOnError && result.exitCode != 0 && stdout.trim().isEmpty) {
      throw AdbCommandException(
          'adb ${args.join(' ')}', result.exitCode, stderr);
    }

    return stdout.isNotEmpty ? stdout : stderr;
  }

  /// Pairs with a device over Wi-Fi using `adb pair <ip>:<port>`.
  /// The pairing code is sent via stdin since adb pair prompts for it.
  Future<String> pairDevice(String ip, int port, String pairingCode) async {
    final adbPath = await getAdbPath();
    final target = '$ip:$port';
    final process = await Process.start(adbPath, ['pair', target]);

    // Send the pairing code when prompted
    process.stdin.writeln(pairingCode);
    await process.stdin.close();

    final stdout = await process.stdout.transform(const SystemEncoding().decoder).join();
    final stderr = await process.stderr.transform(const SystemEncoding().decoder).join();
    final exitCode = await process.exitCode.timeout(AdbConstants.commandTimeout);

    if (exitCode != 0 || stderr.contains('Failed') || stderr.contains('error')) {
      throw AdbCommandException('adb pair $target', exitCode, stderr.isNotEmpty ? stderr : stdout);
    }

    return stdout;
  }

  Future<String> installApk(String serial, String localApkPath) async {
    return runAdbForDevice(
      serial,
      ['install', '-r', localApkPath],
      timeout: AdbConstants.longCommandTimeout,
    );
  }

  Future<({int total, int used, int free})> getStorageInfo(
      String serial) async {
    final output = await shell(serial, ['df', '/data']);
    final lines = output.trim().split('\n');
    // Parse the df output - second line has the data
    // Filesystem  1K-blocks  Used  Available  Use%  Mounted on
    for (final line in lines.skip(1)) {
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length >= 4) {
        final totalKb = int.tryParse(parts[1]) ?? 0;
        final usedKb = int.tryParse(parts[2]) ?? 0;
        final freeKb = int.tryParse(parts[3]) ?? 0;
        return (
          total: totalKb * 1024,
          used: usedKb * 1024,
          free: freeKb * 1024,
        );
      }
    }
    return (total: 0, used: 0, free: 0);
  }

  Future<Uint8List> captureScreenshot(String serial) async {
    final adbPath = await getAdbPath();
    final process = await Process.start(
      adbPath,
      ['-s', serial, 'exec-out', 'screencap', '-p'],
    );
    final bytes = <int>[];
    await for (final chunk in process.stdout) {
      bytes.addAll(chunk);
    }
    final exitCode =
        await process.exitCode.timeout(AdbConstants.commandTimeout);
    if (exitCode != 0) {
      final stderr = await process.stderr
          .transform(const SystemEncoding().decoder)
          .join();
      throw AdbCommandException('screencap', exitCode, stderr);
    }
    return Uint8List.fromList(bytes);
  }

  Future<void> ensureServerRunning() async {
    await runAdb(['start-server']);
  }
}
