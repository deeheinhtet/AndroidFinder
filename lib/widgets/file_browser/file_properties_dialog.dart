import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../models/file_item.dart';

class FilePropertiesDialog extends StatelessWidget {
  final FileItem file;

  const FilePropertiesDialog({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm:ss');

    return AlertDialog(
      title: Row(
        children: [
          Icon(
            file.isDirectory ? Icons.folder : Icons.insert_drive_file,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              file.name,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PropertyRow('Name', file.name),
            _PropertyRow('Path', file.absolutePath),
            _PropertyRow('Type', file.isDirectory
                ? 'Folder'
                : file.isSymlink
                    ? 'Symbolic Link'
                    : _getFileType(file.name)),
            _PropertyRow('Size', file.isDirectory
                ? '--'
                : FileSizeFormatter.format(file.sizeBytes)),
            _PropertyRow('Modified', dateFormat.format(file.modified)),
            if (file.permissions != null)
              _PropertyRow('Permissions', file.permissions!),
          ],
        ),
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  String _getFileType(String name) {
    if (!name.contains('.')) return 'File';
    final ext = name.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return 'Image ($ext)';
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
        return 'Video ($ext)';
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
      case 'ogg':
        return 'Audio ($ext)';
      case 'pdf':
        return 'PDF Document';
      case 'apk':
        return 'Android Package';
      case 'zip':
      case 'rar':
      case 'tar':
      case 'gz':
      case '7z':
        return 'Archive ($ext)';
      case 'txt':
      case 'log':
      case 'md':
        return 'Text ($ext)';
      case 'json':
      case 'xml':
      case 'yaml':
        return 'Data ($ext)';
      default:
        return '.$ext File';
    }
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
