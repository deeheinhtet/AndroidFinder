import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/platform_utils.dart';
import '../models/file_item.dart';
import '../models/sort_option.dart';
import '../services/local_file_service.dart';
import 'adb_provider.dart';

class LocalFileState {
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

  LocalFileState({
    String? currentPath,
    this.files = const [],
    this.isLoading = false,
    List<String>? pathHistory,
    this.historyIndex = 0,
    this.errorMessage,
    this.selectedFiles = const {},
    this.searchQuery = '',
    this.sortField = SortField.name,
    this.sortAscending = true,
  })  : currentPath = currentPath ?? PlatformUtils.homeDirectory,
        pathHistory = pathHistory ?? [PlatformUtils.homeDirectory];

  LocalFileState copyWith({
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
  }) {
    return LocalFileState(
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
    );
  }

  bool get canGoBack => historyIndex > 0;
  bool get canGoForward => historyIndex < pathHistory.length - 1;

  List<FileItem> get filteredAndSortedFiles {
    var result = files.toList();

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result =
          result.where((f) => f.name.toLowerCase().contains(query)).toList();
    }

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

class LocalFileNotifier extends StateNotifier<LocalFileState> {
  final LocalFileService _localFileService;

  LocalFileNotifier(this._localFileService) : super(LocalFileState());

  Future<void> navigateTo(String path) async {
    state = state.copyWith(
        isLoading: true, clearError: true, selectedFiles: {}, searchQuery: '');
    try {
      final files = await _localFileService.listDirectory(path);
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
      final files = await _localFileService.listDirectory(state.currentPath);
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
      final files = await _localFileService.listDirectory(path);
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
      final files = await _localFileService.listDirectory(path);
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
    final parts = state.currentPath.split('/');
    if (parts.length <= 2) {
      await navigateTo('/');
      return;
    }
    parts.removeLast();
    final parent = parts.join('/');
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
}

final localFileProvider =
    StateNotifierProvider<LocalFileNotifier, LocalFileState>((ref) {
  return LocalFileNotifier(ref.read(localFileServiceProvider));
});
