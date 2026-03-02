class AdbConstants {
  static const String defaultAdbPort = '5555';
  static const Duration commandTimeout = Duration(seconds: 30);
  static const Duration longCommandTimeout = Duration(minutes: 10);
  static const String defaultDevicePath = '/sdcard';
  static const int maxConcurrentTransfers = 3;
  static const Duration progressPollInterval = Duration(milliseconds: 500);
}
