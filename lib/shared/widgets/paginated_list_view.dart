import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/ads/domain/models/ad_banner_model.dart';
import '../../features/ads/presentation/providers/ads_provider.dart';
import '../../features/ads/presentation/widgets/ad_banner_card.dart';
import '../utils/ad_list_position_helper.dart';

class PaginatedListView<T> extends ConsumerStatefulWidget {
  final List<T> items;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final VoidCallback onLoadMore;
  final Widget Function(BuildContext context, int index, T item) itemBuilder;
  final IndexedWidgetBuilder? separatorBuilder;
  final EdgeInsets padding;
  final ScrollPhysics? physics;
  final ScrollController? externalController;

  // Parámetros de Banners Publicitarios
  final List<AdBanner>? banners;
  final String? screenContext;
  final String? searchQuery;
  final int adFirstIndex;
  final int adInterval;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.isLoadingMore,
    required this.hasReachedEnd,
    required this.onLoadMore,
    required this.itemBuilder,
    this.separatorBuilder,
    this.padding = const EdgeInsets.all(0),
    this.physics,
    this.externalController,
    this.banners,
    this.screenContext,
    this.searchQuery,
    this.adFirstIndex = 3,
    this.adInterval = 6,
  });

  @override
  ConsumerState<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends ConsumerState<PaginatedListView<T>> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.externalController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    if (widget.externalController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      if (!widget.isLoadingMore && !widget.hasReachedEnd) {
        widget.onLoadMore();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeBanners = widget.banners ?? [];
    final dismissedIds = ref.watch(dismissedBannerIdsProvider);

    final totalVisualCount = AdListPositionHelper.calculateTotalCount(
      realCount: widget.items.length,
      banners: activeBanners,
      dismissedIds: dismissedIds,
      firstIndex: widget.adFirstIndex,
      interval: widget.adInterval,
    );

    return ListView.separated(
      controller: _scrollController,
      padding: widget.padding,
      physics: widget.physics ?? const AlwaysScrollableScrollPhysics(),
      itemCount: totalVisualCount + 1, // +1 for loading indicator / end message
      separatorBuilder: widget.separatorBuilder ??
          (context, index) =>
              const Divider(height: 1, color: Colors.transparent),
      itemBuilder: (context, index) {
        if (index < totalVisualCount) {
          // 1. Determinar si en este índice visual hay un banner activo
          final banner = AdListPositionHelper.getBannerAtVisualIndex(
            index,
            realCount: widget.items.length,
            banners: activeBanners,
            dismissedIds: dismissedIds,
            firstIndex: widget.adFirstIndex,
            interval: widget.adInterval,
          );

          if (banner != null) {
            return AdBannerCard(
              banner: banner,
              screenContext: widget.screenContext ?? 'list',
              searchQuery: widget.searchQuery,
            );
          }

          // 2. Elemento real de la lista
          final realIndex = AdListPositionHelper.getRealIndex(
            index,
            realCount: widget.items.length,
            banners: activeBanners,
            dismissedIds: dismissedIds,
            firstIndex: widget.adFirstIndex,
            interval: widget.adInterval,
          );

          if (realIndex >= 0 && realIndex < widget.items.length) {
            return widget.itemBuilder(context, realIndex, widget.items[realIndex]);
          }
          return const SizedBox.shrink();
        } else {
          // Bottom widget (Loading more / End of list)
          if (widget.isLoadingMore) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Center(child: CircularProgressIndicator()),
            );
          } else if (widget.hasReachedEnd && widget.items.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Text(
                  'No hay más elementos',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ),
            );
          } else {
            return const SizedBox.shrink();
          }
        }
      },
    );
  }
}
