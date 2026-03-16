import 'package:flutter/material.dart';
import '../../models/sort_option.dart';

class FileToolbar extends StatefulWidget {
  final bool canGoBack;
  final bool canGoForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  final VoidCallback onUp;
  final VoidCallback onRefresh;
  final VoidCallback onHome;
  final VoidCallback onNewFolder;
  final VoidCallback? onDeviceSearch;
  final bool isDevicePanel;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final SortField sortField;
  final bool sortAscending;
  final ValueChanged<SortField> onSortChanged;
  final ValueNotifier<bool>? searchFocusTrigger;

  const FileToolbar({
    super.key,
    required this.canGoBack,
    required this.canGoForward,
    required this.onBack,
    required this.onForward,
    required this.onUp,
    required this.onRefresh,
    required this.onHome,
    required this.onNewFolder,
    required this.isDevicePanel,
    this.onDeviceSearch,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.sortField,
    required this.sortAscending,
    required this.onSortChanged,
    this.searchFocusTrigger,
  });

  @override
  State<FileToolbar> createState() => _FileToolbarState();
}

class _FileToolbarState extends State<FileToolbar> {
  bool _showSearch = false;
  late TextEditingController _searchController;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
    widget.searchFocusTrigger?.addListener(_onSearchFocusTrigger);
  }

  @override
  void didUpdateWidget(FileToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery &&
        widget.searchQuery != _searchController.text) {
      _searchController.text = widget.searchQuery;
    }
    if (widget.searchQuery.isEmpty && _showSearch) {
      // Keep search open if user cleared it manually
    }
    if (widget.searchFocusTrigger != oldWidget.searchFocusTrigger) {
      oldWidget.searchFocusTrigger?.removeListener(_onSearchFocusTrigger);
      widget.searchFocusTrigger?.addListener(_onSearchFocusTrigger);
    }
  }

  void _onSearchFocusTrigger() {
    setState(() => _showSearch = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
  }

  void closeSearch() {
    _searchController.clear();
    widget.onSearchChanged('');
    setState(() => _showSearch = false);
  }

  @override
  void dispose() {
    widget.searchFocusTrigger?.removeListener(_onSearchFocusTrigger);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _ToolbarButton(
                    icon: Icons.arrow_back,
                    tooltip: 'Back',
                    onPressed: widget.canGoBack ? widget.onBack : null,
                  ),
                  _ToolbarButton(
                    icon: Icons.arrow_forward,
                    tooltip: 'Forward',
                    onPressed: widget.canGoForward ? widget.onForward : null,
                  ),
                  _ToolbarButton(
                    icon: Icons.arrow_upward,
                    tooltip: 'Up',
                    onPressed: widget.onUp,
                  ),
                  _ToolbarButton(
                    icon: Icons.home,
                    tooltip: 'Home',
                    onPressed: widget.onHome,
                  ),
                  const SizedBox(width: 8),
                  _ToolbarButton(
                    icon: Icons.refresh,
                    tooltip: 'Refresh (F5)',
                    onPressed: widget.onRefresh,
                  ),
                  if (widget.isDevicePanel) ...[
                    _ToolbarButton(
                      icon: Icons.create_new_folder,
                      tooltip: 'New Folder',
                      onPressed: widget.onNewFolder,
                    ),
                    _ToolbarButton(
                      icon: Icons.manage_search,
                      tooltip: 'Search Device (Ctrl+Shift+F)',
                      onPressed: widget.onDeviceSearch,
                    ),
                  ],
                  const SizedBox(width: 8),
                  // Sort dropdown
                  _SortDropdown(
                    sortField: widget.sortField,
                    sortAscending: widget.sortAscending,
                    onSortChanged: widget.onSortChanged,
                  ),
                ],
              ),
            ),
          ),
          // Search
          if (_showSearch)
            SizedBox(
              width: 180,
              height: 28,
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autofocus: true,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Filter files...',
                  hintStyle: const TextStyle(fontSize: 13),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                    borderSide: BorderSide(
                        color: theme.colorScheme.outline.withOpacity(0.3)),
                  ),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close, size: 14),
                    onPressed: () {
                      _searchController.clear();
                      widget.onSearchChanged('');
                      setState(() => _showSearch = false);
                    },
                    padding: EdgeInsets.zero,
                    constraints:
                        const BoxConstraints(minWidth: 24, minHeight: 24),
                  ),
                ),
                onChanged: widget.onSearchChanged,
              ),
            )
          else
            _ToolbarButton(
              icon: Icons.search,
              tooltip: 'Search (Ctrl+F)',
              onPressed: () => setState(() => _showSearch = true),
            ),
        ],
      ),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final SortField sortField;
  final bool sortAscending;
  final ValueChanged<SortField> onSortChanged;

  const _SortDropdown({
    required this.sortField,
    required this.sortAscending,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<SortField>(
      tooltip: 'Sort by',
      onSelected: onSortChanged,
      offset: const Offset(0, 32),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
            const SizedBox(width: 2),
            Text(
              _sortLabel(sortField),
              style: TextStyle(
                fontSize: 12,
                color:
                    Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              size: 16,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        _buildItem(context, SortField.name, 'Name', Icons.sort_by_alpha),
        _buildItem(context, SortField.size, 'Size', Icons.storage),
        _buildItem(context, SortField.date, 'Date', Icons.calendar_today),
        _buildItem(context, SortField.type, 'Type', Icons.category),
      ],
    );
  }

  PopupMenuItem<SortField> _buildItem(
      BuildContext context, SortField field, String label, IconData icon) {
    final isActive = sortField == field;
    return PopupMenuItem<SortField>(
      value: field,
      child: Row(
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(label),
          if (isActive) ...[
            const Spacer(),
            Icon(
              sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: Theme.of(context).colorScheme.primary,
            ),
          ],
        ],
      ),
    );
  }

  String _sortLabel(SortField field) {
    switch (field) {
      case SortField.name:
        return 'Name';
      case SortField.size:
        return 'Size';
      case SortField.date:
        return 'Date';
      case SortField.type:
        return 'Type';
    }
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 18,
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
      padding: const EdgeInsets.all(4),
    );
  }
}
