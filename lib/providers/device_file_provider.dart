import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/file_item.dart';
import '../models/sort_option.dart';
import '../services/file_service.dart';
import 'adb_provider.dart';

class DeviceFileState {
  final String currentPath;
  final List<FileItem> files;
  final bool isLoading;
  final List<String> pathHistory;
  final int historyIndex;
  final String? errorMessage;
  final Set<String> selectedFiles;
  final String searchQuery;
  final SortField sortField;
  final bool sortAscending;
  final Map<String, int> directorySizes;
  final Set<String>? pendingDeletePaths;

  const DeviceFileState({
    this.currentPath = AdbConstants.defaultDevicePath,
    this.files = const [],
    this.isLoading = false,
    this.pathHistory = const [AdbConstants.defaultDevicePath],
    this.historyIndex = 0,
    this.errorMessage,
    this.selectedFiles = const {},
    this.searchQuery = '',
    this.sortField = SortField.name,
    this.sortAscending = true,
    this.directorySizes = const {},
    this.pendingDeletePaths,
  });

  DeviceFileState copyWith({
    String? currentPath,
    List<FileItem>? files,
    bool? isLoading,
    List<String>? pathHistory,
    int? historyIndex,
    String? errorMessage,
    Set<String>? selectedFiles,
    String? searchQuery,
    SortField? sortField,
    bool? sortAscending,
    bool clearError = false,
    Map<String, int>? directorySizes,
    Set<String>? pendingDeletePaths,
    bool clearPendingDelete = false,
  }) {
    return DeviceFileState(
      currentPath: currentPath ?? this.currentPath,
      files: files ?? this.files,
      isLoading: isLoading ?? this.isLoading,
      pathHistory: pathHistory ?? this.pathHistory,
      historyIndex: historyIndex ?? this.historyIndex,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      selectedFiles: selectedFiles ?? this.selectedFiles,
      searchQuery: searchQuery ?? this.searchQuery,
      sortField: sortField ?? this.sortField,
      sortAscending: sortAscending ?? this.sortAscending,
      directorySizes: directorySizes ?? this.directorySizes,
      pendingDeletePaths:
          clearPendingDelete ? null : (pendingDeletePaths ?? this.pendingDeletePaths),
    );
  }

  bool get canGoBack => historyIndex > 0;
  bool get canGoForward => historyIndex < pathHistory.length - 1;

  List<FileItem> get filteredAndSortedFiles {
    var result = files.toList();

    // Filter by search
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result
          .where((f) => f.name.toLowerCase().contains(query))
          .toList();
    }

    // Sort: directories always first
    final dirs = result.where((f) => f.isDirectory).toList();
    final files_ = result.where((f) => !f.isDirectory).toList();

    dirs.sort((a, b) => _compare(a, b));
    files_.sort((a, b) => _compare(a, b));

    return [...dirs, ...files_];
  }

  int _compare(FileItem a, FileItem b) {
    int result;
    switch (sortField) {
      case SortField.name:
        result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      case SortField.size:
        result = a.sizeBytes.compareTo(b.sizeBytes);
      case SortField.date:
        result = a.modified.compareTo(b.modified);
      case SortField.type:
        final extA = a.name.contains('.') ? a.name.split('.').last : '';
        final extB = b.name.contains('.') ? b.name.split('.').last : '';
        result = extA.compareTo(extB);
        if (result == 0) {
          result = a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
    }
    return sortAscending ? result : -result;
  }

  int get selectedTotalBytes {
    return files
        .where((f) => selectedFiles.contains(f.absolutePath))
        .fold(0, (sum, f) => sum + f.sizeBytes);
  }
}

class DeviceFileNotifier extends StateNotifier<DeviceFileState> {
  final FileService _fileService;
  final String _serial;
  Timer? _deletionTimer;

  DeviceFileNotifier(this._fileService, this._serial)
      : super(const DeviceFileState());

  @override
  void dispose() {
    _deletionTimer?.cancel();
    super.dispose();
  }

