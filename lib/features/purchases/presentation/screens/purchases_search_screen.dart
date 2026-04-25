import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:d_una_app/shared/widgets/generic_search_screen.dart';
import 'package:d_una_app/shared/widgets/filter_bottom_sheet.dart';
import 'package:d_una_app/shared/widgets/horizontal_filter_bar.dart';
import 'package:d_una_app/features/purchases/presentation/providers/purchases_providers.dart';
import 'package:d_una_app/core/utils/search_utils.dart';
import '../widgets/purchase_list_item.dart';
import '../../domain/models/purchase_model.dart';

class PurchasesSearchScreen extends ConsumerStatefulWidget {
  const PurchasesSearchScreen({super.key});

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

  void _showSupplierFilter(List<Purchase> purchases) {
    final options =
        purchases
            .map((e) => e.supplierName)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();

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
    final options = {'invoice': 'Factura', 'delivery_note': 'Nota de Entrega'};

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Tipo de documento',
      options: options.values.toList(),
      selectedValues: _selectedTypes.map((t) => options[t]!).toSet(),
      onApply: (selectedValues) {
        setState(() {
          _selectedTypes.clear();
          for (var label in selectedValues) {
            final key = options.entries.firstWhere((e) => e.value == label).key;
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
    final purchasesAsync = ref.watch(purchasesProvider(null));
    final dateFormat = DateFormat('dd/MM/yyyy');

    return GenericSearchScreen<Purchase>(
      title: 'Buscar compra',
      hintText: 'Proveedor o número...',
      historyKey: 'purchases_search_history',
      data: purchasesAsync,
      onResetFilters: () {
        setState(() {
          _selectedSupplierNames.clear();
          _selectedTypes.clear();
          _dateRange = null;
          _missingSerialsOnly = false;
        });
      },
      itemBuilder: (context, purchase) {
        return PurchaseListItem(
          purchase: purchase,
          onTap: () {
            context.push('/my-purchases/view/${purchase.id}');
          },
        );
      },
      filters: [
        FilterChipData(
          label: _getChipLabel(_selectedSupplierNames, 'Proveedor'),
          isActive: _selectedSupplierNames.isNotEmpty,
          onTap: () {
            purchasesAsync.whenData(
              (purchases) => _showSupplierFilter(purchases),
            );
          },
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
        final matchesText = SearchUtils.matchesCombo(query, [
          purchase.supplierName,
          purchase.documentNumber,
        ]);

        final matchesSupplier =
            _selectedSupplierNames.isEmpty ||
            _selectedSupplierNames.contains(purchase.supplierName);

        final matchesType =
            _selectedTypes.isEmpty ||
            _selectedTypes.contains(purchase.documentType);

        final matchesDate =
            _dateRange == null ||
            (purchase.date.isAfter(
                  _dateRange!.start.subtract(const Duration(seconds: 1)),
                ) &&
                purchase.date.isBefore(
                  _dateRange!.end.add(const Duration(days: 1)),
                ));

        final matchesMissingSerials =
            !_missingSerialsOnly || purchase.hasMissingSerials;

        return matchesText &&
            matchesSupplier &&
            matchesType &&
            matchesDate &&
            matchesMissingSerials;
      },
    );
  }
}
