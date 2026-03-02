class AdbNotFoundException implements Exception {
  final String message;
  AdbNotFoundException(
      [this.message =
          'ADB not found. Please install Android SDK Platform Tools.']);
  @override
  String toString() => 'AdbNotFoundException: $message';
}

class AdbCommandException implements Exception {
  final String command;
  final int exitCode;
  final String stderr;
  AdbCommandException(this.command, this.exitCode, this.stderr);
  @override
  String toString() =>
      'AdbCommandException: "$command" exited with $exitCode: $stderr';
}

class DeviceUnreachableException implements Exception {
  final String serial;
  DeviceUnreachableException(this.serial);
  @override
  String toString() => 'DeviceUnreachableException: $serial is unreachable';
}

class TransferFailedException implements Exception {
  final String sourcePath;
  final String destPath;
  final String reason;
  TransferFailedException(this.sourcePath, this.destPath, this.reason);
  @override
  String toString() =>
      'TransferFailedException: $sourcePath -> $destPath: $reason';
}
