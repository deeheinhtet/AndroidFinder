import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/connection_type.dart';
import '../../providers/adb_provider.dart';
import '../../providers/device_provider.dart';
import '../../providers/storage_provider.dart';
import '../../providers/theme_provider.dart';

class DeviceStatusBar extends ConsumerWidget {
  const DeviceStatusBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deviceState = ref.watch(deviceProvider);
    final theme = Theme.of(context);

    if (!deviceState.hasConnectedDevices) return const SizedBox.shrink();

    final activeSerial = deviceState.activeSerial;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Row(
        children: [
          // Device tabs (scrollable)
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: deviceState.connectedDevices.entries.map((entry) {
                  final serial = entry.key;
                  final device = entry.value;
                  final isActive = serial == activeSerial;
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _DeviceTab(
                      label: device.model ?? serial,
                      connectionType: device.connectionType,
                      isActive: isActive,
                      onTap: () => ref
                          .read(deviceProvider.notifier)
                          .setActiveDevice(serial),
                      onClose: () => ref
                          .read(deviceProvider.notifier)
                          .disconnectDevice(serial),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // Separator
          Container(
            width: 1,
            height: 20,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: theme.colorScheme.outline.withOpacity(0.2),
          ),
          // Active device info & actions
          if (activeSerial != null) ...[
            _StorageBadge(serial: activeSerial),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () =>
                  _captureScreenshot(context, ref, activeSerial),
              icon: const Icon(Icons.screenshot, size: 16),
              tooltip: 'Capture Screenshot',
              iconSize: 16,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: const EdgeInsets.all(4),
            ),
            const SizedBox(width: 4),
          ],
          IconButton(
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              size: 16,
            ),
            tooltip: 'Toggle Theme',
            iconSize: 16,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            padding: const EdgeInsets.all(4),
          ),
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: () => ref.read(deviceProvider.notifier).disconnect(),
            icon: const Icon(Icons.link_off, size: 14),
            label: const Text('Disconnect'),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _captureScreenshot(
      BuildContext context, WidgetRef ref, String serial) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Capturing screenshot...'),
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          width: 250,
        ),
      );
      final adb = ref.read(adbServiceProvider);
      final bytes = await adb.captureScreenshot(serial);
      if (!context.mounted) return;

      final savePath = await FilePicker.platform.saveFile(
        dialogTitle: 'Save Screenshot',
        fileName: 'screenshot_${DateTime.now().millisecondsSinceEpoch}.png',
        type: FileType.image,
      );
      if (savePath == null) return;

      await File(savePath).writeAsBytes(bytes);
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Screenshot saved to $savePath'),
          behavior: SnackBarBehavior.floating,
          width: 350,
          duration: const Duration(seconds: 3),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Screenshot failed: $e'),
          behavior: SnackBarBehavior.floating,
          width: 350,
        ),
      );
    }
  }
}

class _DeviceTab extends StatelessWidget {
  final String label;
  final ConnectionType connectionType;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _DeviceTab({
    required this.label,
    required this.connectionType,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: isActive
          ? theme.colorScheme.primaryContainer
          : Colors.transparent,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 30,
          padding: const EdgeInsets.only(left: 8, right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                connectionType == ConnectionType.wifi
                    ? Icons.wifi
                    : Icons.usb,
                size: 14,
                color: isActive
                    ? theme.colorScheme.onPrimaryContainer
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 20,
                height: 20,
                child: IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, size: 12),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Disconnect',
                  color: isActive
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StorageBadge extends ConsumerWidget {
  final String serial;

  const _StorageBadge({required this.serial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final storageAsync = ref.watch(storageProvider(serial));
    final theme = Theme.of(context);

    return storageAsync.when(
      data: (storage) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storage, size: 14,
              color: theme.colorScheme.onSurface.withOpacity(0.5)),
          const SizedBox(width: 4),
          Text(
            '${storage.formattedUsed} / ${storage.formattedTotal}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 60,
            height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: storage.usagePercent,
                backgroundColor:
                    theme.colorScheme.onSurface.withOpacity(0.1),
                valueColor: AlwaysStoppedAnimation(
                  storage.usagePercent > 0.9
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
              ),
            ),
          ),
        ],
      ),
      loading: () => const SizedBox(
        width: 12,
        height: 12,
        child: CircularProgressIndicator(strokeWidth: 1.5),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
