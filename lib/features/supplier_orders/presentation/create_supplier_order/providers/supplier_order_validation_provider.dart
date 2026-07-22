import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../supplier_orders_list/providers/supplier_orders_providers.dart';
import '../../../domain/repositories/supplier_orders_repository.dart';
import '../../../domain/models/supplier_order_item.dart';

enum SupplierOrderValidationStatus { ok, lowStock, outOfStock, priceIncreased, missing }

class SupplierOrderValidationItem {
  final Set<SupplierOrderValidationStatus> statuses;
  final double currentStock;
  final double currentCost;

  SupplierOrderValidationItem({
    required this.statuses,
    required this.currentStock,
    required this.currentCost,
  });

  bool get isOk => statuses.isEmpty;
}

class SupplierOrderValidationState {
  final Map<String, SupplierOrderValidationItem> items;
  final bool isValidating;

  SupplierOrderValidationState({this.items = const {}, this.isValidating = false});

  SupplierOrderValidationState copyWith({
    Map<String, SupplierOrderValidationItem>? items,
    bool? isValidating,
  }) {
    return SupplierOrderValidationState(
      items: items ?? this.items,
      isValidating: isValidating ?? this.isValidating,
    );
  }
}

class SupplierOrderValidationNotifier extends StateNotifier<SupplierOrderValidationState> {
  final SupplierOrdersRepository _repository;
  final List<SupplierOrderItem> _orderItems;

  SupplierOrderValidationNotifier(this._repository, this._orderItems)
      : super(SupplierOrderValidationState()) {
    validate();
  }

  Future<void> validate() async {
    if (_orderItems.isEmpty) {
      state = state.copyWith(items: {}, isValidating: false);
      return;
    }

    state = state.copyWith(isValidating: true);

    try {
      final stockIds = _orderItems
          .map((i) => i.supplierBranchStockId)
          .whereType<String>()
          .toList();

      final stockMap = await _repository.validateSupplierOrderItems(stockIds: stockIds);
      final Map<String, SupplierOrderValidationItem> newMap = {};

      for (final item in _orderItems) {
        if (item.supplierBranchStockId == null) {
          newMap[item.id] = SupplierOrderValidationItem(
            statuses: {},
            currentStock: 999999,
            currentCost: item.unitPrice,
          );
          continue;
        }

        final currentData = stockMap[item.supplierBranchStockId];
        if (currentData == null) {
          newMap[item.id] = SupplierOrderValidationItem(
            statuses: {SupplierOrderValidationStatus.missing},
            currentStock: 0,
            currentCost: 0,
          );
          continue;
        }

        final Set<SupplierOrderValidationStatus> statuses = {};

        if (currentData.quantity <= 0) {
          statuses.add(SupplierOrderValidationStatus.outOfStock);
        } else if (currentData.quantity < item.quantity) {
          statuses.add(SupplierOrderValidationStatus.lowStock);
        }

        if (currentData.price > (item.unitPrice + 0.01)) {
          statuses.add(SupplierOrderValidationStatus.priceIncreased);
        }

        newMap[item.id] = SupplierOrderValidationItem(
          statuses: statuses,
          currentStock: currentData.quantity,
          currentCost: currentData.price,
        );
      }

      state = state.copyWith(items: newMap, isValidating: false);
    } catch (e) {
      debugPrint('Error validating supplier order items: $e');
      state = state.copyWith(isValidating: false);
    }
  }
}

final supplierOrderValidationProvider = StateNotifierProvider.autoDispose
    .family<SupplierOrderValidationNotifier, SupplierOrderValidationState, List<SupplierOrderItem>>((
  ref,
  items,
) {
  final repository = ref.watch(supplierOrdersRepositoryProvider);
  return SupplierOrderValidationNotifier(repository, items);
});
