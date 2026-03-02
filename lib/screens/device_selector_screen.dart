import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/connection_type.dart';
import '../providers/device_provider.dart';
import '../providers/theme_provider.dart';
import '../widgets/device_panel/setup_guide_dialog.dart';
import '../widgets/device_panel/wifi_connect_dialog.dart';
import '../widgets/device_panel/wifi_pair_dialog.dart';

class DeviceSelectorScreen extends ConsumerStatefulWidget {
  const DeviceSelectorScreen({super.key});

  @override
  ConsumerState<DeviceSelectorScreen> createState() =>
      _DeviceSelectorScreenState();
}

class _DeviceSelectorScreenState extends ConsumerState<DeviceSelectorScreen> {
  bool _hasShownAdbGuide = false;

  @override
  Widget build(BuildContext context) {
    final deviceState = ref.watch(deviceProvider);
    final theme = Theme.of(context);

    // Auto-show setup guide when ADB is not found
    if (!_hasShownAdbGuide &&
        deviceState.errorMessage != null &&
        _isAdbNotFoundError(deviceState.errorMessage!)) {
      _hasShownAdbGuide = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSetupGuide(context);
      });
    }

    return Stack(
      children: [
        Positioned(
          top: 8,
          right: 8,
          child: IconButton(
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
            icon: Icon(
              ref.watch(themeModeProvider) == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            tooltip: 'Toggle Theme',
          ),
        ),
        Center(
          child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            Icon(
              Icons.phone_android,
              size: 80,
              color: theme.colorScheme.primary.withOpacity(0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'AndroidFinder',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect to an Android device to browse files',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: deviceState.isScanning
                      ? null
                      : () => ref.read(deviceProvider.notifier).scan(),
                  icon: deviceState.isScanning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  label: Text(
                      deviceState.isScanning ? 'Scanning...' : 'Scan Devices'),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: deviceState.isConnecting
                      ? null
                      : () => _showPairDialog(context),
                  icon: const Icon(Icons.phonelink_lock),
                  label: const Text('Pair Device'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: deviceState.isConnecting
                      ? null
                      : () => _showWifiDialog(context),
                  icon: const Icon(Icons.wifi),
                  label: const Text('Wi-Fi Connect'),
                ),
                const SizedBox(width: 12),
                FilledButton.tonalIcon(
                  onPressed: deviceState.isConnecting
                      ? null
                      : () => ref.read(deviceProvider.notifier).autoConnectWifi(),
                  icon: const Icon(Icons.wifi_find),
                  label: const Text('Auto Connect'),
                ),
              ],
            ),
            if (deviceState.errorMessage != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        deviceState.errorMessage!,
                        style: TextStyle(
                            color: theme.colorScheme.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (deviceState.discoveredDevices.isNotEmpty) ...[
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Discovered Devices',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ),
              ),
              ...deviceState.discoveredDevices
                  .where((d) => !deviceState.connectedDevices.containsKey(d.serialNumber))
                  .map((device) {
                final isAvailable = device.status == 'device';
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      device.connectionType == ConnectionType.wifi
                          ? Icons.wifi
                          : Icons.usb,
                      color: isAvailable
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withOpacity(0.4),
                    ),
                    title: Text(device.model ?? device.serialNumber),
                    subtitle: Text(
                      '${device.serialNumber} - ${device.status}',
                      style: TextStyle(
                        color: isAvailable
                            ? theme.colorScheme.onSurface.withOpacity(0.6)
                            : theme.colorScheme.error,
                      ),
                    ),
                    trailing: isAvailable
                        ? deviceState.isConnecting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2),
                              )
                            : const Icon(Icons.arrow_forward_ios, size: 16)
                        : null,
                    onTap: isAvailable && !deviceState.isConnecting
                        ? () =>
                            ref.read(deviceProvider.notifier).selectDevice(device)
                        : null,
                  ),
                );
              }),
            ],
            if (deviceState.isConnecting) ...[
              const SizedBox(height: 24),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('Connecting...'),
                ],
              ),
            ],
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => _showSetupGuide(context),
              icon: const Icon(Icons.help_outline, size: 18),
              label: const Text('Setup Guide'),
            ),
            ],
          ),
        ),
      ),
    ),
      ],
    );
  }

  bool _isAdbNotFoundError(String error) {
    final lower = error.toLowerCase();
    return lower.contains('adb not found') ||
        lower.contains('adb') && lower.contains('not found') ||
        lower.contains('adbnotfoundexception');
  }

  void _showSetupGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const SetupGuideDialog(),
    );
  }

  void _showPairDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const WifiPairDialog(),
    );
  }

  void _showWifiDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const WifiConnectDialog(),
    );
  }
}
