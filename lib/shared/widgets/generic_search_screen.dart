import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'custom_search_bar.dart';
import 'horizontal_filter_bar.dart';
import '../models/paginated_state.dart';
import 'paginated_list_view.dart';
import '../../features/ads/domain/models/ad_banner_model.dart';
import '../../features/ads/presentation/providers/ads_provider.dart';
import '../../features/ads/presentation/widgets/ad_banner_card.dart';
import '../utils/ad_list_position_helper.dart';

class GenericSearchScreen<T> extends StatefulWidget {
  final String title;
  final String hintText;
  final String historyKey;
  final AsyncValue<List<T>>? data;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final bool Function(T item, String query)? filter;
  final List<FilterChipData> filters;
  final Widget? emptyState;
  final VoidCallback? onResetFilters;
  final ValueChanged<String>? onQueryChanged;
  final Widget? bottomFilterWidget;
  final int Function(T a, T b)? comparator;
  final String? initialQuery;
  final bool readOnly;
  final bool showHistory;
  final PreferredSizeWidget? appBarOverride;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  // Paginated Mode
  final bool isPaginatedMode;
  final AsyncValue<PaginatedState<T>>? paginatedDataAsync;
  final ValueChanged<String>? onServerSearch;
  final VoidCallback? onLoadMore;

  // Banners Publicitarios
  final List<AdBanner>? banners;
  final String? screenContext;

  const GenericSearchScreen({
    super.key,
    this.title = 'Buscar',
    this.hintText = 'Buscar...',
    required this.historyKey,
    this.data,
    required this.itemBuilder,
    this.filter,
    this.filters = const [],
    this.emptyState,
    this.onResetFilters,
    this.onQueryChanged,
    this.bottomFilterWidget,
    this.comparator,
    this.initialQuery,
    this.readOnly = false,
    this.showHistory = true,
    this.appBarOverride,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.isPaginatedMode = false,
    this.paginatedDataAsync,
    this.onServerSearch,
    this.onLoadMore,
    this.banners,
    this.screenContext,
  });

  @override
  State<GenericSearchScreen<T>> createState() => _GenericSearchScreenState<T>();
}

