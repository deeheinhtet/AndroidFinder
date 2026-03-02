import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/utils/file_size_formatter.dart';
import '../../models/file_item.dart';

class FileItemTile extends StatelessWidget {
  final FileItem file;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback onDoubleTap;

  const FileItemTile({
    super.key,
    required this.file,
    required this.isSelected,
    required this.onTap,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy HH:mm');

    return InkWell(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final showDate = width > 400;
          final showPermissions = width > 500 && file.permissions != null;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                  : null,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outline.withOpacity(0.05),
                ),
              ),
            ),
            child: Row(
              children: [
                _buildIcon(theme),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Text(
                    file.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: file.isDirectory ? FontWeight.w600 : null,
                      color: file.isSymlink
                          ? theme.colorScheme.primary
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    file.isDirectory ? '--' : FileSizeFormatter.format(file.sizeBytes),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
                if (showDate) ...[
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 130,
                    child: Text(
                      dateFormat.format(file.modified),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                ],
                if (showPermissions)
                  SizedBox(
                    width: 90,
                    child: Text(
                      file.permissions!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildIcon(ThemeData theme) {
    if (file.isDirectory) {
      return Icon(
        Icons.folder,
        size: 20,
        color: theme.colorScheme.primary.withOpacity(0.8),
      );
    }

    final ext = file.name.split('.').last.toLowerCase();
    IconData iconData;
    Color iconColor;

    switch (ext) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
      case 'webp':
        iconData = Icons.image;
        iconColor = Colors.orange;
      case 'mp4':
      case 'mkv':
      case 'avi':
      case 'mov':
      case 'wmv':
        iconData = Icons.movie;
        iconColor = Colors.red;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
      case 'ogg':
        iconData = Icons.music_note;
        iconColor = Colors.purple;
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.redAccent;
      case 'apk':
        iconData = Icons.android;
        iconColor = Colors.green;
      case 'zip':
      case 'rar':
      case 'tar':
      case 'gz':
      case '7z':
        iconData = Icons.archive;
        iconColor = Colors.brown;
      case 'txt':
      case 'log':
      case 'md':
        iconData = Icons.description;
        iconColor = Colors.blueGrey;
      case 'json':
      case 'xml':
      case 'yaml':
      case 'yml':
        iconData = Icons.data_object;
        iconColor = Colors.teal;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = theme.colorScheme.onSurface.withOpacity(0.5);
    }

    return Icon(iconData, size: 20, color: iconColor);
  }
}