  Future<void> navigateTo(String path) async {
    state = state.copyWith(
        isLoading: true, clearError: true, selectedFiles: {}, searchQuery: '');
    try {
      final files = await _fileService.listDirectory(_serial, path);
      final newHistory =
          state.pathHistory.sublist(0, state.historyIndex + 1)..add(path);
      state = state.copyWith(
        currentPath: path,
        files: files,
        isLoading: false,
        pathHistory: newHistory,
        historyIndex: newHistory.length - 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final files =
          await _fileService.listDirectory(_serial, state.currentPath);
      state = state.copyWith(files: files, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> goBack() async {
    if (!state.canGoBack) return;
    final newIndex = state.historyIndex - 1;
    final path = state.pathHistory[newIndex];
    state = state.copyWith(
        isLoading: true, clearError: true, selectedFiles: {}, searchQuery: '');
    try {
      final files = await _fileService.listDirectory(_serial, path);
      state = state.copyWith(
        currentPath: path,
        files: files,
        isLoading: false,
        historyIndex: newIndex,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> goForward() async {
    if (!state.canGoForward) return;
    final newIndex = state.historyIndex + 1;
    final path = state.pathHistory[newIndex];
    state = state.copyWith(
        isLoading: true, clearError: true, selectedFiles: {}, searchQuery: '');
    try {
      final files = await _fileService.listDirectory(_serial, path);
      state = state.copyWith(
        currentPath: path,
        files: files,
        isLoading: false,
        historyIndex: newIndex,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<void> goUp() async {
    if (state.currentPath == '/') return;
    final parts = state.currentPath.split('/');
    parts.removeLast();
    final parent = parts.isEmpty ? '/' : parts.join('/');
    await navigateTo(parent.isEmpty ? '/' : parent);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSort(SortField field) {
    if (state.sortField == field) {
      state = state.copyWith(sortAscending: !state.sortAscending);
    } else {
      state = state.copyWith(sortField: field, sortAscending: true);
    }
  }

  void toggleSelect(String absolutePath) {
    final selected = Set<String>.from(state.selectedFiles);
    if (selected.contains(absolutePath)) {
      selected.remove(absolutePath);
    } else {
      selected.add(absolutePath);
    }
    state = state.copyWith(selectedFiles: selected);
  }

  void selectAll() {
    state = state.copyWith(
      selectedFiles:
          state.filteredAndSortedFiles.map((f) => f.absolutePath).toSet(),
    );
  }

  void clearSelection() {
    state = state.copyWith(selectedFiles: {});
  }

  Future<void> deleteSelected() async {
    for (final path in state.selectedFiles) {
      await _fileService.delete(_serial, path);
    }
    await refresh();
  }

  Future<void> renameFile(String oldPath, String newName) async {
    final parts = oldPath.split('/');
    parts.removeLast();
    final newPath = '${parts.join('/')}/$newName';
    await _fileService.rename(_serial, oldPath, newPath);
    await refresh();
  }

  Future<void> createDirectory(String name) async {
    final path = '${state.currentPath}/$name';
    await _fileService.createDirectory(_serial, path);
    await refresh();
  }

  Future<void> batchRename(
    List<FileItem> items,
    String prefix,
    int startIndex,
    int padWidth,
  ) async {
    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final ext = item.name.contains('.') && !item.isDirectory
          ? '.${item.name.split('.').last}'
          : '';
      final num = (startIndex + i).toString().padLeft(padWidth, '0');
      final newName = '$prefix$num$ext';
      final parts = item.absolutePath.split('/');
      parts.removeLast();
      final newPath = '${parts.join('/')}/$newName';
      await _fileService.rename(_serial, item.absolutePath, newPath);
    }
    await refresh();
  }

  Future<void> loadDirectorySize(String path) async {
    try {
      final size = await _fileService.getDirectorySize(_serial, path);
      final newSizes = Map<String, int>.from(state.directorySizes);
      newSizes[path] = size;
      state = state.copyWith(directorySizes: newSizes);
    } catch (_) {}
  }

  Future<void> scheduleDeletion() async {
    final toDelete = Set<String>.from(state.selectedFiles);
    if (toDelete.isEmpty) return;
    state = state.copyWith(pendingDeletePaths: toDelete, selectedFiles: {});
    _deletionTimer = Timer(const Duration(seconds: 5), () async {
      await _executeDelete(toDelete);
    });
  }

  void cancelDeletion() {
    _deletionTimer?.cancel();
    _deletionTimer = null;
    final toRestore = state.pendingDeletePaths ?? {};
    state = state.copyWith(
      selectedFiles: toRestore,
      clearPendingDelete: true,
    );
  }

  Future<void> _executeDelete(Set<String> paths) async {
    state = state.copyWith(clearPendingDelete: true);
    for (final path in paths) {
      await _fileService.delete(_serial, path);
    }
    await refresh();
  }
}

final deviceFileProvider =
    StateNotifierProvider.family<DeviceFileNotifier, DeviceFileState, String>(
        (ref, serial) {
  return DeviceFileNotifier(ref.read(fileServiceProvider), serial);
});
