import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/file_item.dart';
import '../services/preview_service.dart';
import 'adb_provider.dart';

// --- Result types ---

sealed class PreviewResult {}

class ImagePreviewResult extends PreviewResult {
  final Uint8List bytes;
  ImagePreviewResult(this.bytes);
}

class TextPreviewResult extends PreviewResult {
  final String content;
  final String fileName;
  TextPreviewResult(this.content, this.fileName);
}

class ExternalOpenResult extends PreviewResult {}

class FileInfoResult extends PreviewResult {
  final FileItem file;
  FileInfoResult(this.file);
}

// --- State ---

class PreviewState {
  final bool isLoading;
  final double progress;
  final String statusText;
  final PreviewResult? result;
  final String? error;

  const PreviewState({
    this.isLoading = false,
    this.progress = 0.0,
    this.statusText = '',
    this.result,
    this.error,
  });

  PreviewState copyWith({
    bool? isLoading,
    double? progress,
    String? statusText,
    PreviewResult? result,
    String? error,
  }) {
    return PreviewState(
      isLoading: isLoading ?? this.isLoading,
      progress: progress ?? this.progress,
      statusText: statusText ?? this.statusText,
      result: result ?? this.result,
      error: error ?? this.error,
    );
  }
}

// --- Notifier ---

class PreviewNotifier extends StateNotifier<PreviewState> {
  final PreviewService _previewService;

  PreviewNotifier(this._previewService) : super(const PreviewState());

  Future<void> previewFile({
    required FileItem file,
    String? serial,
    String? localFilePath,
  }) async {
    state = const PreviewState(isLoading: true, statusText: 'Classifying file...');

    try {
      final category = _previewService.classifyFile(file.name);

      // APK → file info only
      if (category == FileCategory.apk) {
        state = PreviewState(result: FileInfoResult(file));
        return;
      }

      // Unsupported → file info
      if (category == FileCategory.unsupported) {
        state = PreviewState(result: FileInfoResult(file));
        return;
      }

      // Determine local path
      String localPath;
      if (localFilePath != null) {
        // Local panel file — already on disk
        localPath = localFilePath;
      } else if (serial != null) {
        // Device file — pull to cache
        state = state.copyWith(statusText: 'Pulling file from device...');
        localPath = await _previewService.pullToCache(
          serial,
          file.absolutePath,
          file.modified,
          onProgress: (bytes) {
            final totalBytes = file.sizeBytes;
            final prog = totalBytes > 0 ? (bytes / totalBytes).clamp(0.0, 1.0) : 0.0;
            state = state.copyWith(
              progress: prog,
              statusText: 'Pulling file... ${(prog * 100).toInt()}%',
            );
          },
        );
      } else {
        state = const PreviewState(error: 'No file source specified');
        return;
      }

      // Route by category
      switch (category) {
        case FileCategory.image:
          if (file.sizeBytes > PreviewService.maxInlineImageBytes) {
            state = state.copyWith(statusText: 'Opening with system viewer...');
            await _previewService.openWithSystem(localPath);
            state = PreviewState(result: ExternalOpenResult());
          } else {
            state = state.copyWith(statusText: 'Loading image...');
            final bytes = await File(localPath).readAsBytes();
            state = PreviewState(result: ImagePreviewResult(Uint8List.fromList(bytes)));
          }

        case FileCategory.text:
          if (file.sizeBytes > PreviewService.maxInlineTextBytes) {
            state = state.copyWith(statusText: 'Opening with system editor...');
            await _previewService.openWithSystem(localPath);
            state = PreviewState(result: ExternalOpenResult());
          } else {
            state = state.copyWith(statusText: 'Reading file...');
            final content = await _previewService.readTextContent(localPath);
            state = PreviewState(result: TextPreviewResult(content, file.name));
          }

        case FileCategory.video:
        case FileCategory.audio:
        case FileCategory.pdf:
          state = state.copyWith(statusText: 'Opening with system app...');
          await _previewService.openWithSystem(localPath);
          state = PreviewState(result: ExternalOpenResult());

        case FileCategory.apk:
        case FileCategory.unsupported:
          // Already handled above, but satisfy exhaustiveness
          state = PreviewState(result: FileInfoResult(file));
      }
    } catch (e) {
      state = PreviewState(error: e.toString());
    }
  }
}

// --- Providers ---

final previewServiceProvider = Provider<PreviewService>((ref) {
  return PreviewService(ref.read(fileServiceProvider));
});

final previewNotifierProvider =
    StateNotifierProvider.autoDispose<PreviewNotifier, PreviewState>((ref) {
  return PreviewNotifier(ref.read(previewServiceProvider));
});
