import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/file_item.dart';
import '../../providers/adb_provider.dart';
import '../../providers/device_file_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/local_file_provider.dart';
import '../../providers/transfer_provider.dart';
import 'file_properties_dialog.dart';
import 'preview_dialog.dart';

void showFileContextMenu({
  required BuildContext context,
  required WidgetRef ref,
  required Offset position,
  required FileItem file,
  required bool isDevicePanel,
  required String? serial,
  required String currentPath,
}) {
  final theme = Theme.of(context);

  showMenu(
    context: context,
    position: RelativeRect.fromLTRB(
        position.dx, position.dy, position.dx + 1, position.dy + 1),
    items: <PopupMenuEntry>[
      // Open folder
      if (file.isDirectory)
        PopupMenuItem(
          child: const _MenuTile(Icons.folder_open, 'Open'),
          onTap: () {
            if (isDevicePanel && serial != null) {
              ref
                  .read(deviceFileProvider(serial).notifier)
                  .navigateTo(file.absolutePath);
            } else {
              ref
                  .read(localFileProvider.notifier)
                  .navigateTo(file.absolutePath);
            }
          },
        ),

      // Preview (non-directory files)
      if (!file.isDirectory)
        PopupMenuItem(
          child: const _MenuTile(Icons.preview, 'Preview'),
          onTap: () {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              showDialog(
                context: context,
                builder: (context) => PreviewDialog(
                  file: file,
                  serial: isDevicePanel ? serial : null,
                  localFilePath: !isDevicePanel ? file.absolutePath : null,
                ),
              );
            });
          },
        ),

      // Download (device file)
      if (isDevicePanel && !file.isDirectory)
        PopupMenuItem(
          child: const _MenuTile(Icons.download, 'Download'),
          onTap: () async {
            if (serial == null) return;
            final dir = await FilePicker.platform.getDirectoryPath();
            if (dir != null) {
              ref.read(transferProvider.notifier).enqueueDownload(
                    serial,
                    file.absolutePath,
                    '$dir/${file.name}',
                    file.name,
                  );
            }
          },
        ),

      // Upload (local file)
      if (!isDevicePanel && !file.isDirectory && serial != null)
        PopupMenuItem(
          child: const _MenuTile(Icons.upload, 'Upload to Device'),
          onTap: () {
            final deviceState = ref.read(deviceProvider);
            final activeSerial = deviceState.activeSerial;
            if (activeSerial == null) return;
            final devicePath = ref
                .read(deviceFileProvider(activeSerial))
                .currentPath;
            ref.read(transferProvider.notifier).enqueueUpload(
                  activeSerial,
                  file.absolutePath,
                  '$devicePath/${file.name}',
                  file.name,
                );
          },
        ),

      // Copy to... (transfer to other panel's current dir)
      if (isDevicePanel && serial != null)
        PopupMenuItem(
          child: const _MenuTile(Icons.file_copy_outlined, 'Copy to Local...'),
          onTap: () async {
            final dir = await FilePicker.platform.getDirectoryPath();
            if (dir != null) {
              ref.read(transferProvider.notifier).enqueueDownload(
                    serial,
                    file.absolutePath,
                    '$dir/${file.name}',
                    file.name,
                  );
            }
          },
        ),
      if (!isDevicePanel && serial != null)
        PopupMenuItem(
          child: const _MenuTile(Icons.file_copy_outlined, 'Copy to Device...'),
          onTap: () {
            final deviceState = ref.read(deviceProvider);
            final activeSerial = deviceState.activeSerial;
            if (activeSerial == null) return;
            final devicePath = ref
                .read(deviceFileProvider(activeSerial))
                .currentPath;
            ref.read(transferProvider.notifier).enqueueUpload(
                  activeSerial,
                  file.absolutePath,
                  '$devicePath/${file.name}',
                  file.name,
                );
          },
        ),

      // Install APK (local .apk file only)
      if (!isDevicePanel &&
          serial != null &&
          file.name.toLowerCase().endsWith('.apk'))
        PopupMenuItem(
          child: const _MenuTile(Icons.install_mobile, 'Install on Device'),
          onTap: () {
            _installApk(context, ref, serial, file.absolutePath);
          },
        ),

      const PopupMenuDivider(),

      // Copy Path
      PopupMenuItem(
        child: const _MenuTile(Icons.content_copy, 'Copy Path'),
        onTap: () {
          Clipboard.setData(ClipboardData(text: file.absolutePath));
          _showSnackBar(context, 'Path copied to clipboard');
        },
      ),

      // Copy Name
      PopupMenuItem(
        child: const _MenuTile(Icons.abc, 'Copy Name'),
        onTap: () {
          Clipboard.setData(ClipboardData(text: file.name));
          _showSnackBar(context, 'Name copied to clipboard');
        },
      ),

      const PopupMenuDivider(),

      // Rename (device only)
      if (isDevicePanel)
        PopupMenuItem(
          child: const _MenuTile(Icons.drive_file_rename_outline, 'Rename'),
          onTap: () {
            if (serial == null) return;
            _showRenameDialog(context, ref, serial, file);
          },
        ),

      // Delete (device only)
      if (isDevicePanel)
        PopupMenuItem(
          child: _MenuTile(Icons.delete, 'Delete',
              color: theme.colorScheme.error),
          onTap: () {
            if (serial == null) return;
            _showDeleteDialog(context, ref, serial, file);
          },
        ),

      if (isDevicePanel) const PopupMenuDivider(),

      // Select All
      PopupMenuItem(
        child: const _MenuTile(Icons.select_all, 'Select All'),
        onTap: () {
          if (isDevicePanel && serial != null) {
            ref.read(deviceFileProvider(serial).notifier).selectAll();
          } else {
            ref.read(localFileProvider.notifier).selectAll();
          }
        },
      ),

      const PopupMenuDivider(),

      // Properties
      PopupMenuItem(
        child: const _MenuTile(Icons.info_outline, 'Properties'),
        onTap: () {
          _showPropertiesDialog(context, file);
        },
      ),
    ],
  );
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _MenuTile(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(color: color, fontSize: 14)),
      ],
    );
  }
}

