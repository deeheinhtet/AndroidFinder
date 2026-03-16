import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/clipboard_provider.dart';
import '../providers/device_file_provider.dart';
import '../providers/device_provider.dart';
import '../providers/local_file_provider.dart';
import '../providers/transfer_provider.dart';
import '../widgets/device_panel/device_status_bar.dart';
import '../widgets/device_panel/quick_access_sidebar.dart';
import '../widgets/file_browser/conflict_resolution_dialog.dart';
import '../widgets/file_browser/device_search_dialog.dart';
import '../widgets/file_browser/file_browser_panel.dart';
import '../widgets/transfer/transfer_panel.dart';
import 'device_selector_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  double _dividerPosition = 0.5;
  final _deviceSearchFocus = ValueNotifier<bool>(false);
  final _localSearchFocus = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(localFileProvider.notifier).refresh();
      // Set up conflict resolver
      ref.read(transferProvider.notifier).setConflictResolver(
        (fileName, sourceBytes, destBytes) async {
          if (!mounted) return ConflictResolution.skip;
          final result = await showDialog<ConflictResolution>(
            context: context,
            builder: (_) => ConflictResolutionDialog(
              fileName: fileName,
              sourceBytes: sourceBytes,
              destBytes: destBytes,
            ),
          );
          return result ?? ConflictResolution.skip;
        },
      );
    });
  }

  @override
  void dispose() {
    _deviceSearchFocus.dispose();
    _localSearchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceProvider);
    final isConnected = deviceState.hasConnectedDevices;

    ref.listen(deviceProvider, (prev, next) {
      if (prev == null) return;
      final prevKeys = prev.connectedDevices.keys.toSet();
      final nextKeys = next.connectedDevices.keys.toSet();
      final newSerials = nextKeys.difference(prevKeys);
      for (final serial in newSerials) {
        ref
            .read(deviceFileProvider(serial).notifier)
            .navigateTo('/sdcard');
      }
    });

    return Scaffold(
      body: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.f5): () => _refreshAll(),
          const SingleActivator(LogicalKeyboardKey.keyA, control: true): () =>
              _selectAll(),
          const SingleActivator(LogicalKeyboardKey.keyF, control: true): () =>
              _focusSearch(),
          const SingleActivator(LogicalKeyboardKey.keyF,
              control: true, shift: true): () => _deviceSearch(context),
          const SingleActivator(LogicalKeyboardKey.delete): () =>
              _deleteSelected(context),
          const SingleActivator(LogicalKeyboardKey.escape): () => _clearAll(),
          const SingleActivator(LogicalKeyboardKey.enter): () =>
              _openSelectedFolder(),
          const SingleActivator(LogicalKeyboardKey.keyC, control: true): () =>
              _copySelected(),
          const SingleActivator(LogicalKeyboardKey.keyV, control: true): () =>
              _pasteClipboard(),
          const SingleActivator(LogicalKeyboardKey.keyD, control: true): () =>
              _downloadSelectedFiles(context),
          const SingleActivator(LogicalKeyboardKey.keyU, control: true): () =>
              _uploadSelectedFiles(),
        },
        child: Focus(
          autofocus: true,
          child: Column(
            children: [
              if (isConnected) const DeviceStatusBar(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final availableWidth = constraints.maxWidth - 6;
                    const minPanelWidth = 300.0;
                    final minRatio = minPanelWidth / availableWidth;
                    final maxRatio = 1.0 - minRatio;
                    final clampedPosition =
                        _dividerPosition.clamp(minRatio, maxRatio);
                    final leftWidth = availableWidth * clampedPosition;
                    final rightWidth = availableWidth - leftWidth;
                    return Row(
                      children: [
                        SizedBox(
                          width: leftWidth,
                          height: constraints.maxHeight,
                          child: isConnected
                              ? Row(
                                  children: [
                                    QuickAccessSidebar(
                                      serial: deviceState.activeSerial!,
                                    ),
                                    Expanded(
                                      child: FileBrowserPanel(
                                        isDevicePanel: true,
                                        searchFocusTrigger: _deviceSearchFocus,
                                      ),
                                    ),
                                  ],
                                )
                              : const DeviceSelectorScreen(),
                        ),
                        GestureDetector(
                          onHorizontalDragUpdate: (details) {
                            setState(() {
                              _dividerPosition +=
                                  details.primaryDelta! / availableWidth;
                              _dividerPosition =
                                  _dividerPosition.clamp(minRatio, maxRatio);
                            });
                          },
                          child: MouseRegion(
                            cursor: SystemMouseCursors.resizeColumn,
                            child: Container(
                              width: 6,
                              height: constraints.maxHeight,
                              color: Theme.of(context)
                                  .colorScheme
                                  .outline
                                  .withOpacity(0.1),
                              child: Center(
                                child: Container(
                                  width: 2,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .outline
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: rightWidth,
                          height: constraints.maxHeight,
                          child: FileBrowserPanel(
                            isDevicePanel: false,
                            searchFocusTrigger: _localSearchFocus,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const TransferPanel(),
            ],
          ),
        ),
      ),
    );
  }

  void _refreshAll() {
    final deviceState = ref.read(deviceProvider);
    final serial = deviceState.activeSerial;
    if (serial != null) {
      ref.read(deviceFileProvider(serial).notifier).refresh();
    }
    ref.read(localFileProvider.notifier).refresh();
  }

  void _selectAll() {
    final deviceState = ref.read(deviceProvider);
    final serial = deviceState.activeSerial;
    if (serial != null) {
      ref.read(deviceFileProvider(serial).notifier).selectAll();
    }
  }

  void _focusSearch() {
    _deviceSearchFocus.value = !_deviceSearchFocus.value;
    _localSearchFocus.value = !_localSearchFocus.value;
  }

  void _deleteSelected(BuildContext context) {
    final deviceState = ref.read(deviceProvider);
    final serial = deviceState.activeSerial;
    if (serial == null) return;
    final selected = ref.read(deviceFileProvider(serial)).selectedFiles;
    if (selected.isEmpty) return;
    _scheduleDelete(context, serial, selected.length);
  }

  void _scheduleDelete(BuildContext context, String serial, int count) {
    ref.read(deviceFileProvider(serial).notifier).scheduleDeletion();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleting $count item(s) in 5 seconds...'),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        width: 350,
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            ref.read(deviceFileProvider(serial).notifier).cancelDeletion();
          },
        ),
      ),
    );
  }

  void _copySelected() {
    final deviceState = ref.read(deviceProvider);
    final serial = deviceState.activeSerial;
    if (serial != null) {
      final devState = ref.read(deviceFileProvider(serial));
      if (devState.selectedFiles.isNotEmpty) {
        final items = devState.files
            .where((f) => devState.selectedFiles.contains(f.absolutePath))
            .toList();
        ref
            .read(clipboardProvider.notifier)
            .copy(items, true, serial, devState.currentPath);
        return;
      }
    }
    final locState = ref.read(localFileProvider);
    if (locState.selectedFiles.isNotEmpty) {
      final items = locState.files
          .where((f) => locState.selectedFiles.contains(f.absolutePath))
          .toList();
      ref
          .read(clipboardProvider.notifier)
          .copy(items, false, null, locState.currentPath);
    }
  }

  void _pasteClipboard() {
    final clipboard = ref.read(clipboardProvider);
    if (!clipboard.hasItems) return;
    final deviceState = ref.read(deviceProvider);
    final serial = deviceState.activeSerial;
    if (clipboard.isFromDevice && serial != null) {
      // pasting device files → local panel
      final localPath = ref.read(localFileProvider).currentPath;
      for (final item in clipboard.items) {
        if (!item.isDirectory) {
          ref.read(transferProvider.notifier).enqueueDownload(
                serial,
                item.absolutePath,
                '$localPath/${item.name}',
                item.name,
              );
        }
      }
    } else if (!clipboard.isFromDevice && serial != null) {
      // pasting local files → device panel
      final devicePath = ref.read(deviceFileProvider(serial)).currentPath;
      for (final item in clipboard.items) {
        if (!item.isDirectory) {
          ref.read(transferProvider.notifier).enqueueUpload(
                serial,
                item.absolutePath,
                '$devicePath/${item.name}',
                item.name,
              );
        }
      }
    }
  }

  Future<void> _downloadSelectedFiles(BuildContext context) async {
    final deviceState = ref.read(deviceProvider);
    final serial = deviceState.activeSerial;
    if (serial == null) return;
    final devState = ref.read(deviceFileProvider(serial));
    if (devState.selectedFiles.isEmpty) return;
    final dir = await FilePicker.platform.getDirectoryPath();
    if (dir == null) return;
    for (final file in devState.files) {
      if (devState.selectedFiles.contains(file.absolutePath) &&
          !file.isDirectory) {
        ref.read(transferProvider.notifier).enqueueDownload(
              serial,
              file.absolutePath,
              '$dir/${file.name}',
              file.name,
            );
      }
    }
  }

  void _uploadSelectedFiles() {
    final deviceState = ref.read(deviceProvider);
    final serial = deviceState.activeSerial;
    if (serial == null) return;
    final locState = ref.read(localFileProvider);
    if (locState.selectedFiles.isEmpty) return;
    final devicePath = ref.read(deviceFileProvider(serial)).currentPath;
    for (final file in locState.files) {
      if (locState.selectedFiles.contains(file.absolutePath) &&
          !file.isDirectory) {
        ref.read(transferProvider.notifier).enqueueUpload(
              serial,
              file.absolutePath,
              '$devicePath/${file.name}',
              file.name,
            );
      }
    }
  }

  void _deviceSearch(BuildContext context) {
    final serial = ref.read(deviceProvider).activeSerial;
    if (serial == null) return;
    showDialog(
      context: context,
      builder: (_) => DeviceSearchDialog(serial: serial),
    );
  }

  void _clearAll() {
    final deviceState = ref.read(deviceProvider);
    final serial = deviceState.activeSerial;
    if (serial != null) {
      ref.read(deviceFileProvider(serial).notifier).clearSelection();
      ref.read(deviceFileProvider(serial).notifier).setSearchQuery('');
    }
    ref.read(localFileProvider.notifier).clearSelection();
    ref.read(localFileProvider.notifier).setSearchQuery('');
  }

  void _openSelectedFolder() {
    final deviceState = ref.read(deviceProvider);
    final serial = deviceState.activeSerial;
    if (serial == null) return;
    final devState = ref.read(deviceFileProvider(serial));
    if (devState.selectedFiles.length == 1) {
      final selectedPath = devState.selectedFiles.first;
      final file = devState.files.where((f) => f.absolutePath == selectedPath).firstOrNull;
      if (file != null && file.isDirectory) {
        ref.read(deviceFileProvider(serial).notifier).navigateTo(file.absolutePath);
      }
    }
  }
}
