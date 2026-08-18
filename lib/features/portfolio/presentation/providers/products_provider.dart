import 'dart:async';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_products_repository.dart';
import '../../data/models/product_model.dart';
import '../../../../shared/models/paginated_state.dart';

final productsRepositoryProvider = Provider<SupabaseProductsRepository>((ref) {
  return SupabaseProductsRepository(Supabase.instance.client);
});

final productsProvider = AsyncNotifierProvider<ProductsNotifier, List<Product>>(
  () {
    return ProductsNotifier();
  },
);

class ProductsNotifier extends AsyncNotifier<List<Product>> {
  @override
  FutureOr<List<Product>> build() async {
    return ref.read(productsRepositoryProvider).getProducts();
  }

  Future<void> createProduct(
    Product product, {
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(productsRepositoryProvider)
          .createProduct(
            product,
            imageBytes: imageBytes,
            imageExtension: imageExtension,
          );
      ref.invalidate(paginatedProductsProvider);
      ref.invalidate(paginatedProductSearchProvider);
      return ref.read(productsRepositoryProvider).getProducts();
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> updateProduct(
    Product product, {
    Uint8List? imageBytes,
    String? imageExtension,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(productsRepositoryProvider)
          .updateProduct(
            product,
            imageBytes: imageBytes,
            imageExtension: imageExtension,
          );
      ref.invalidate(paginatedProductsProvider);
      ref.invalidate(paginatedProductSearchProvider);
      return ref.read(productsRepositoryProvider).getProducts();
    });
    if (state.hasError) throw state.error!;
  }

  Future<void> deleteProduct(String id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(productsRepositoryProvider).deleteProduct(id);
      ref.invalidate(paginatedProductsProvider);
      ref.invalidate(paginatedProductSearchProvider);
      ref.invalidate(productHasLinkedDocumentsProvider(id));
      return ref.read(productsRepositoryProvider).getProducts();
    });
  }
}

// --- Paginated Products ---
final paginatedProductsProvider =
    AsyncNotifierProvider<PaginatedProducts, PaginatedState<Product>>(
      () => PaginatedProducts(),
    );

class PaginatedProducts extends AsyncNotifier<PaginatedState<Product>> {
  static const int _limit = 25;
  String? _searchQuery;
  String? _categoryId;
  String? _brandId;
  String _orderBy = 'created_at';
  bool _ascending = false;

  @override
  FutureOr<PaginatedState<Product>> build() async {
    return _fetchPage(0);
  }

  Future<PaginatedState<Product>> _fetchPage(int offset) async {
    final products = await ref
        .read(productsRepositoryProvider)
        .getProductsPaginated(
          offset: offset,
          limit: _limit,
          searchQuery: _searchQuery,
          categoryId: _categoryId,
          brandId: _brandId,
          orderBy: _orderBy,
          ascending: _ascending,
        );
    return PaginatedState<Product>(
      items: products,
      hasReachedEnd: products.length < _limit,
      currentOffset: offset,
      isLoadingMore: false,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || current.hasReachedEnd) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final nextOffset = current.currentOffset + _limit;
      final newPage = await _fetchPage(nextOffset);

      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...newPage.items],
          currentOffset: nextOffset,
          hasReachedEnd: newPage.hasReachedEnd,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false, error: e));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(0));
  }

  void updateSearch(String? query) {
    _searchQuery = query;
    refresh();
  }

  void updateFilters({String? categoryId, String? brandId}) {
    _categoryId = categoryId;
    _brandId = brandId;
    refresh();
  }

  void updateSort(String orderBy, bool ascending) {
    _orderBy = orderBy;
    _ascending = ascending;
    refresh();
  }
}

// --- Paginated Product Search (AutoDispose) ---
final paginatedProductSearchProvider =
    AutoDisposeAsyncNotifierProvider<
      PaginatedProductSearch,
      PaginatedState<Product>
    >(() => PaginatedProductSearch());

class PaginatedProductSearch
    extends AutoDisposeAsyncNotifier<PaginatedState<Product>> {
  static const int _limit = 25;
  String? _searchQuery;
  String? _categoryId;
  String? _brandId;
  String _orderBy = 'created_at';
  bool _ascending = false;

  @override
  FutureOr<PaginatedState<Product>> build() async {
    return _fetchPage(0);
  }

  Future<PaginatedState<Product>> _fetchPage(int offset) async {
    final products = await ref
        .read(productsRepositoryProvider)
        .getProductsPaginated(
          offset: offset,
          limit: _limit,
          searchQuery: _searchQuery,
          categoryId: _categoryId,
          brandId: _brandId,
          orderBy: _orderBy,
          ascending: _ascending,
        );
    return PaginatedState<Product>(
      items: products,
      hasReachedEnd: products.length < _limit,
      currentOffset: offset,
      isLoadingMore: false,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || current.hasReachedEnd) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final nextOffset = current.currentOffset + _limit;
      final newPage = await _fetchPage(nextOffset);

      state = AsyncData(
        current.copyWith(
          items: [...current.items, ...newPage.items],
          currentOffset: nextOffset,
          hasReachedEnd: newPage.hasReachedEnd,
          isLoadingMore: false,
        ),
      );
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false, error: e));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(0));
  }

  void updateSearch(String? query) {
    _searchQuery = query;
    refresh();
  }

  void updateFilters({String? categoryId, String? brandId}) {
    _categoryId = categoryId;
    _brandId = brandId;
    refresh();
  }

  void updateSort(String orderBy, bool ascending) {
    _orderBy = orderBy;
    _ascending = ascending;
    refresh();
  }
}

final productHasLinkedDocumentsProvider =
    FutureProvider.family<bool, String>((ref, productId) async {
  return ref.read(productsRepositoryProvider).hasLinkedDocuments(productId);
});
