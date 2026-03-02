import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/device_file_provider.dart';

class QuickAccessSidebar extends ConsumerStatefulWidget {
  final String serial;

  const QuickAccessSidebar({super.key, required this.serial});

  @override
  ConsumerState<QuickAccessSidebar> createState() => _QuickAccessSidebarState();
}

class _QuickAccessSidebarState extends ConsumerState<QuickAccessSidebar> {
  bool _collapsed = false;

  static const _bookmarks = [
    _Bookmark('DCIM', Icons.camera_alt, '/sdcard/DCIM'),
    _Bookmark('Downloads', Icons.download, '/sdcard/Download'),
    _Bookmark('Music', Icons.music_note, '/sdcard/Music'),
    _Bookmark('Pictures', Icons.image, '/sdcard/Pictures'),
    _Bookmark('Movies', Icons.movie, '/sdcard/Movies'),
    _Bookmark('Documents', Icons.description, '/sdcard/Documents'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentPath = ref.watch(
      deviceFileProvider(widget.serial).select((s) => s.currentPath),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _collapsed ? 32 : 72,
      decoration: BoxDecoration(
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _collapsed = !_collapsed),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Icon(
                _collapsed ? Icons.chevron_right : Icons.chevron_left,
                size: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ),
          if (!_collapsed) ...[
            Divider(
              height: 1,
              color: theme.colorScheme.outline.withOpacity(0.1),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 4),
                children: _bookmarks.map((b) {
                  final isActive = currentPath == b.path;
                  return _BookmarkButton(
                    bookmark: b,
                    isActive: isActive,
                    onTap: () => ref
                        .read(deviceFileProvider(widget.serial).notifier)
                        .navigateTo(b.path),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Bookmark {
  final String label;
  final IconData icon;
  final String path;

  const _Bookmark(this.label, this.icon, this.path);
}

class _BookmarkButton extends StatelessWidget {
  final _Bookmark bookmark;
  final bool isActive;
  final VoidCallback onTap;

  const _BookmarkButton({
    required this.bookmark,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: bookmark.path,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? theme.colorScheme.primaryContainer.withOpacity(0.5)
                : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                bookmark.icon,
                size: 18,
                color: isActive
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withOpacity(0.6),
              ),
              const SizedBox(height: 2),
              Text(
                bookmark.label,
                style: TextStyle(
                  fontSize: 9,
                  color: isActive
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withOpacity(0.6),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
