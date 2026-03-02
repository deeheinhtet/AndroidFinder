import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/transfer_task.dart';
import '../../providers/transfer_provider.dart';

class TransferPanel extends ConsumerStatefulWidget {
  const TransferPanel({super.key});

  @override
  ConsumerState<TransferPanel> createState() => _TransferPanelState();
}

class _TransferPanelState extends ConsumerState<TransferPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final transferState = ref.watch(transferProvider);
    final theme = Theme.of(context);

    if (transferState.tasks.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withOpacity(0.2)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    _isExpanded
                        ? Icons.expand_more
                        : Icons.expand_less,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Transfers',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(width: 8),
                  if (transferState.activeCount > 0)
                    _Badge(
                      label: '${transferState.activeCount} active',
                      color: theme.colorScheme.primary,
                    ),
                  if (transferState.queuedCount > 0) ...[
                    const SizedBox(width: 4),
                    _Badge(
                      label: '${transferState.queuedCount} queued',
                      color: theme.colorScheme.secondary,
                    ),
                  ],
                  if (transferState.completedCount > 0) ...[
                    const SizedBox(width: 4),
                    _Badge(
                      label: '${transferState.completedCount} done',
                      color: Colors.green,
                    ),
                  ],
                  if (transferState.failedCount > 0) ...[
                    const SizedBox(width: 4),
                    _Badge(
                      label: '${transferState.failedCount} failed',
                      color: theme.colorScheme.error,
                    ),
                  ],
                  const Spacer(),
                  if (transferState.completedCount > 0 ||
                      transferState.failedCount > 0)
                    TextButton(
                      onPressed: () =>
                          ref.read(transferProvider.notifier).clearCompleted(),
                      child: const Text('Clear'),
                    ),
                ],
              ),
            ),
          ),
          if (_isExpanded)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: transferState.tasks.length,
                itemBuilder: (context, index) {
                  final task = transferState.tasks[index];
                  return _TransferItemTile(task: task);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _TransferItemTile extends ConsumerWidget {
  final TransferTask task;

  const _TransferItemTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isActive = task.status == TransferStatus.inProgress;
    final hasProgress = isActive && task.totalBytes > 0;
    final progress =
        hasProgress ? task.transferredBytes / task.totalBytes : null;
    final percent = hasProgress ? (progress! * 100) : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(
            task.direction == TransferDirection.deviceToLocal
                ? Icons.download
                : Icons.upload,
            size: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.fileName,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isActive && hasProgress) ...[
                  const SizedBox(height: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _buildProgressText(task, percent!),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                      fontSize: 10,
                    ),
                  ),
                ] else if (isActive)
                  const LinearProgressIndicator()
                else if (task.status == TransferStatus.queued)
                  Text('Queued',
                      style: theme.textTheme.labelSmall?.copyWith(
                          color:
                              theme.colorScheme.onSurface.withOpacity(0.5)))
                else if (task.status == TransferStatus.completed)
                  Text('Completed',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: Colors.green))
                else if (task.status == TransferStatus.failed)
                  Text(task.errorMessage ?? 'Failed',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: theme.colorScheme.error)),
              ],
            ),
          ),
          if (task.status == TransferStatus.queued)
            IconButton(
              icon: const Icon(Icons.close, size: 16),
              onPressed: () =>
                  ref.read(transferProvider.notifier).cancelTransfer(task.id),
              tooltip: 'Cancel',
              iconSize: 16,
              constraints:
                  const BoxConstraints(minWidth: 28, minHeight: 28),
            ),
          if (task.status == TransferStatus.completed)
            const Icon(Icons.check_circle, size: 16, color: Colors.green),
          if (task.status == TransferStatus.failed)
            Icon(Icons.error, size: 16, color: theme.colorScheme.error),
        ],
      ),
    );
  }

  String _buildProgressText(TransferTask task, double percent) {
    final parts = <String>[];
    parts.add('${percent.toStringAsFixed(1)}%');

    // Speed calculation
    if (task.startedAt != null && task.transferredBytes > 0) {
      final elapsed =
          DateTime.now().difference(task.startedAt!).inMilliseconds;
      if (elapsed > 0) {
        final bytesPerSec = task.transferredBytes / (elapsed / 1000);
        parts.add('${_formatBytes(bytesPerSec.round())}/s');

        // ETA
        if (task.totalBytes > task.transferredBytes && bytesPerSec > 0) {
          final remaining = task.totalBytes - task.transferredBytes;
          final etaSecs = (remaining / bytesPerSec).round();
          final mins = etaSecs ~/ 60;
          final secs = etaSecs % 60;
          parts.add('~$mins:${secs.toString().padLeft(2, '0')} remaining');
        }
      }
    }

    // Transferred / Total
    parts.add(
        '${_formatBytes(task.transferredBytes)} / ${_formatBytes(task.totalBytes)}');

    return parts.join(' \u2022 ');
  }

  static String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${units[i]}';
  }
}
