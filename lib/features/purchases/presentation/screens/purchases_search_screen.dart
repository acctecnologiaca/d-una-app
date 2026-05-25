import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:d_una_app/shared/widgets/generic_search_screen.dart';
import 'package:d_una_app/shared/widgets/filter_bottom_sheet.dart';
import 'package:d_una_app/shared/widgets/horizontal_filter_bar.dart';
import 'package:d_una_app/features/purchases/presentation/providers/purchases_providers.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/suppliers_provider.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';

import '../widgets/purchase_list_item.dart';
import '../../domain/models/purchase_model.dart';

class PurchasesSearchScreen extends ConsumerStatefulWidget {
  final bool selectionMode;

  const PurchasesSearchScreen({
    super.key,
    this.selectionMode = false,
  });

  @override
  ConsumerState<PurchasesSearchScreen> createState() =>
      _PurchasesSearchScreenState();
}

class _PurchasesSearchScreenState extends ConsumerState<PurchasesSearchScreen> {
  // Filtros
  final Set<String> _selectedSupplierNames = {};
  final Set<String> _selectedTypes = {}; // 'invoice', 'delivery_note'
  DateTimeRange? _dateRange;
  bool _missingSerialsOnly = false;

  String _getChipLabel(Set<String> selected, String defaultLabel) {
    if (selected.isEmpty) return defaultLabel;
    if (selected.length == 1) {
      if (defaultLabel == 'Tipo') {
        return selected.first == 'invoice' ? 'Factura' : 'Nota de Entrega';
      }
      return selected.first;
    }
    return '$defaultLabel +${selected.length}';
  }

  void _showSupplierFilter() async {
    final affiliatedSuppliers = await ref.read(suppliersProvider.future);
    final unaffiliatedSuppliers = await ref.read(allSuppliersProvider.future);
    final currentPurchases =
        ref.read(paginatedPurchaseSearchProvider).valueOrNull?.items ?? [];

    Set<String> availableOptions = {};
    availableOptions.addAll(affiliatedSuppliers.map((s) => s.name));
    availableOptions.addAll(unaffiliatedSuppliers.map((s) => s.legalName ?? s.name));
    
    // Ensure all valid supplier names from the current purchases are ALWAYS included 
    // (this guarantees that if the repository resolves a name differently, we still show it)
    final validSupplierNames = currentPurchases
        .map((p) => p.supplierName)
        .whereType<String>()
        .toSet();
        
    availableOptions.addAll(validSupplierNames);

    if (currentPurchases.isNotEmpty) {
      final validSupplierNames =
          currentPurchases
              .map((p) => p.supplierName)
              .whereType<String>()
              .toSet();
      availableOptions = availableOptions.where(
        (name) =>
            validSupplierNames.contains(name) ||
            _selectedSupplierNames.contains(name),
      ).toSet();
    }

    if (!mounted) return;

    final options = availableOptions.toSet().toList()..sort();

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Proveedor',
      options: options,
      selectedValues: _selectedSupplierNames,
      onApply: (selected) {
        setState(() {
          _selectedSupplierNames.clear();
          _selectedSupplierNames.addAll(selected);
        });
      },
    );
  }

  void _showTypeFilter() {
    final allOptions = {'invoice': 'Factura', 'delivery_note': 'Nota de Entrega'};
    final currentPurchases =
        ref.read(paginatedPurchaseSearchProvider).valueOrNull?.items ?? [];

    Map<String, String> availableOptions = Map.from(allOptions);

    if (currentPurchases.isNotEmpty) {
      final validTypes = currentPurchases.map((p) => p.documentType).toSet();
      availableOptions.removeWhere(
        (key, value) =>
            !validTypes.contains(key) && !_selectedTypes.contains(key),
      );
    }

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Tipo de documento',
      options: availableOptions.values.toList(),
      selectedValues: _selectedTypes.map((t) => allOptions[t]!).toSet(),
      onApply: (selectedValues) {
        setState(() {
          _selectedTypes.clear();
          for (var label in selectedValues) {
            final key =
                allOptions.entries.firstWhere((e) => e.value == label).key;
            _selectedTypes.add(key);
          }
        });
      },
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      initialDateRange: _dateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
              onPrimary: Theme.of(context).colorScheme.onPrimary,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginatedAsync = ref.watch(paginatedPurchaseSearchProvider);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return GenericSearchScreen<Purchase>(
      title: widget.selectionMode ? 'Seleccionar compra' : 'Buscar compra',
      hintText: 'Proveedor o número...',
      historyKey: 'purchases_search_history',
      isPaginatedMode: true,
      paginatedDataAsync: paginatedAsync,
      showHistory: !widget.selectionMode,
      onResetFilters: () {
        setState(() {
          _selectedSupplierNames.clear();
          _selectedTypes.clear();
          _dateRange = null;
          _missingSerialsOnly = false;
        });
        ref.read(paginatedPurchaseSearchProvider.notifier).updateSearch(null);
      },
      onServerSearch: (query) {
        ref.read(paginatedPurchaseSearchProvider.notifier).updateSearch(query);
      },
      onLoadMore: () {
        ref.read(paginatedPurchaseSearchProvider.notifier).loadMore();
      },
      onQueryChanged: (query) {
        // Handled by onServerSearch
      },
      itemBuilder: (context, purchase) {
        return PurchaseListItem(
          purchase: purchase,
          onTap: () {
            if (widget.selectionMode) {
              Navigator.of(context).pop(purchase);
            } else {
              context.push('/my-purchases/view/${purchase.id}');
            }
          },
        );
      },
      filters: [
        FilterChipData(
          label: _getChipLabel(_selectedSupplierNames, 'Proveedor'),
          isActive: _selectedSupplierNames.isNotEmpty,
          onTap: _showSupplierFilter,
        ),
        FilterChipData(
          label: _getChipLabel(_selectedTypes, 'Tipo'),
          isActive: _selectedTypes.isNotEmpty,
          onTap: _showTypeFilter,
        ),
        FilterChipData(
          label: _dateRange == null
              ? 'Fecha'
              : '${dateFormat.format(_dateRange!.start)} - ${dateFormat.format(_dateRange!.end)}',
          isActive: _dateRange != null,
          onTap: _selectDateRange,
        ),
        FilterChipData(
          label: 'Sin seriales',
          isActive: _missingSerialsOnly,
          onTap: () =>
              setState(() => _missingSerialsOnly = !_missingSerialsOnly),
        ),
      ],
      filter: (purchase, query) {
        if (_selectedSupplierNames.isNotEmpty &&
            !_selectedSupplierNames.contains(purchase.supplierName)) {
          return false;
        }

        if (_selectedTypes.isNotEmpty) {
          final options = {'invoice': 'Factura', 'delivery_note': 'Nota de Entrega'};
          final mappedTypes = _selectedTypes.map((t) => options[t]).toSet();
          final purchaseTypeMapped = options[purchase.documentType];
          
          if (!mappedTypes.contains(purchaseTypeMapped) && !_selectedTypes.contains(purchase.documentType)) {
             return false;
          }
        }

        if (_dateRange != null) {
          final start = DateTime(_dateRange!.start.year, _dateRange!.start.month, _dateRange!.start.day);
          final end = DateTime(_dateRange!.end.year, _dateRange!.end.month, _dateRange!.end.day, 23, 59, 59);
          if (purchase.date.isBefore(start) || purchase.date.isAfter(end)) {
            return false;
          }
        }

        if (_missingSerialsOnly && !purchase.hasMissingSerials) {
          return false;
        }

        return true;
      },
    );
  }
}
