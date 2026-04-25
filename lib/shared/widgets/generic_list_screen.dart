import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';

class GenericListScreen<T> extends ConsumerStatefulWidget {
  final String title;
  final String? subtitle;
  final String? descriptionText;
  final Widget? headerWidget;
  final AsyncValue<List<T>> itemsAsync;

  /// Predicate to filter items. If null, no search is performed.
  final bool Function(T item, String query)? onSearch;

  /// Current sort options. If null, no sort selector is shown.
  final List<SortOption>? sortOptions;

  /// Initial sort option. Required if sortOptions is not null.
  final SortOption? initialSort;

  /// Sorting logic. Required if sortOptions is not null.
  final int Function(T a, T b, SortOption sort)? onSort;

  /// Builds the visual representation of an item, typically a StandardListItem.
  final Widget Function(BuildContext context, T item) itemBuilder;

  /// Action when the FAB is pressed. If null, no FAB is shown.
  final VoidCallback? onAddPressed;

  final String emptyListMessage;

  /// Floating Action Button label
  final String fabLabel;

  /// Floating Action Button icon
  final IconData fabIcon;

  /// Whether the Floating Action Button is enabled
  final bool isFabEnabled;

  /// Pre-sort hook if you need to filter the main async list (e.g. by owner id)
  /// before searching and sorting is applied.
  final List<T> Function(List<T> items)? preFilter;

  const GenericListScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.descriptionText,
    this.headerWidget,
    required this.itemsAsync,
    this.onSearch,
    this.sortOptions,
    this.initialSort,
    this.onSort,
    required this.itemBuilder,
    this.onAddPressed,
    required this.emptyListMessage,
    this.fabLabel = 'Agregar',
    this.fabIcon = Icons.add,
    this.isFabEnabled = true,
    this.preFilter,
  }) : assert(
         (sortOptions == null && initialSort == null && onSort == null) ||
             (sortOptions != null && initialSort != null && onSort != null),
         'If sortOptions are provided, initialSort and onSort must also be provided.',
       );

  @override
  ConsumerState<GenericListScreen<T>> createState() =>
      _GenericListScreenState<T>();
}

class _GenericListScreenState<T> extends ConsumerState<GenericListScreen<T>> {
  late SortOption? _currentSort;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentSort = widget.initialSort;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: StandardAppBar(
        title: widget.title,
        subtitle: widget.subtitle,
        isSearchable: widget.onSearch != null,
        onSearchChanged: widget.onSearch != null
            ? (value) => setState(() => _searchQuery = value)
            : null,
        onSearchClosed: widget.onSearch != null
            ? () => setState(() => _searchQuery = '')
            : null,
      ),
      floatingActionButton: widget.onAddPressed != null
          ? Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: CustomExtendedFab(
                onPressed: widget.onAddPressed!,
                label: widget.fabLabel,
                icon: widget.fabIcon,
                isEnabled: widget.isFabEnabled,
                backgroundColor: colors.tertiaryContainer,
                foregroundColor: colors.onTertiaryContainer,
              ),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.headerWidget != null) widget.headerWidget!,

          if (widget.descriptionText != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                widget.descriptionText!,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurface,
                  height: 1.5,
                ),
              ),
            ),

          if (widget.sortOptions != null && _currentSort != null)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: SortSelector(
                currentSort: _currentSort!,
                options: widget.sortOptions!,
                onSortChanged: (sort) => setState(() => _currentSort = sort),
              ),
            ),

          if (widget.headerWidget != null ||
              widget.descriptionText != null ||
              widget.sortOptions != null)
            const SizedBox(height: 8),

          Expanded(
            child: widget.itemsAsync.when(
              data: (items) {
                // 1. Initial pre-filtering (e.g. only items owned by user)
                var processedList = widget.preFilter != null
                    ? widget.preFilter!(items)
                    : List<T>.from(items);

                // 2. Search filtering
                if (widget.onSearch != null && _searchQuery.isNotEmpty) {
                  processedList = processedList
                      .where((item) => widget.onSearch!(item, _searchQuery))
                      .toList();
                }

                // 3. Sorting
                if (widget.onSort != null && _currentSort != null) {
                  processedList.sort(
                    (a, b) => widget.onSort!(a, b, _currentSort!),
                  );
                }

                if (processedList.isEmpty) {
                  return Center(
                    child: Text(
                      widget.emptyListMessage,
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: processedList.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 8),
                  itemBuilder: (context, index) {
                    final item = processedList[index];
                    return widget.itemBuilder(context, item);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  'Error al cargar',
                  style: TextStyle(color: colors.error),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
