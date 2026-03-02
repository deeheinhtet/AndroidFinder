import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SetupGuideDialog extends StatelessWidget {
  const SetupGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.help_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Setup Guide'),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _SectionHeader(
                icon: Icons.download,
                title: 'Install ADB',
                theme: theme,
              ),
              const SizedBox(height: 8),
              _buildInstallInstructions(context, theme),
              const SizedBox(height: 24),
              _SectionHeader(
                icon: Icons.phone_android,
                title: 'Enable USB Debugging on Phone',
                theme: theme,
              ),
              const SizedBox(height: 8),
              _buildUsbDebuggingSteps(theme),
              const SizedBox(height: 24),
              _SectionHeader(
                icon: Icons.lightbulb_outline,
                title: 'Quick Tips',
                theme: theme,
              ),
              const SizedBox(height: 8),
              _buildQuickTips(theme),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Got it'),
        ),
      ],
    );
  }

  Widget _buildInstallInstructions(BuildContext context, ThemeData theme) {
    if (Platform.isMacOS) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('macOS — Install via Homebrew:',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          _CommandBlock(
            command: 'brew install android-platform-tools',
            theme: theme,
          ),
          const SizedBox(height: 12),
          Text(
            'Or install Android Studio (includes ADB automatically).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      );
    } else if (Platform.isLinux) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Linux (Ubuntu/Debian):',
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          _CommandBlock(
            command: 'sudo apt install android-tools-adb',
            theme: theme,
          ),
          const SizedBox(height: 12),
          Text(
            'Or install Android Studio (includes ADB automatically).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      );
    } else if (Platform.isWindows) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Windows:', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            '1. Download "SDK Platform-Tools for Windows" from the Android developer website',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            '2. Extract to a folder (e.g. C:\\platform-tools)',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            '3. Add that folder to your system PATH environment variable',
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          Text(
            'Or install Android Studio (includes ADB automatically).',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      );
    }
    return Text('Install ADB via your package manager or Android Studio.',
        style: theme.textTheme.bodySmall);
  }

  Widget _buildUsbDebuggingSteps(ThemeData theme) {
    const steps = [
      'Go to Settings > About Phone',
      'Tap "Build Number" 7 times to enable Developer Options',
      'Go to Settings > Developer Options',
      'Enable "USB Debugging"',
      '(Optional) Enable "Wireless Debugging" for Wi-Fi connections',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...steps.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text(
                    '${entry.key + 1}.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(entry.value, style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.info_outline,
                size: 14,
                color: theme.colorScheme.primary),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'When you connect via USB, tap "Allow" on the phone prompt.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickTips(ThemeData theme) {
    const tips = [
      'After installing ADB, restart this app.',
      'Use "Scan Devices" for USB, "Pair Device" for first-time Wi-Fi.',
      'Wi-Fi: both phone and computer must be on the same network.',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: tips.map((tip) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('• ', style: theme.textTheme.bodySmall),
              Expanded(
                child: Text(tip, style: theme.textTheme.bodySmall),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final ThemeData theme;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: theme.colorScheme.primary),
        const SizedBox(width: 6),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _CommandBlock extends StatelessWidget {
  final String command;
  final ThemeData theme;

  const _CommandBlock({
    required this.command,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Expanded(
            child: SelectableText(
              command,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontFamilyFallback: const ['Courier New', 'Courier'],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.copy, size: 16),
            tooltip: 'Copy to clipboard',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: command));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
