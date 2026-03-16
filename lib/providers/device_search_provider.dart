import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_item.dart';
import '../services/file_service.dart';
import 'adb_provider.dart';

class DeviceSearchState {
  final String query;
  final List<FileItem> results;
  final bool isSearching;
  final String? error;

  const DeviceSearchState({
    this.query = '',
    this.results = const [],
    this.isSearching = false,
    this.error,
  });

  DeviceSearchState copyWith({
    String? query,
    List<FileItem>? results,
    bool? isSearching,
    String? error,
    bool clearError = false,
  }) {
    return DeviceSearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isSearching: isSearching ?? this.isSearching,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DeviceSearchNotifier extends StateNotifier<DeviceSearchState> {
  final FileService _fileService;
  final String _serial;

  DeviceSearchNotifier(this._fileService, this._serial)
      : super(const DeviceSearchState());

  Future<void> search(String query, {String root = '/sdcard'}) async {
    if (query.trim().isEmpty) {
      state = const DeviceSearchState();
      return;
    }
    state = state.copyWith(
        query: query, results: [], isSearching: true, clearError: true);
    try {
      final results = <FileItem>[];
      await for (final path in _fileService.findFiles(_serial, root, query)) {
        final name = path.split('/').last;
        results.add(FileItem(
          name: name,
          absolutePath: path,
          isDirectory: false,
          sizeBytes: 0,
          modified: DateTime.now(),
        ));
        state = state.copyWith(results: List.from(results));
      }
      state = state.copyWith(isSearching: false);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: e.toString());
    }
  }

  void clear() {
    state = const DeviceSearchState();
  }
}

final deviceSearchProvider = StateNotifierProvider.autoDispose
    .family<DeviceSearchNotifier, DeviceSearchState, String>((ref, serial) {
  return DeviceSearchNotifier(ref.read(fileServiceProvider), serial);
});
