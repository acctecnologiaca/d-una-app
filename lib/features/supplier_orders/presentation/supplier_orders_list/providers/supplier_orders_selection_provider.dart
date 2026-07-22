import 'package:flutter_riverpod/flutter_riverpod.dart';

class SupplierOrderSelectionState {
  final Set<String> selectedIds;
  final bool isSelectionMode;

  const SupplierOrderSelectionState({
    this.selectedIds = const {},
    this.isSelectionMode = false,
  });

  SupplierOrderSelectionState copyWith({
    Set<String>? selectedIds,
    bool? isSelectionMode,
  }) {
    return SupplierOrderSelectionState(
      selectedIds: selectedIds ?? this.selectedIds,
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
    );
  }

  int get count => selectedIds.length;
  bool get isSingle => count == 1;
  bool get isMultiple => count > 1;
  bool isSelected(String id) => selectedIds.contains(id);
}

class SupplierOrderSelectionNotifier extends StateNotifier<SupplierOrderSelectionState> {
  SupplierOrderSelectionNotifier() : super(const SupplierOrderSelectionState());

  void toggle(String id) {
    final updated = Set<String>.from(state.selectedIds);
    if (updated.contains(id)) {
      updated.remove(id);
    } else {
      updated.add(id);
    }
    state = state.copyWith(
      selectedIds: updated,
      isSelectionMode: updated.isNotEmpty,
    );
  }

  void selectAll(List<String> ids) {
    state = state.copyWith(selectedIds: ids.toSet(), isSelectionMode: true);
  }

  void clearSelection() {
    state = const SupplierOrderSelectionState();
  }
}

final supplierOrderSelectionProvider =
    StateNotifierProvider<SupplierOrderSelectionNotifier, SupplierOrderSelectionState>(
      (ref) => SupplierOrderSelectionNotifier(),
    );
