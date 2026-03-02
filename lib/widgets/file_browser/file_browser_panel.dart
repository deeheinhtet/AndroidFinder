import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import '../../models/file_item.dart';
import '../../models/sort_option.dart';
import '../../providers/device_file_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/local_file_provider.dart';
import '../../providers/transfer_provider.dart';
import 'file_breadcrumb_bar.dart';
import 'file_context_menu.dart';
import 'file_item_tile.dart';
import 'file_toolbar.dart';
import 'preview_dialog.dart';
import 'selection_action_bar.dart';

class FileBrowserPanel extends ConsumerWidget {
  final bool isDevicePanel;
  final ValueNotifier<bool>? searchFocusTrigger;

  const FileBrowserPanel({
    super.key,
    required this.isDevicePanel,
    this.searchFocusTrigger,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceState = ref.watch(deviceProvider);
    final serial = deviceState.activeSerial;

    if (isDevicePanel && serial == null) {
      return const Center(child: Text('No device connected'));
    }

    // Read full state object once
    final devState =
        isDevicePanel ? ref.watch(deviceFileProvider(serial!)) : null;
    final locState = !isDevicePanel ? ref.watch(localFileProvider) : null;

    final currentPath =
        isDevicePanel ? devState!.currentPath : locState!.currentPath;
    final displayFiles = isDevicePanel
        ? devState!.filteredAndSortedFiles
        : locState!.filteredAndSortedFiles;
    final isLoading =
        isDevicePanel ? devState!.isLoading : locState!.isLoading;
    final errorMessage =
        isDevicePanel ? devState!.errorMessage : locState!.errorMessage;
    final selectedFiles =
        isDevicePanel ? devState!.selectedFiles : locState!.selectedFiles;
    final canGoBack =
        isDevicePanel ? devState!.canGoBack : locState!.canGoBack;
    final canGoForward =
        isDevicePanel ? devState!.canGoForward : locState!.canGoForward;
    final searchQuery =
        isDevicePanel ? devState!.searchQuery : locState!.searchQuery;
    final sortField =
        isDevicePanel ? devState!.sortField : locState!.sortField;
    final sortAscending =
        isDevicePanel ? devState!.sortAscending : locState!.sortAscending;
    final selectedTotalBytes =
        isDevicePanel ? devState!.selectedTotalBytes : locState!.selectedTotalBytes;

    return DropTarget(
      onDragDone: (details) {
        if (!isDevicePanel || serial == null) return;
        for (final file in details.files) {
          final fileName = file.path.split('/').last;
          ref.read(transferProvider.notifier).enqueueUpload(
                serial,
                file.path,
                '$currentPath/$fileName',
                fileName,
              );
        }
      },
      child: Column(
        children: [
          FileBreadcrumbBar(
            path: currentPath,
            label: isDevicePanel ? 'Device' : 'Local',
            icon: isDevicePanel ? Icons.phone_android : Icons.computer,
            onPathTap: (path) => _navigateTo(ref, serial, path),
          ),
          FileToolbar(
            canGoBack: canGoBack,
            canGoForward: canGoForward,
            onBack: () => _goBack(ref, serial),
            onForward: () => _goForward(ref, serial),
            onUp: () => _goUp(ref, serial),
            onRefresh: () => _refresh(ref, serial),
            onHome: () => _goHome(ref, serial),
            onNewFolder: () => _showNewFolderDialog(context, ref, serial),
            isDevicePanel: isDevicePanel,
            searchQuery: searchQuery,
            onSearchChanged: (q) => _setSearch(ref, serial, q),
            sortField: sortField,
            sortAscending: sortAscending,
            onSortChanged: (f) => _setSort(ref, serial, f),
            searchFocusTrigger: searchFocusTrigger,
          ),
          if (errorMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Theme.of(context).colorScheme.errorContainer,
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontSize: 12,
                ),
              ),
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayFiles.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                                searchQuery.isNotEmpty
                                    ? Icons.search_off
                                    : Icons.folder_open,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.3)),
                            const SizedBox(height: 8),
                            Text(
                                searchQuery.isNotEmpty
                                    ? 'No files match "$searchQuery"'
                                    : 'Empty folder',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.5))),
                          ],
                        ),
                      )
                    : _buildDragTarget(context, ref, serial, displayFiles,
                        selectedFiles, currentPath),
          ),
          // Selection action bar
          if (selectedFiles.isNotEmpty)
            SelectionActionBar(
              selectedCount: selectedFiles.length,
              selectedBytes: selectedTotalBytes,
              isDevicePanel: isDevicePanel,
              onClearSelection: () {
                if (isDevicePanel && serial != null) {
                  ref
                      .read(deviceFileProvider(serial).notifier)
                      .clearSelection();
                } else {
                  ref.read(localFileProvider.notifier).clearSelection();
                }
              },
              onSelectAll: () {
                if (isDevicePanel && serial != null) {
                  ref.read(deviceFileProvider(serial).notifier).selectAll();
                } else {
                  ref.read(localFileProvider.notifier).selectAll();
                }
              },
              onDelete: isDevicePanel && serial != null
                  ? () => _confirmDeleteSelected(context, ref, serial)
                  : null,
              onDownload: isDevicePanel && serial != null
                  ? () => _downloadSelected(ref, serial, displayFiles,
                      selectedFiles)
                  : null,
              onUpload: !isDevicePanel && serial != null
                  ? () => _uploadSelected(ref, serial, displayFiles,
                      selectedFiles)
                  : null,
            ),
        ],
      ),
    );
  }

  Widget _buildDragTarget(BuildContext context, WidgetRef ref, String? serial,
      List<FileItem> files, Set<String> selectedFiles, String currentPath) {
    return DragTarget<List<FileItem>>(
      onAcceptWithDetails: (details) {
        final droppedItems = details.data;
        if (serial == null) return;

        for (final item in droppedItems) {
          if (isDevicePanel) {
            ref.read(transferProvider.notifier).enqueueUpload(
                  serial,
                  item.absolutePath,
                  '$currentPath/${item.name}',
                  item.name,
                );
          } else {
            final localPath = '$currentPath/${item.name}';
            ref.read(transferProvider.notifier).enqueueDownload(
                  serial,
                  item.absolutePath,
                  localPath,
                  item.name,
                );
          }
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHovering = candidateData.isNotEmpty;
        return Container(
          decoration: isHovering
              ? BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withOpacity(0.05),
                )
              : null,
          child: ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              final isSelected = selectedFiles.contains(file.absolutePath);
              return Draggable<List<FileItem>>(
                data: selectedFiles.isNotEmpty
                    ? files
                        .where(
                            (f) => selectedFiles.contains(f.absolutePath))
                        .toList()
                    : [file],
                feedback: Material(
                  elevation: 4,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          file.isDirectory
                              ? Icons.folder
                              : Icons.insert_drive_file,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selectedFiles.length > 1
                              ? '${selectedFiles.length} items'
                              : file.name,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ),
                child: GestureDetector(
                  onSecondaryTapUp: (details) {
                    _showContextMenu(
                      context,
                      ref,
                      serial,
                      file,
                      details.globalPosition,
                    );
                  },
                  child: FileItemTile(
                    file: file,
                    isSelected: isSelected,
                    onTap: () => _toggleSelect(ref, serial, file),
                    onDoubleTap: () {
                      if (file.isDirectory) {
                        _navigateTo(ref, serial, file.absolutePath);
                      } else {
                        _showPreview(context, ref, serial, file);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showContextMenu(BuildContext context, WidgetRef ref, String? serial,
      FileItem file, Offset position) {
    showFileContextMenu(
      context: context,
      ref: ref,
      position: position,
      file: file,
      isDevicePanel: isDevicePanel,
      serial: serial,
      currentPath: isDevicePanel
          ? ref.read(deviceFileProvider(serial!)).currentPath
          : ref.read(localFileProvider).currentPath,
    );
  }

  void _showPreview(
      BuildContext context, WidgetRef ref, String? serial, FileItem file) {
    showDialog(
      context: context,
      builder: (context) => PreviewDialog(
        file: file,
        serial: isDevicePanel ? serial : null,
        localFilePath: !isDevicePanel ? file.absolutePath : null,
      ),
    );
  }

  void _navigateTo(WidgetRef ref, String? serial, String path) {
    if (isDevicePanel && serial != null) {
      ref.read(deviceFileProvider(serial).notifier).navigateTo(path);
    } else if (!isDevicePanel) {
      ref.read(localFileProvider.notifier).navigateTo(path);
    }
  }

  void _goBack(WidgetRef ref, String? serial) {
    if (isDevicePanel && serial != null) {
      ref.read(deviceFileProvider(serial).notifier).goBack();
    } else if (!isDevicePanel) {
      ref.read(localFileProvider.notifier).goBack();
    }
  }

  void _goForward(WidgetRef ref, String? serial) {
    if (isDevicePanel && serial != null) {
      ref.read(deviceFileProvider(serial).notifier).goForward();
    } else if (!isDevicePanel) {
      ref.read(localFileProvider.notifier).goForward();
    }
  }

  void _goUp(WidgetRef ref, String? serial) {
    if (isDevicePanel && serial != null) {
      ref.read(deviceFileProvider(serial).notifier).goUp();
    } else if (!isDevicePanel) {
      ref.read(localFileProvider.notifier).goUp();
    }
  }

  void _refresh(WidgetRef ref, String? serial) {
    if (isDevicePanel && serial != null) {
      ref.read(deviceFileProvider(serial).notifier).refresh();
    } else if (!isDevicePanel) {
      ref.read(localFileProvider.notifier).refresh();
    }
  }

  void _goHome(WidgetRef ref, String? serial) {
    if (isDevicePanel && serial != null) {
      ref.read(deviceFileProvider(serial).notifier).navigateTo('/sdcard');
    } else if (!isDevicePanel) {
      ref
          .read(localFileProvider.notifier)
          .navigateTo(ref.read(localFileProvider).currentPath);
    }
  }

  void _toggleSelect(WidgetRef ref, String? serial, FileItem file) {
    if (isDevicePanel && serial != null) {
      ref
          .read(deviceFileProvider(serial).notifier)
          .toggleSelect(file.absolutePath);
    } else if (!isDevicePanel) {
      ref.read(localFileProvider.notifier).toggleSelect(file.absolutePath);
    }
  }

  void _setSearch(WidgetRef ref, String? serial, String query) {
    if (isDevicePanel && serial != null) {
      ref.read(deviceFileProvider(serial).notifier).setSearchQuery(query);
    } else if (!isDevicePanel) {
      ref.read(localFileProvider.notifier).setSearchQuery(query);
    }
  }

  void _setSort(WidgetRef ref, String? serial, SortField field) {
    if (isDevicePanel && serial != null) {
      ref.read(deviceFileProvider(serial).notifier).setSort(field);
    } else if (!isDevicePanel) {
      ref.read(localFileProvider.notifier).setSort(field);
    }
  }

  void _confirmDeleteSelected(
      BuildContext context, WidgetRef ref, String serial) {
    final count = isDevicePanel
        ? ref.read(deviceFileProvider(serial)).selectedFiles.length
        : 0;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text(
            'Are you sure you want to delete $count selected item(s)?\n'
            'This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
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
  }

  void _downloadSelected(WidgetRef ref, String serial,
      List<FileItem> files, Set<String> selectedFiles) async {
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null) return;
    for (final file in files) {
      if (selectedFiles.contains(file.absolutePath) && !file.isDirectory) {
        ref.read(transferProvider.notifier).enqueueDownload(
              serial,
              file.absolutePath,
              '$dir/${file.name}',
              file.name,
            );
      }
    }
  }

  void _uploadSelected(WidgetRef ref, String serial,
      List<FileItem> files, Set<String> selectedFiles) {
    final deviceState = ref.read(deviceProvider);
    final activeSerial = deviceState.activeSerial;
    if (activeSerial == null) return;
    final devicePath = ref
        .read(deviceFileProvider(activeSerial))
        .currentPath;
    for (final file in files) {
      if (selectedFiles.contains(file.absolutePath) && !file.isDirectory) {
        ref.read(transferProvider.notifier).enqueueUpload(
              activeSerial,
              file.absolutePath,
              '$devicePath/${file.name}',
              file.name,
            );
      }
    }
  }

  void _showNewFolderDialog(
      BuildContext context, WidgetRef ref, String? serial) {
    if (!isDevicePanel) return;

    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Folder'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Folder name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
          onSubmitted: (_) {
            if (controller.text.trim().isNotEmpty && serial != null) {
              ref
                  .read(deviceFileProvider(serial).notifier)
                  .createDirectory(controller.text.trim());
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
              if (controller.text.trim().isNotEmpty && serial != null) {
                ref
                    .read(deviceFileProvider(serial).notifier)
                    .createDirectory(controller.text.trim());
                Navigator.of(context).pop();
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}
