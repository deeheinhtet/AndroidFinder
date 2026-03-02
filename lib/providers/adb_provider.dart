import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/adb_service.dart';
import '../services/device_service.dart';
import '../services/file_service.dart';
import '../services/local_file_service.dart';
import '../services/transfer_service.dart';

final adbServiceProvider = Provider<AdbService>((ref) => AdbService());

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService(ref.read(adbServiceProvider));
});

final fileServiceProvider = Provider<FileService>((ref) {
  return FileService(ref.read(adbServiceProvider));
});

final localFileServiceProvider =
    Provider<LocalFileService>((ref) => LocalFileService());

final transferServiceProvider = Provider<TransferService>((ref) {
  return TransferService(ref.read(fileServiceProvider));
});
