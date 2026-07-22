import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:d_una_app/shared/widgets/generic_search_screen.dart';
import 'package:d_una_app/shared/widgets/filter_bottom_sheet.dart';
import 'package:d_una_app/shared/widgets/horizontal_filter_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/supplier_orders_providers.dart';
import '../providers/supplier_orders_selection_provider.dart';
import '../supplier_order_selection_actions.dart';
import '../../../domain/models/supplier_order.dart';
import '../../../domain/models/supplier_order_status.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/suppliers_provider.dart';
import 'package:d_una_app/features/portfolio/domain/models/supplier_model.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import '../widgets/supplier_order_card.dart';

/// Search screen for supplier orders.
///
/// Uses [GenericSearchScreen] in paginated mode with filter chips for
/// supplier, status, and date range. Includes a [SortSelector] for
/// "Más reciente", "Nombre (A-Z)", and "Nombre (Z-A)".
class SupplierOrdersSearchScreen extends ConsumerStatefulWidget {
  const SupplierOrdersSearchScreen({super.key});

  @override
  ConsumerState<SupplierOrdersSearchScreen> createState() =>
      _SupplierOrdersSearchScreenState();
}

class _SupplierOrdersSearchScreenState
    extends ConsumerState<SupplierOrdersSearchScreen> {
  // Filter state
  final Set<String> _selectedSupplierNames = {};
  final Set<String> _selectedStatuses = {};
  DateTimeRange? _dateRange;

  // Sort state
  SortOption _currentSort = SortOption.recent;

  @override
  void dispose() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) return;
      ref.read(supplierOrderSelectionProvider.notifier).clearSelection();
    });
    super.dispose();
  }

  /// Returns a formatted chip label based on selected values.
  String _getChipLabel(Set<String> selected, String defaultLabel) {
    if (selected.isEmpty) return defaultLabel;
    if (selected.length == 1) return selected.first;
    return '$defaultLabel +${selected.length}';
  }

  /// Shows the supplier filter bottom sheet with all registered suppliers.
  void _showSupplierFilter(
    List<Supplier> selectableSuppliers,
    List<SupplierOrder> currentOrders,
    Map<String, String> nameToFormattedMap,
  ) {
    Set<String> availableOptions = {};

    // Add active suppliers
    for (final s in selectableSuppliers) {
      availableOptions.add(s.name);
    }

    // Include supplier names from current orders mapped correctly
    for (final o in currentOrders) {
      if (o.supplierName != 'Desconocido') {
        final mappedName = nameToFormattedMap[o.supplierName] ?? o.supplierName;
        availableOptions.add(mappedName);
      }
    }

    final options = availableOptions.toList()..sort();

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

  Widget _buildStatusLeading(String statusLabel, ColorScheme colors) {
    final status = SupplierOrderStatus.values
        .where((s) => s.label == statusLabel)
        .firstOrNull;

    if (status != null) {
      return Image.asset(status.iconPath, width: 24, height: 24);
    }

    if (statusLabel == 'Archivada') {
      return Icon(
        Icons.archive_outlined,
        size: 24,
        color: colors.onSurfaceVariant,
      );
    }

    return CircleAvatar(
      radius: 12,
      backgroundColor: colors.secondaryContainer,
      child: Text(
        statusLabel.isNotEmpty ? statusLabel[0].toUpperCase() : '?',
        style: TextStyle(color: colors.onSecondaryContainer, fontSize: 12),
      ),
    );
  }

  /// Shows the status filter bottom sheet with all possible order statuses.
  void _showStatusFilter() {
    final allStatuses = {
      for (final s in SupplierOrderStatus.values) s.dbValue: s.label,
    };
    allStatuses['archived'] = 'Archivada';

    final orderedLabels = [
      'Borrador',
      'Enviada',
      'Reenviada',
      'Finalizada',
      'Cancelada',
      'Archivada',
    ];

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Estatus',
      options: orderedLabels,
      selectedValues: _selectedStatuses
          .map((s) => allStatuses[s] ?? s)
          .where((label) => label.isNotEmpty)
          .toSet(),
      leadingBuilder: (value) =>
          _buildStatusLeading(value, Theme.of(context).colorScheme),
      sortOptions: false,
      onApply: (selectedLabels) {
        setState(() {
          _selectedStatuses.clear();
          for (final label in selectedLabels) {
            final key = allStatuses.entries
                .firstWhere((e) => e.value == label)
                .key;
            _selectedStatuses.add(key);
          }
        });
        final wantsArchived = _selectedStatuses.contains('archived');
        ref
            .read(paginatedSupplierOrderSearchProvider.notifier)
            .updateIncludeArchived(wantsArchived);
      },
    );
  }

  /// Shows the date range picker for filtering by date.
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

  /// Returns a comparator function based on the current sort option.
  int Function(SupplierOrder a, SupplierOrder b)? _getComparator() {
    switch (_currentSort) {
      case SortOption.recent:
        return (a, b) => b.date.compareTo(a.date);
      case SortOption.nameAZ:
        return (a, b) => a.supplierName.toLowerCase().compareTo(
          b.supplierName.toLowerCase(),
        );
      case SortOption.nameZA:
        return (a, b) => b.supplierName.toLowerCase().compareTo(
          a.supplierName.toLowerCase(),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginatedAsync = ref.watch(paginatedSupplierOrderSearchProvider);
    final suppliersAsync = ref.watch(suppliersProvider);
    final userProfile = ref.watch(userProfileProvider).valueOrNull;
    final selection = ref.watch(supplierOrderSelectionProvider);
    final dateFormat = DateFormat('dd/MM/yyyy');

    final suppliers = suppliersAsync.valueOrNull ?? [];
    final allOrders = paginatedAsync.valueOrNull?.items ?? [];
    final selectedOrders = allOrders
        .where((o) => selection.selectedIds.contains(o.id))
        .toList();

    final canSendBatch =
        selection.count > 0 &&
        selection.count <= 3 &&
        selectedOrders.every(
          (o) =>
              o.status != SupplierOrderStatus.finalized &&
              o.status != SupplierOrderStatus.cancelled,
        );

    final isSingleResend = selectedOrders.length == 1 &&
        (selectedOrders.first.status == SupplierOrderStatus.sent ||
            selectedOrders.first.status == SupplierOrderStatus.resent);

    final isAllArchived = selectedOrders.isNotEmpty &&
        selectedOrders.every((o) => o.isArchived);

    // Filter out suppliers that are locked for this user profile context
    final selectableSuppliers = suppliers.where((s) {
      final isVerified = userProfile?.verificationStatus == 'verified';
      final isBusiness = userProfile?.verificationType == 'business';

      if (!isVerified) {
        // Unverified: Block all Wholesale suppliers
        return s.tradeType != 'WHOLESALE';
      } else {
        // Verified Individual: Block Wholesale suppliers unless they explicitly accept individual
        if (!isBusiness && s.tradeType == 'WHOLESALE') {
          return s.allowedVerificationTypes.contains('individual');
        }
      }
      return true;
    }).toList();

    // Map names to commercial name to handle legacy orders with legalName
    final Map<String, String> nameToFormattedMap = {};
    for (final s in selectableSuppliers) {
      nameToFormattedMap[s.name] = s.name;
      if (s.legalName != null && s.legalName!.isNotEmpty) {
        nameToFormattedMap[s.legalName!] = s.name;
      }
    }

    // Build status chip label with translated values
    String statusChipLabel = 'Estatus';
    if (_selectedStatuses.isNotEmpty) {
      final allStatuses = {
        for (final s in SupplierOrderStatus.values) s.dbValue: s.label,
      };
      allStatuses['archived'] = 'Archivada';
      final selectedLabels = _selectedStatuses
          .map((s) => allStatuses[s] ?? s)
          .toSet();
      statusChipLabel = _getChipLabel(selectedLabels, 'Estatus');
    }

    return GenericSearchScreen<SupplierOrder>(
      title: 'Buscar orden',
      hintText: 'Proveedor o número...',
      historyKey: 'supplier_orders_search_history',
      isPaginatedMode: true,
      paginatedDataAsync: paginatedAsync,
      appBarOverride: selection.isSelectionMode
          ? _buildSelectionHeader(
              context,
              ref,
              selection,
              canSendBatch,
              isSingleResend,
              isAllArchived,
            )
          : null,
      onResetFilters: () {
        setState(() {
          _selectedSupplierNames.clear();
          _selectedStatuses.clear();
          _dateRange = null;
          _currentSort = SortOption.recent;
        });
        ref
            .read(paginatedSupplierOrderSearchProvider.notifier)
            .updateSearch(null);
        ref
            .read(paginatedSupplierOrderSearchProvider.notifier)
            .updateIncludeArchived(false);
      },
      onServerSearch: (query) {
        ref
            .read(paginatedSupplierOrderSearchProvider.notifier)
            .updateSearch(query);
      },
      onLoadMore: () {
        ref.read(paginatedSupplierOrderSearchProvider.notifier).loadMore();
      },
      onQueryChanged: (query) {
        // Handled by onServerSearch debounce
      },
      bottomFilterWidget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            SortSelector(
              currentSort: _currentSort,
              onSortChanged: (val) {
                setState(() => _currentSort = val);
              },
              options: const [
                SortOption.recent,
                SortOption.nameAZ,
                SortOption.nameZA,
              ],
            ),
          ],
        ),
      ),
      itemBuilder: (context, order) {
        return SupplierOrderCard(
          order: order,
          isSelectionMode: selection.isSelectionMode,
          isSelected: selection.isSelected(order.id),
          onLongPress: () =>
              ref.read(supplierOrderSelectionProvider.notifier).toggle(order.id),
          onTap: selection.isSelectionMode
              ? () => ref.read(supplierOrderSelectionProvider.notifier).toggle(order.id)
              : () {
                  context.push('/supplier-orders/view/${order.id}');
                },
        );
      },
      filters: [
        FilterChipData(
          label: _getChipLabel(_selectedSupplierNames, 'Proveedor'),
          isActive: _selectedSupplierNames.isNotEmpty,
          onTap: () {
            final currentOrders = paginatedAsync.valueOrNull?.items ?? [];
            _showSupplierFilter(
              selectableSuppliers,
              currentOrders,
              nameToFormattedMap,
            );
          },
        ),
        FilterChipData(
          label: statusChipLabel,
          isActive: _selectedStatuses.isNotEmpty,
          onTap: _showStatusFilter,
        ),
        FilterChipData(
          label: _dateRange == null
              ? 'Fecha'
              : '${dateFormat.format(_dateRange!.start)} - ${dateFormat.format(_dateRange!.end)}',
          isActive: _dateRange != null,
          onTap: _selectDateRange,
        ),
      ],
      filter: (order, query) {
        // Client-side supplier name filter
        if (_selectedSupplierNames.isNotEmpty) {
          final orderFormattedName =
              nameToFormattedMap[order.supplierName] ?? order.supplierName;
          if (!_selectedSupplierNames.contains(orderFormattedName)) {
            return false;
          }
        }

        // Client-side status filter
        if (_selectedStatuses.isNotEmpty) {
          final isMatched = _selectedStatuses.any((statusKey) {
            if (statusKey == 'archived') {
              return order.isArchived;
            }
            return order.status.dbValue == statusKey && !order.isArchived;
          });
          if (!isMatched) return false;
        } else {
          if (order.isArchived) return false;
        }

        // Client-side date range filter
        if (_dateRange != null) {
          final start = DateTime(
            _dateRange!.start.year,
            _dateRange!.start.month,
            _dateRange!.start.day,
          );
          final end = DateTime(
            _dateRange!.end.year,
            _dateRange!.end.month,
            _dateRange!.end.day,
            23,
            59,
            59,
          );
          if (order.date.isBefore(start) || order.date.isAfter(end)) {
            return false;
          }
        }

        return true;
      },
      comparator: _getComparator(),
    );
  }

  PreferredSizeWidget _buildSelectionHeader(
    BuildContext context,
    WidgetRef ref,
    SupplierOrderSelectionState selection,
    bool canSendBatch,
    bool isSingleResend,
    bool isAllArchived,
  ) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(kToolbarHeight),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => ref
                    .read(supplierOrderSelectionProvider.notifier)
                    .clearSelection(),
              ),
              Text(
                '${selection.count} Ítem${selection.count > 1 ? 's' : ''}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  isAllArchived ? Icons.unarchive_outlined : Icons.archive_outlined,
                ),
                tooltip: isAllArchived ? 'Desarchivar' : 'Archivar',
                onPressed: () => SupplierOrderSelectionActions.handleBatchArchive(
                  context,
                  ref,
                  selection,
                  archive: !isAllArchived,
                ),
              ),
              IconButton(
                icon: Icon(isSingleResend ? Symbols.forward : Icons.send),
                tooltip: isSingleResend ? 'Reenviar' : 'Enviar',
                onPressed: canSendBatch
                    ? () => SupplierOrderSelectionActions.handleBatchSend(
                        context,
                        ref,
                        selection,
                      )
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => SupplierOrderSelectionActions.showActionsSheet(
                  context,
                  ref,
                  selection,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