void _showSnackBar(BuildContext context, String message) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        width: 250,
      ),
    );
  });
}

void _showPropertiesDialog(BuildContext context, FileItem file) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showDialog(
      context: context,
      builder: (context) => FilePropertiesDialog(file: file),
    );
  });
}

void _showRenameDialog(
    BuildContext context, WidgetRef ref, String serial, FileItem file) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final controller = TextEditingController(text: file.name);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) {
            if (controller.text.trim().isNotEmpty) {
              ref
                  .read(deviceFileProvider(serial).notifier)
                  .renameFile(file.absolutePath, controller.text.trim());
              Navigator.of(context).pop();
            }
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref
                    .read(deviceFileProvider(serial).notifier)
                    .renameFile(file.absolutePath, controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  });
}

void _installApk(
    BuildContext context, WidgetRef ref, String serial, String apkPath) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        final adb = ref.read(adbServiceProvider);
        return FutureBuilder(
          future: adb.installApk(serial, apkPath),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AlertDialog(
                content: Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Expanded(child: Text('Installing APK...')),
                  ],
                ),
              );
            }
            // Auto-close dialog and show result
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(dialogContext).pop();
              final success = snapshot.error == null;
              ScaffoldMessenger.of(dialogContext).showSnackBar(
                SnackBar(
                  content: Text(success
                      ? 'APK installed successfully'
                      : 'Installation failed: ${snapshot.error}'),
                  behavior: SnackBarBehavior.floating,
                  width: 350,
                  duration: const Duration(seconds: 3),
                ),
              );
            });
            return const SizedBox.shrink();
          },
        );
      },
    );
  });
}

void _showDeleteDialog(
    BuildContext context, WidgetRef ref, String serial, FileItem file) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text(
          'Are you sure you want to delete "${file.name}"?\n'
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Select this file and delete
              ref
                  .read(deviceFileProvider(serial).notifier)
                  .toggleSelect(file.absolutePath);
              ref
                  .read(deviceFileProvider(serial).notifier)
                  .deleteSelected();
              Navigator.of(context).pop();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  });
}
