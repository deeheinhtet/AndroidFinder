import 'package:flutter/material.dart';

class FileBreadcrumbBar extends StatelessWidget {
  final String path;
  final String label;
  final IconData icon;
  final void Function(String path) onPathTap;

  const FileBreadcrumbBar({
    super.key,
    required this.path,
    required this.label,
    required this.icon,
    required this.onPathTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right,
              size: 16, color: theme.colorScheme.onSurface.withOpacity(0.3)),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  InkWell(
                    onTap: () => onPathTap('/'),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      child: Text(
                        '/',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                  for (var i = 0; i < segments.length; i++) ...[
                    Icon(Icons.chevron_right,
                        size: 14,
                        color:
                            theme.colorScheme.onSurface.withOpacity(0.3)),
                    InkWell(
                      onTap: () {
                        final targetPath =
                            '/${segments.sublist(0, i + 1).join('/')}';
                        onPathTap(targetPath);
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        child: Text(
                          segments[i],
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: i == segments.length - 1
                                ? theme.colorScheme.onSurface
                                : theme.colorScheme.primary,
                            fontWeight: i == segments.length - 1
                                ? FontWeight.w600
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
