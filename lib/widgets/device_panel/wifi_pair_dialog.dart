import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/device_provider.dart';

class WifiPairDialog extends ConsumerStatefulWidget {
  const WifiPairDialog({super.key});

  @override
  ConsumerState<WifiPairDialog> createState() => _WifiPairDialogState();
}

class _WifiPairDialogState extends ConsumerState<WifiPairDialog> {
  final _ipController = TextEditingController();
  final _portController = TextEditingController();
  final _codeController = TextEditingController();
  bool _isPairing = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _ipController.dispose();
    _portController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _pair() async {
    final ip = _ipController.text.trim();
    final port = int.tryParse(_portController.text.trim());
    final code = _codeController.text.trim();

    if (ip.isEmpty) {
      setState(() => _error = 'Please enter the pairing IP address');
      return;
    }
    final ipRegex = RegExp(r'^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}$');
    if (!ipRegex.hasMatch(ip)) {
      setState(() => _error = 'Invalid IP address format');
      return;
    }
    if (port == null || port <= 0) {
      setState(() => _error = 'Please enter a valid pairing port');
      return;
    }
    if (code.isEmpty) {
      setState(() => _error = 'Please enter the 6-digit pairing code');
      return;
    }

    setState(() {
      _isPairing = true;
      _error = null;
      _success = null;
    });

    try {
      final result =
          await ref.read(deviceProvider.notifier).pairDevice(ip, port, code);
      if (mounted) {
        setState(() {
          _isPairing = false;
          _success = 'Paired successfully!\n$result\nYou can now close this and use "Wi-Fi Connect" with the connection port.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPairing = false;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.phonelink_lock, size: 24),
          SizedBox(width: 8),
          Text('Pair Device'),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How to pair:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '1. On your phone, go to Settings > Developer Options > Wireless Debugging\n'
                    '2. Tap "Pair device with pairing code"\n'
                    '3. Enter the pairing IP, port, and 6-digit code shown on your phone',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Pairing IP Address',
                hintText: '192.168.1.100',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.wifi),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              enabled: !_isPairing,
              autofocus: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Pairing Port',
                hintText: '41023',
                helperText: 'This is NOT 5555 — use the port shown on your phone',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              enabled: !_isPairing,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: '6-digit Pairing Code',
                hintText: '123456',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.pin),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              enabled: !_isPairing,
              onSubmitted: (_) => _pair(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 18, color: theme.colorScheme.onErrorContainer),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: theme.colorScheme.onErrorContainer,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (_success != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _success!,
                        style: const TextStyle(
                          color: Colors.green,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(_success != null ? 'Done' : 'Cancel'),
        ),
        if (_success == null)
          FilledButton(
            onPressed: _isPairing ? null : _pair,
            child: _isPairing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Pair'),
          ),
      ],
    );
  }
}
