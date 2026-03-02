import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../models/file_item.dart';
import '../../providers/preview_provider.dart';

class PreviewDialog extends ConsumerStatefulWidget {
  final FileItem file;
  final String? serial;
  final String? localFilePath;

  const PreviewDialog({
    super.key,
    required this.file,
    this.serial,
    this.localFilePath,
  });

  @override
  ConsumerState<PreviewDialog> createState() => _PreviewDialogState();
}

class _PreviewDialogState extends ConsumerState<PreviewDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(previewNotifierProvider.notifier).previewFile(
            file: widget.file,
            serial: widget.serial,
            localFilePath: widget.localFilePath,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(previewNotifierProvider);
    final theme = Theme.of(context);

    // Auto-close on external open
    ref.listen(previewNotifierProvider, (prev, next) {
      if (next.result is ExternalOpenResult) {
        Navigator.of(context).pop();
      }
    });

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 800,
          maxHeight: 700,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.preview,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.file.name,
                      style: theme.textTheme.titleSmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                    splashRadius: 16,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: _buildContent(state, theme),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(PreviewState state, ThemeData theme) {
    if (state.isLoading) {
      return _LoadingView(
        progress: state.progress,
        statusText: state.statusText,
      );
    }

    if (state.error != null) {
      return _ErrorView(message: state.error!);
    }

    final result = state.result;
    if (result == null) {
      return const SizedBox.shrink();
    }

    return switch (result) {
      ImagePreviewResult(:final bytes) => _ImagePreview(bytes: bytes),
      TextPreviewResult(:final content, :final fileName) =>
        _TextPreview(content: content, fileName: fileName),
      FileInfoResult(:final file) => _FileInfoPreview(file: file),
      ExternalOpenResult() => const SizedBox.shrink(), // handled by listener
    };
  }
}

// --- Loading ---

class _LoadingView extends StatelessWidget {
  final double progress;
  final String statusText;

  const _LoadingView({required this.progress, required this.statusText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (progress > 0)
            LinearProgressIndicator(value: progress)
          else
            const LinearProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            statusText,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

// --- Error ---

class _ErrorView extends StatelessWidget {
  final String message;

  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// --- Image Preview ---

class _ImagePreview extends StatelessWidget {
  final Uint8List bytes;

  const _ImagePreview({required this.bytes});

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      maxScale: 10.0,
      child: Center(
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (_, error, __) => _ErrorView(
            message: 'Failed to decode image: $error',
          ),
        ),
      ),
    );
  }
}

// --- Text Preview ---

class _TextPreview extends StatelessWidget {
  final String content;
  final String fileName;

  const _TextPreview({required this.content, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        child: SelectableText(
          content,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }
}

// --- File Info Preview ---

class _FileInfoPreview extends StatelessWidget {
  final FileItem file;

  const _FileInfoPreview({required this.file});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm:ss');

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.insert_drive_file,
            size: 48,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 16),
          _PropertyRow('Name', file.name),
          _PropertyRow('Path', file.absolutePath),
          _PropertyRow('Size', FileSizeFormatter.format(file.sizeBytes)),
          _PropertyRow('Modified', dateFormat.format(file.modified)),
          if (file.permissions != null)
            _PropertyRow('Permissions', file.permissions!),
        ],
      ),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  final String label;
  final String value;

  const _PropertyRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
