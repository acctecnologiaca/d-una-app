import 'package:flutter/material.dart';

class SearchableSelectionSheet<T extends Object> extends StatefulWidget {
  final String title;
  final List<T> items;
  final T? selectedValue;
  final String Function(T) itemLabelBuilder;
  final String Function(T)? itemSubtitleBuilder;
  final bool showAddOption;
  final String addOptionLabel;
  final VoidCallback? onAddPressed;

  const SearchableSelectionSheet._({
    required this.title,
    required this.items,
    required this.selectedValue,
    required this.itemLabelBuilder,
    this.itemSubtitleBuilder,
    this.showAddOption = false,
    this.addOptionLabel = 'Agregar',
    this.onAddPressed,
  });

  static Future<T?> show<T extends Object>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required T? selectedValue,
    required String Function(T) itemLabelBuilder,
    String Function(T)? itemSubtitleBuilder,
    bool showAddOption = false,
    String addOptionLabel = 'Agregar',
    VoidCallback? onAddPressed,
  }) {
    return showModalBottomSheet<T?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SearchableSelectionSheet<T>._(
        title: title,
        items: items,
        selectedValue: selectedValue,
        itemLabelBuilder: itemLabelBuilder,
        itemSubtitleBuilder: itemSubtitleBuilder,
        showAddOption: showAddOption,
        addOptionLabel: addOptionLabel,
        onAddPressed: onAddPressed,
      ),
    );
  }

  @override
  State<SearchableSelectionSheet<T>> createState() =>
      _SearchableSelectionSheetState<T>();
}

class _SearchableSelectionSheetState<T extends Object>
    extends State<SearchableSelectionSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final filteredItems = widget.items.where((item) {
      if (_searchQuery.isEmpty) return true;
      final label = widget.itemLabelBuilder(item).toLowerCase();
      final subtitle =
          widget.itemSubtitleBuilder?.call(item).toLowerCase() ?? '';
      return label.contains(_searchQuery.toLowerCase()) ||
          subtitle.contains(_searchQuery.toLowerCase());
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                height: 4,
                width: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header (Close button + Title)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.title,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar (Under Title, matching FilterBottomSheet)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _searchController,
                autofocus: false,
                decoration: InputDecoration(
                  hintText: 'Buscar ${widget.title.toLowerCase()}...',
                  //prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 20),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: colors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: colors.outline),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // Add Option (if enabled)
            if (widget.showAddOption)
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  widget.onAddPressed?.call();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.add,
                        color: colors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.addOptionLabel,
                        style: TextStyle(
                          color: colors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Options List
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          _searchQuery.isNotEmpty
                              ? 'No se encontraron resultados para "$_searchQuery"'
                              : 'No hay opciones disponibles',
                          style: TextStyle(color: colors.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final isSelected = widget.selectedValue == item;
                        final label = widget.itemLabelBuilder(item);
                        final subtitle = widget.itemSubtitleBuilder?.call(item);
                        final initial = label.isNotEmpty
                            ? label[0].toUpperCase()
                            : '?';

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? colors.primaryContainer
                                : colors.secondaryContainer,
                            child: Text(
                              initial,
                              style: TextStyle(
                                color: isSelected
                                    ? colors.onPrimaryContainer
                                    : colors.onSecondaryContainer,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(
                            label,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isSelected
                                   ? FontWeight.bold
                                   : FontWeight.w400,
                              color: colors.onSurface,
                            ),
                          ),
                          subtitle: subtitle != null && subtitle.isNotEmpty
                              ? Text(
                                  subtitle,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: colors.onSurfaceVariant,
                                  ),
                                )
                              : null,
                          trailing: isSelected
                              ? Icon(Icons.check, color: colors.primary)
                              : null,
                          onTap: () {
                            Navigator.pop(context, item);
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