class _GenericSearchScreenState<T> extends State<GenericSearchScreen<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<String> _history = [];
  String _searchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    // Pre-fill search if initialQuery is provided BEFORE attaching listener
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      _searchController.text = widget.initialQuery!;
      _searchQuery = widget.initialQuery!;
    }
    _searchController.addListener(_onSearchInputChanged);
    // Request focus after build (only if not readOnly)
    if (!widget.readOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _focusNode.requestFocus();
      });
    }
  }

  void _onSearchInputChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
    widget.onQueryChanged?.call(_searchController.text);

    if (widget.isPaginatedMode) {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (mounted) widget.onServerSearch?.call(_searchController.text);
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
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

  Future<void> _addToHistory(String term) async {
    if (term.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final cleanTerm = term.trim();

    _history.remove(cleanTerm);
    _history.insert(0, cleanTerm);

    if (_history.length > 5) {
      _history = _history.sublist(0, 5);
    }

    await prefs.setStringList(widget.historyKey, _history);
    setState(() {});
  }

  Future<void> _removeFromHistory(String term) async {
    final prefs = await SharedPreferences.getInstance();
    _history.remove(term);
    await prefs.setStringList(widget.historyKey, _history);
    setState(() {});
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(widget.historyKey);
    setState(() {
      _history.clear();
    });
  }

  void _onSearchSubmitted(String value) {
    if (value.isNotEmpty) {
      _addToHistory(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      floatingActionButtonLocation: widget.floatingActionButtonLocation,
      floatingActionButton: widget.floatingActionButton,
      appBar:
          widget.appBarOverride ??
          AppBar(
            backgroundColor: colors.surfaceContainerHigh,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: colors.onSurface),
              onPressed: () => Navigator.of(context).pop(),
            ),
            titleSpacing: 0,
            title: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: CustomSearchBar(
                controller: _searchController,
                focusNode: _focusNode,
                hintText: widget.hintText,
                readOnly: widget.readOnly,
                onSubmitted: _onSearchSubmitted,
              ),
            ),
          ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Filter Bar (Chips)
          if (widget.filters.isNotEmpty)
            HorizontalFilterBar(
              filters: widget.filters,
              onResetFilters: widget.onResetFilters,
            ),

          // 2. Optional Bottom Filter (e.g. Sort selector)
          if (widget.bottomFilterWidget != null) widget.bottomFilterWidget!,

          // 3. Content Area
          Expanded(
            child: widget.isPaginatedMode
                ? (widget.paginatedDataAsync?.when(
                        data: (state) => _buildPaginatedBody(state, colors),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => FriendlyErrorWidget(
                          error: err,
                          onRetry: () =>
                              widget.onServerSearch?.call(_searchQuery),
                        ),
                      ) ??
                      const SizedBox.shrink())
                : (widget.data?.when(
                        data: (items) => _buildBody(items, colors),
                        loading: () =>
                            const Center(child: CircularProgressIndicator()),
                        error: (err, stack) => FriendlyErrorWidget(error: err),
                      ) ??
                      const SizedBox.shrink()),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(List<T> items, ColorScheme colors) {
    final bool hasActiveFilters = widget.filters.any((f) => f.isActive);
    final bool showHistory =
        widget.showHistory && _searchQuery.isEmpty && !hasActiveFilters;

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
    final filteredItems = widget.filter != null
        ? items.where((item) => widget.filter!(item, _searchQuery)).toList()
        : items;

    // Sort Items
    if (widget.comparator != null) {
      filteredItems.sort(widget.comparator!);
    }

    if (filteredItems.isEmpty) {
      return widget.emptyState ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48, color: colors.outline),
                const SizedBox(height: 16),
                Text(
                  'No se encontraron resultados',
                  style: TextStyle(color: colors.outline),
                ),
              ],
            ),
          );
    }

    final activeBanners = widget.banners ?? [];

    return Consumer(
      builder: (context, ref, child) {
        final dismissedIds = ref.watch(dismissedBannerIdsProvider);
        final totalCount = AdListPositionHelper.calculateTotalCount(
          realCount: filteredItems.length,
          banners: activeBanners,
          dismissedIds: dismissedIds,
        );

        return ListView.builder(
          padding: const EdgeInsets.only(bottom: 80),
          itemCount: totalCount,
          itemBuilder: (context, index) {
            final banner = AdListPositionHelper.getBannerAtVisualIndex(
              index,
              realCount: filteredItems.length,
              banners: activeBanners,
              dismissedIds: dismissedIds,
            );

            if (banner != null) {
              return AdBannerCard(
                banner: banner,
                screenContext: widget.screenContext ?? 'search',
                searchQuery: _searchQuery,
              );
            }

            final realIndex = AdListPositionHelper.getRealIndex(
              index,
              realCount: filteredItems.length,
              banners: activeBanners,
              dismissedIds: dismissedIds,
            );
            if (realIndex >= 0 && realIndex < filteredItems.length) {
              return widget.itemBuilder(context, filteredItems[realIndex]);
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  Widget _buildPaginatedBody(PaginatedState<T> state, ColorScheme colors) {
    final bool hasActiveFilters = widget.filters.any((f) => f.isActive);
    final bool showHistory =
        widget.showHistory && _searchQuery.isEmpty && !hasActiveFilters;

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

    if (state.isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // Apply client-side filter to paginated items if provided
    final filteredItems = widget.filter != null
        ? state.items
              .where((item) => widget.filter!(item, _searchQuery))
              .toList()
        : state.items;

    if (filteredItems.isEmpty && !state.isLoadingMore) {
      return widget.emptyState ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 48, color: colors.outline),
                const SizedBox(height: 16),
                Text(
                  'No se encontraron resultados',
                  style: TextStyle(color: colors.outline),
                ),
              ],
            ),
          );
    }

    return PaginatedListView<T>(
      items: filteredItems,
      isLoadingMore: state.isLoadingMore,
      hasReachedEnd: state.hasReachedEnd,
      onLoadMore: () {
        widget.onLoadMore?.call();
      },
      banners: widget.banners,
      screenContext: widget.screenContext,
      searchQuery: _searchQuery,
      padding: const EdgeInsets.only(bottom: 80),
      itemBuilder: (context, index, item) => widget.itemBuilder(context, item),
    );
  }
}
