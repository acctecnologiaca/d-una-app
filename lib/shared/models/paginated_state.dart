class PaginatedState<T> {
  final List<T> items;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final int currentOffset;
  final Object? error;

  static const int pageSize = 25;

  bool get isInitialLoading => items.isEmpty && !hasReachedEnd && error == null;
  int get nextOffset => currentOffset + pageSize;

  const PaginatedState({
    this.items = const [],
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.currentOffset = 0,
    this.error,
  });

  PaginatedState<T> copyWith({
    List<T>? items,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    int? currentOffset,
    Object? error,
  }) {
    return PaginatedState<T>(
      items: items ?? this.items,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      currentOffset: currentOffset ?? this.currentOffset,
      error: error ?? this.error,
    );
  }
}
