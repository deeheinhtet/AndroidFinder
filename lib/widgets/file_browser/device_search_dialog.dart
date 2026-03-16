import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/device_file_provider.dart';
import '../../providers/device_search_provider.dart';

class DeviceSearchDialog extends ConsumerStatefulWidget {
  final String serial;

  const DeviceSearchDialog({super.key, required this.serial});

  @override
  ConsumerState<DeviceSearchDialog> createState() => _DeviceSearchDialogState();
}

class _DeviceSearchDialogState extends ConsumerState<DeviceSearchDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(deviceSearchProvider(widget.serial));
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Search Device'),
      content: SizedBox(
        width: 480,
        height: 400,
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Enter file name...',
                border: const OutlineInputBorder(),
                suffixIcon: searchState.isSearching
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
              ),
              onSubmitted: (q) =>
                  ref.read(deviceSearchProvider(widget.serial).notifier).search(q),
            ),
            const SizedBox(height: 8),
            if (searchState.error != null)
              Text(
                searchState.error!,
                style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
              ),
            Text(
              '${searchState.results.length} result(s)',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: searchState.results.isEmpty && !searchState.isSearching
                  ? Center(
                      child: Text(
                        searchState.query.isEmpty
                            ? 'Enter a search term above'
                            : 'No results found',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: searchState.results.length,
                      itemBuilder: (context, i) {
                        final item = searchState.results[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.insert_drive_file, size: 16),
                          title: Text(
                            item.name,
                            style: const TextStyle(fontSize: 13),
                          ),
                          subtitle: Text(
                            item.absolutePath,
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            // Navigate to the containing folder
                            final parts = item.absolutePath.split('/');
                            parts.removeLast();
                            final dir = parts.join('/');
                            ref
                                .read(deviceFileProvider(widget.serial).notifier)
                                .navigateTo(dir.isEmpty ? '/' : dir);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            ref.read(deviceSearchProvider(widget.serial).notifier).clear();
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
        FilledButton(
          onPressed: () => ref
              .read(deviceSearchProvider(widget.serial).notifier)
              .search(_controller.text),
          child: const Text('Search'),
        ),
      ],
    );
  }
}
