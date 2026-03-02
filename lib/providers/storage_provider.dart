import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'adb_provider.dart';

class StorageInfo {
  final int total;
  final int used;
  final int free;

  const StorageInfo({required this.total, required this.used, required this.free});

  double get usagePercent => total > 0 ? used / total : 0;

  String get formattedUsed => _formatBytes(used);
  String get formattedTotal => _formatBytes(total);

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${units[i]}';
  }
}

final storageProvider =
    FutureProvider.family<StorageInfo, String>((ref, serial) async {
  final adb = ref.read(adbServiceProvider);
  final info = await adb.getStorageInfo(serial);
  return StorageInfo(total: info.total, used: info.used, free: info.free);
});
