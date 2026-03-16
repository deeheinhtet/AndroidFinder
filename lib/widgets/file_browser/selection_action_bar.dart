import 'package:flutter/material.dart';
import '../../core/utils/file_size_formatter.dart';

class SelectionActionBar extends StatelessWidget {
  final int selectedCount;
  final int selectedBytes;
  final bool isDevicePanel;
  final VoidCallback onClearSelection;
  final VoidCallback onSelectAll;
  final VoidCallback? onDelete;
  final VoidCallback? onDownload;
  final VoidCallback? onUpload;
  final VoidCallback? onBatchRename;

  const SelectionActionBar({
    super.key,
    required this.selectedCount,
    required this.selectedBytes,
    required this.isDevicePanel,
    required this.onClearSelection,
    required this.onSelectAll,
    this.onDelete,
    this.onDownload,
    this.onUpload,
    this.onBatchRename,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Flexible(
            child: Text(
              '$selectedCount selected${selectedBytes > 0 ? ' (${FileSizeFormatter.format(selectedBytes)})' : ''}',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          _ActionButton(
            icon: Icons.select_all,
            label: 'All',
            onPressed: onSelectAll,
          ),
          _ActionButton(
            icon: Icons.deselect,
            label: 'None',
            onPressed: onClearSelection,
          ),
          if (isDevicePanel && selectedCount > 1 && onBatchRename != null)
            _ActionButton(
              icon: Icons.drive_file_rename_outline,
              label: 'Rename',
              onPressed: onBatchRename,
            ),
          if (isDevicePanel && onDownload != null)
            _ActionButton(
              icon: Icons.download,
              label: 'Download',
              onPressed: onDownload,
            ),
          if (!isDevicePanel && onUpload != null)
            _ActionButton(
              icon: Icons.upload,
              label: 'Upload',
              onPressed: onUpload,
            ),
          if (isDevicePanel && onDelete != null)
            _ActionButton(
              icon: Icons.delete_outline,
              label: 'Delete',
              onPressed: onDelete,
              color: theme.colorScheme.error,
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color? color;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 14, color: color),
      label: Text(label, style: TextStyle(fontSize: 12, color: color)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(0, 28),
      ),
    );
  }
}
