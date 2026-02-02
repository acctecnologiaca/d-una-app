import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'custom_search_bar.dart';

class FilterChipData {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const FilterChipData({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
}

class GenericSearchScreen<T> extends StatefulWidget {
  final String title;
  final String hintText;
  final String historyKey;
  final AsyncValue<List<T>> data;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final bool Function(T item, String query) filter;
  final List<FilterChipData> filters;
  final Widget? emptyState;
  final VoidCallback? onResetFilters;
  final ValueChanged<String>? onQueryChanged;

  const GenericSearchScreen({
    super.key,
    this.title = 'Buscar',
    this.hintText = 'Buscar...',
    required this.historyKey,
    required this.data,
    required this.itemBuilder,
    required this.filter,
    this.filters = const [],
    this.emptyState,
    this.onResetFilters,
    this.onQueryChanged,
  });

  @override
  State<GenericSearchScreen<T>> createState() => _GenericSearchScreenState<T>();
}

class _GenericSearchScreenState<T> extends State<GenericSearchScreen<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _history = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
      widget.onQueryChanged?.call(_searchController.text);
    });
    // Request focus after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _history = prefs.getStringList(widget.historyKey) ?? [];
    });
  }

  Future<void> _addToHistory(String query) async {
    if (query.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    List<String> newHistory = List.from(_history);

    // Remove if exists to move to top
    newHistory.remove(query);
    // Add to top
    newHistory.insert(0, query);
    // Limit to 10
    if (newHistory.length > 10) {
      newHistory = newHistory.sublist(0, 10);
    }

    await prefs.setStringList(widget.historyKey, newHistory);
    setState(() {
      _history = newHistory;
    });
  }

  Future<void> _removeFromHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> newHistory = List.from(_history);
    newHistory.remove(query);
    await prefs.setStringList(widget.historyKey, newHistory);
    setState(() {
      _history = newHistory;
    });
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(widget.historyKey);
    setState(() {
      _history = [];
    });
  }

  void _onSearchSubmitted(String query) {
    _addToHistory(query);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: colors.surfaceContainerHigh,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => Navigator.of(
            context,
          ).pop(), // Changed context.pop() to Navigator.of(context).pop() for standard Flutter
        ),
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: CustomSearchBar(
            controller: _searchController,
            focusNode: _focusNode,
            hintText: widget.hintText,
            onSubmitted: _onSearchSubmitted,
          ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Filters
          if (widget.filters.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children:
                    widget.filters.map((filter) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ActionChip(
                          label: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (filter.isActive) ...[
                                Icon(
                                  Icons.check,
                                  size: 18,
                                  color: colors.onSecondaryContainer,
                                ),
                                const SizedBox(width: 8),
                              ],
                              Text(
                                filter.label,
                                style: TextStyle(
                                  color: filter.isActive
                                      ? colors.onSecondaryContainer
                                      : colors.onSurface,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14, // Matches original font size
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_drop_down,
                                size: 20,
                                color: filter.isActive
                                    ? colors.onSecondaryContainer
                                    : colors.onSurface,
                              ),
                            ],
                          ),
                          backgroundColor: filter.isActive
                              ? colors.secondaryContainer
                              : colors.surface,
                          side: filter.isActive
                              ? const BorderSide(color: Colors.transparent)
                              : BorderSide(
                                  color: colors.outline.withOpacity(
                                    0.3,
                                  ), // Changed .withValues to .withOpacity
                                ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              8,
                            ), // Reduced radius
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          onPressed: filter.onTap,
                        ),
                      );
                    }).toList()..addAll([
                      if (widget.filters.any((f) => f.isActive) &&
                          widget.onResetFilters != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: TextButton(
                            onPressed: widget.onResetFilters,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              minimumSize: const Size(
                                0,
                                32,
                              ), // Match chip height roughly
                              visualDensity: VisualDensity.compact,
                            ),
                            child: Text(
                              "Borrar filtros",
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                    ]),
              ),
            ),

          Expanded(
            child: widget.data.when(
              data: (items) => _buildBody(items, colors),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<T> items, ColorScheme colors) {
    // Determine if we should show history or results
    // Show history only if query is empty AND no active filters allow results to be seen?
    // Actually, usually history is shown only when query is empty.
    // However, if we have active filters (e.g. "Category: Electronics"), we probably want to see results even if query is empty.
    // Logic: Show history if query is empty AND no filters are "active" (meaning narrowing down).
    // The `FilterChipData.isActive` usually means "User has selected a value".

    final bool hasActiveFilters = widget.filters.any((f) => f.isActive);
    final bool showHistory = _searchQuery.isEmpty && !hasActiveFilters;

    if (showHistory) {
      if (_history.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 64, color: colors.outline),
              const SizedBox(height: 16),
              Text(
                'No hay búsquedas recientes',
                style: TextStyle(color: colors.outline),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Historial de busqueda',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                if (_history.isNotEmpty)
                  TextButton(
                    onPressed: _clearHistory,
                    child: const Text('Borrar todo'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _history.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final term = _history[index];
                return Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListTile(
                    dense: true,
                    visualDensity: const VisualDensity(vertical: -1),
                    leading: Icon(
                      Icons.history,
                      color: colors.onSurfaceVariant,
                      size: 20,
                    ),
                    title: Text(
                      term,
                      style: TextStyle(color: colors.onSurface, fontSize: 15),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () => _removeFromHistory(term),
                    ),
                    onTap: () {
                      _searchController.text = term;
                      // Move cursor to end
                      _searchController.selection = TextSelection.fromPosition(
                        TextPosition(offset: term.length),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      );
    }

    // Filter Items
    final filteredItems = items.where((item) {
      return widget.filter(item, _searchQuery);
    }).toList();

    if (filteredItems.isEmpty) {
      return widget.emptyState ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 48,
                  color: colors.outline,
                ), // Fixed: size was missing in original logic often
                const SizedBox(height: 16),
                Text(
                  'No se encontraron resultados',
                  style: TextStyle(color: colors.outline),
                ),
              ],
            ),
          );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80), // Fab space mostly
      itemCount: filteredItems.length,
      itemBuilder: (context, index) =>
          widget.itemBuilder(context, filteredItems[index]),
    );
  }
}
