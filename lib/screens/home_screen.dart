import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/device_file_provider.dart';
import '../providers/device_provider.dart';
import '../providers/local_file_provider.dart';
import '../widgets/device_panel/device_status_bar.dart';
import '../widgets/device_panel/quick_access_sidebar.dart';
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
          const SingleActivator(LogicalKeyboardKey.delete): () =>
              _deleteSelected(context),
          const SingleActivator(LogicalKeyboardKey.escape): () =>
              _clearAll(),
          const SingleActivator(LogicalKeyboardKey.enter): () =>
              _openSelectedFolder(),
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

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete'),
        content: Text(
          'Are you sure you want to delete ${selected.length} selected item(s)?\n'
          'This action cannot be undone.',
        ),
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
