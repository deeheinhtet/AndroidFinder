import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/device_provider.dart';

class WifiConnectDialog extends ConsumerStatefulWidget {
  const WifiConnectDialog({super.key});

  @override
  ConsumerState<WifiConnectDialog> createState() => _WifiConnectDialogState();
}

class _WifiConnectDialogState extends ConsumerState<WifiConnectDialog> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController(text: '5555');
  bool _isConnecting = false;
  String? _error;

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim()) ?? 5555;

    if (ip.isEmpty) {
      setState(() => _error = 'Please enter an IP address');
      return;
    }

    final ipRegex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    if (!ipRegex.hasMatch(ip)) {
      setState(() => _error = 'Invalid IP address format');
      return;
    }

    setState(() {
      _isConnecting = true;
      _error = null;
    });

    try {
      await ref.read(deviceProvider.notifier).connectWifi(ip, port);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isConnecting = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Connect via Wi-Fi'),
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Make sure USB debugging over Wi-Fi is enabled on your device, '
              'or pair using "adb pair" first.',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.1.100',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wifi),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              enabled: !_isConnecting,
              autofocus: true,
              onSubmitted: (_) => _connect(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                hintText: '5555',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              enabled: !_isConnecting,
              onSubmitted: (_) => _connect(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isConnecting ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isConnecting ? null : _connect,
          child: _isConnecting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Connect'),
        ),
      ],
    );
  }
}
