import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/features/quotes/domain/models/quote_model.dart' show StockStatus;
import '../../../domain/repositories/supplier_orders_repository.dart';
import '../../../data/repositories/supabase_supplier_orders_repository.dart';
import '../../../domain/models/supplier_order.dart';
import '../../../domain/models/supplier_order_item.dart';
import '../../../../../shared/models/paginated_state.dart';

part 'supplier_orders_providers.g.dart';

@riverpod
SupplierOrdersRepository supplierOrdersRepository(Ref ref) {
  return SupabaseSupplierOrdersRepository(Supabase.instance.client);
}

Future<List<SupplierOrder>> _enrichOrdersWithValidation(
  Ref ref,
  List<SupplierOrder> orders,
) async {
  if (orders.isEmpty) return orders;

  final activeOrders = orders.where((o) => o.canShowAlerts).toList();
  if (activeOrders.isEmpty) return orders;

  final stockIds = <String>{};
  for (final order in activeOrders) {
    if (order.items != null) {
      for (final item in order.items!) {
        if (item.supplierBranchStockId != null) {
          stockIds.add(item.supplierBranchStockId!);
        }
      }
    }
  }

  if (stockIds.isEmpty) return orders;

  final stockMap = await ref
      .read(supplierOrdersRepositoryProvider)
      .validateSupplierOrderItems(stockIds: stockIds.toList());

  return orders.map((order) {
    if (!order.canShowAlerts || order.items == null || order.items!.isEmpty) {
      return order;
    }

    bool hasPriceIncrease = false;
    StockStatus stockStatus = StockStatus.available;

    for (final item in order.items!) {
      if (item.supplierBranchStockId == null) continue;
      final currentData = stockMap[item.supplierBranchStockId];
      if (currentData == null) continue;

      if (currentData.price > (item.unitPrice + 0.01)) {
        hasPriceIncrease = true;
      }

      if (currentData.quantity <= 0) {
        stockStatus = StockStatus.unavailable;
      } else if (currentData.quantity < item.quantity) {
        if (stockStatus != StockStatus.unavailable) {
          stockStatus = StockStatus.lowStock;
        }
      }
    }

    return SupplierOrder(
      id: order.id,
      userId: order.userId,
      supplierId: order.supplierId,
      supplierBranchId: order.supplierBranchId,
      shippingMethodId: order.shippingMethodId,
      receiverCollaboratorId: order.receiverCollaboratorId,
      orderNumber: order.orderNumber,
      date: order.date,
      paymentMethod: order.paymentMethod,
      status: order.status,
      subtotal: order.subtotal,
      tax: order.tax,
      total: order.total,
      invoicePhotoUrl: order.invoicePhotoUrl,
      isArchived: order.isArchived,
      verificationStatus: order.verificationStatus,
      createdAt: order.createdAt,
      updatedAt: order.updatedAt,
      supplierName: order.supplierName,
      branchName: order.branchName,
      shippingMethodLabel: order.shippingMethodLabel,
      receiverName: order.receiverName,
      items: order.items,
      stockStatus: stockStatus,
      hasPriceIncrease: hasPriceIncrease,
    );
  }).toList();
}

@riverpod
class PaginatedSupplierOrders extends _$PaginatedSupplierOrders {
  String? _searchQuery;
  String? _statusFilter;
  bool _includeArchived = false;

  RealtimeChannel? _realtimeChannel;

  @override
  FutureOr<PaginatedState<SupplierOrder>> build() async {
    _initRealtimeSubscription();
    return _fetchPage(0);
  }

  void _initRealtimeSubscription() {
    if (_realtimeChannel != null) return;

    final channel = Supabase.instance.client
        .channel('public:supplier_orders_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'supplier_orders',
          callback: (payload) {
            final updatedRecord = payload.newRecord;
            final updatedId = updatedRecord['id'] as String?;
            if (updatedId != null) {
              ref.invalidate(supplierOrderDetailProvider(updatedId));
            }
            refresh();
          },
        )
        .subscribe();

    _realtimeChannel = channel;

    ref.onDispose(() {
      _realtimeChannel?.unsubscribe();
      _realtimeChannel = null;
    });
  }

