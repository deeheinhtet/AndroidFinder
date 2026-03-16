import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/bookmarks_provider.dart';

class AddBookmarkDialog extends ConsumerStatefulWidget {
  final String currentPath;

  const AddBookmarkDialog({super.key, required this.currentPath});

  @override
  ConsumerState<AddBookmarkDialog> createState() => _AddBookmarkDialogState();
}

class _AddBookmarkDialogState extends ConsumerState<AddBookmarkDialog> {
  late final TextEditingController _labelController;
  late final TextEditingController _pathController;

  @override
  void initState() {
    super.initState();
    final parts = widget.currentPath.split('/');
    _labelController = TextEditingController(
        text: parts.last.isEmpty ? 'Root' : parts.last);
    _pathController = TextEditingController(text: widget.currentPath);
  }

  @override
  void dispose() {
    _labelController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Bookmark'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _labelController,
            decoration: const InputDecoration(
              labelText: 'Label',
              border: OutlineInputBorder(),
            ),
            autofocus: true,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _pathController,
            decoration: const InputDecoration(
              labelText: 'Path',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final label = _labelController.text.trim();
            final path = _pathController.text.trim();
            if (label.isNotEmpty && path.isNotEmpty) {
              ref.read(bookmarksProvider.notifier).addBookmark(label, path);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
