import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/file_item.dart';
import '../../providers/device_file_provider.dart';

class BatchRenameDialog extends ConsumerStatefulWidget {
  final List<FileItem> selectedItems;
  final String serial;

  const BatchRenameDialog({
    super.key,
    required this.selectedItems,
    required this.serial,
  });

  @override
  ConsumerState<BatchRenameDialog> createState() => _BatchRenameDialogState();
}

class _BatchRenameDialogState extends ConsumerState<BatchRenameDialog> {
  final _prefixController = TextEditingController(text: 'FILE_');
  final _startIndexController = TextEditingController(text: '1');
  final _padWidthController = TextEditingController(text: '3');
  bool _isRenaming = false;

  @override
  void dispose() {
    _prefixController.dispose();
    _startIndexController.dispose();
    _padWidthController.dispose();
    super.dispose();
  }

  String _getNewName(FileItem item, int index) {
    final prefix = _prefixController.text;
    final startIndex = int.tryParse(_startIndexController.text) ?? 1;
    final padWidth = int.tryParse(_padWidthController.text) ?? 3;
    final ext = item.name.contains('.') && !item.isDirectory
        ? '.${item.name.split('.').last}'
        : '';
    final num = (startIndex + index).toString().padLeft(padWidth, '0');
    return '$prefix$num$ext';
  }

  Future<void> _confirm() async {
    setState(() => _isRenaming = true);
    try {
      await ref
          .read(deviceFileProvider(widget.serial).notifier)
          .batchRename(
            widget.selectedItems,
            _prefixController.text,
            int.tryParse(_startIndexController.text) ?? 1,
            int.tryParse(_padWidthController.text) ?? 3,
          );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _isRenaming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rename failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Batch Rename'),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _prefixController,
                    decoration: const InputDecoration(
                      labelText: 'Prefix',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _startIndexController,
                    decoration: const InputDecoration(
                      labelText: 'Start #',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 90,
                  child: TextField(
                    controller: _padWidthController,
                    decoration: const InputDecoration(
                      labelText: 'Pad Width',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Preview (${widget.selectedItems.length} files):',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: widget.selectedItems.length,
                itemBuilder: (context, index) {
                  final item = widget.selectedItems[index];
                  final newName = _getNewName(item, index);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.arrow_forward, size: 14),
                        Expanded(
                          child: Text(
                            newName,
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isRenaming ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isRenaming ? null : _confirm,
          child: _isRenaming
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Rename'),
        ),
      ],
    );
  }
}