  Future<PaginatedState<SupplierOrder>> _fetchPage(int offset) async {
    final rawItems = await ref.read(supplierOrdersRepositoryProvider).getSupplierOrdersPaginated(
      offset: offset,
      limit: PaginatedState.pageSize,
      searchQuery: _searchQuery,
      statusFilter: _statusFilter,
      includeArchived: _includeArchived,
    );
    final items = await _enrichOrdersWithValidation(ref, rawItems);
    return PaginatedState(
      items: items,
      currentOffset: offset,
      hasReachedEnd: items.length < PaginatedState.pageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || current.hasReachedEnd) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final newPage = await _fetchPage(current.nextOffset);
      state = AsyncData(current.copyWith(
        items: [...current.items, ...newPage.items],
        currentOffset: newPage.currentOffset,
        hasReachedEnd: newPage.hasReachedEnd,
        isLoadingMore: false,
      ));
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false, error: e));
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(0));
  }

  void updateSearch(String? query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    refresh();
  }

  void updateFilters({String? status}) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    refresh();
  }

  void updateIncludeArchived(bool include) {
    if (_includeArchived == include) return;
    _includeArchived = include;
    refresh();
  }

  Future<void> archiveSupplierOrder(String id, {required bool archive}) async {
    await ref.read(supplierOrdersRepositoryProvider).archiveSupplierOrder(id, archive);
    await refresh();
  }

  Future<void> updateSupplierOrderStatus(String id, String status) async {
    await ref.read(supplierOrdersRepositoryProvider).updateSupplierOrderStatus(id, status);
    await refresh();
  }

  Future<String?> finalizeSupplierOrder({
    required String orderId,
    required String documentNumber,
    required String documentType,
    required dynamic photoFile, // Dynamic or File type. Let's import File from dart:io or use dynamic.
    required bool createPurchaseRecord,
  }) async {
    final purchaseId = await ref.read(supplierOrdersRepositoryProvider).finalizeSupplierOrder(
      orderId: orderId,
      photoFile: photoFile,
      documentType: documentType,
      documentNumber: documentNumber,
      createPurchaseRecord: createPurchaseRecord,
    );
    refresh();
    return purchaseId;
  }

  Future<void> batchArchiveSupplierOrders(List<String> ids, {required bool archive}) async {
    final repo = ref.read(supplierOrdersRepositoryProvider);
    for (final id in ids) {
      await repo.archiveSupplierOrder(id, archive);
    }
    await refresh();
  }

  Future<void> batchUpdateSupplierOrderStatus(List<String> ids, String status) async {
    final repo = ref.read(supplierOrdersRepositoryProvider);
    for (final id in ids) {
      await repo.updateSupplierOrderStatus(id, status);
    }
    await refresh();
  }
}

// --- Paginated Supplier Order Search (AutoDispose) ---
final paginatedSupplierOrderSearchProvider =
    AutoDisposeAsyncNotifierProvider<PaginatedSupplierOrderSearch, PaginatedState<SupplierOrder>>(
  () => PaginatedSupplierOrderSearch(),
);

class PaginatedSupplierOrderSearch extends AutoDisposeAsyncNotifier<PaginatedState<SupplierOrder>> {
  String? _searchQuery;
  String? _statusFilter;
  bool _includeArchived = false;

  @override
  FutureOr<PaginatedState<SupplierOrder>> build() async {
    return _fetchPage(0);
  }

  Future<PaginatedState<SupplierOrder>> _fetchPage(int offset) async {
    final rawItems = await ref.read(supplierOrdersRepositoryProvider).getSupplierOrdersPaginated(
      offset: offset,
      limit: PaginatedState.pageSize,
      searchQuery: _searchQuery,
      statusFilter: _statusFilter,
      includeArchived: _includeArchived,
    );
    final items = await _enrichOrdersWithValidation(ref, rawItems);
    return PaginatedState(
      items: items,
      currentOffset: offset,
      hasReachedEnd: items.length < PaginatedState.pageSize,
    );
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.isLoadingMore || current.hasReachedEnd) return;

    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final newPage = await _fetchPage(current.nextOffset);
      state = AsyncData(current.copyWith(
        items: [...current.items, ...newPage.items],
        currentOffset: newPage.currentOffset,
        hasReachedEnd: newPage.hasReachedEnd,
        isLoadingMore: false,
      ));
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

  void updateFilters({String? status}) {
    if (_statusFilter == status) return;
    _statusFilter = status;
    refresh();
  }

  void updateIncludeArchived(bool include) {
    if (_includeArchived == include) return;
    _includeArchived = include;
    refresh();
  }
}

@riverpod
Future<({SupplierOrder order, List<SupplierOrderItem> items})> supplierOrderDetail(
  Ref ref,
  String id,
) {
  return ref.read(supplierOrdersRepositoryProvider).getSupplierOrderDetails(id);
}

@riverpod
Future<List<Map<String, dynamic>>> supplierBranches(Ref ref, String supplierId) async {
  final response = await Supabase.instance.client
      .from('supplier_branches')
      .select('id, name')
      .eq('supplier_id', supplierId);
  return List<Map<String, dynamic>>.from(response);
}

@riverpod
Future<Map<String, dynamic>?> supplierBranchContactInfo(
  Ref ref,
  String branchId,
) async {
  final response = await Supabase.instance.client
      .from('supplier_branches')
      .select('id, email, phone')
      .eq('id', branchId)
      .maybeSingle();
  return response;
}

@riverpod
Future<List<SupplierOrder>> mergedChildOrders(
  Ref ref,
  String parentOrderId,
) async {
  final repo = ref.watch(supplierOrdersRepositoryProvider);
  return repo.getMergedChildOrders(parentOrderId);
}

@riverpod
Future<SupplierOrder?> parentSupplierOrder(
  Ref ref,
  String? parentOrderId,
) async {
  if (parentOrderId == null || parentOrderId.isEmpty) return null;
  final repo = ref.watch(supplierOrdersRepositoryProvider);
  return repo.getParentSupplierOrder(parentOrderId);
}

@riverpod
Future<Map<String, dynamic>?> linkedPurchase(
  Ref ref,
  String orderId,
) async {
  final repo = ref.watch(supplierOrdersRepositoryProvider);
  return repo.getLinkedPurchase(orderId);
}


