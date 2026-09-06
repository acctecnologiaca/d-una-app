import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:d_una_app/shared/widgets/generic_search_screen.dart';
import 'package:d_una_app/shared/widgets/filter_bottom_sheet.dart';
import 'package:d_una_app/shared/widgets/horizontal_filter_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import '../../../domain/models/delivery_note_model.dart';
import '../../../domain/models/delivery_note_status.dart';
import '../providers/delivery_notes_providers.dart';
import '../widgets/delivery_note_card.dart';

class DeliveryNotesSearchScreen extends ConsumerStatefulWidget {
  final String? initialQuery;

  const DeliveryNotesSearchScreen({super.key, this.initialQuery});

  @override
  ConsumerState<DeliveryNotesSearchScreen> createState() =>
      _DeliveryNotesSearchScreenState();
}

class _DeliveryNotesSearchScreenState
    extends ConsumerState<DeliveryNotesSearchScreen> {
  final Set<String> _selectedStatuses = {};
  DateTimeRange? _dateRange;
  SortOption _currentSort = SortOption.recent;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      Future.microtask(() {
        ref
            .read(paginatedDeliveryNotesProvider.notifier)
            .setSearchQuery(widget.initialQuery);
      });
    }
  }

  String _getStatusChipLabel() {
    if (_selectedStatuses.isEmpty) return 'Estatus';
    if (_selectedStatuses.length == 1) {
      final status = DeliveryNoteStatus.values
          .where((s) => s.dbValue == _selectedStatuses.first)
          .firstOrNull;
      return status?.label ?? _selectedStatuses.first;
    }
    return 'Estatus +${_selectedStatuses.length}';
  }

  void _showStatusFilter() {
    final statusMap = {
      for (final s in DeliveryNoteStatus.values) s.label: s.dbValue,
    };
    final options = DeliveryNoteStatus.values.map((s) => s.label).toList();

    final selectedLabels = _selectedStatuses
        .map((val) {
          return DeliveryNoteStatus.values
              .where((s) => s.dbValue == val)
              .firstOrNull
              ?.label;
        })
        .whereType<String>()
        .toSet();

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Estatus',
      options: options,
      selectedValues: selectedLabels,
      sortOptions: false,
      onApply: (selected) {
        setState(() {
          _selectedStatuses.clear();
          for (final label in selected) {
            final val = statusMap[label];
            if (val != null) _selectedStatuses.add(val);
          }
        });
      },
    );
  }

  Future<void> _showDateFilter() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
    );

    if (picked != null) {
      setState(() {
        _dateRange = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginatedAsync = ref.watch(paginatedDeliveryNotesProvider);
    final dateFormat = DateFormat('dd/MM/yy');

    return GenericSearchScreen<DeliveryNoteModel>(
      title: 'Buscar notas de entrega',
      hintText: 'Buscar por cliente, número, notas...',
      historyKey: 'delivery_notes_search_history',
      initialQuery: widget.initialQuery,
      isPaginatedMode: true,
      paginatedDataAsync: paginatedAsync,
      onServerSearch: (query) {
        ref.read(paginatedDeliveryNotesProvider.notifier).setSearchQuery(query);
      },
      onLoadMore: () {
        ref.read(paginatedDeliveryNotesProvider.notifier).loadMore();
      },
      bottomFilterWidget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            SortSelector(
              currentSort: _currentSort,
              onSortChanged: (val) {
                setState(() => _currentSort = val);
                ref
                    .read(paginatedDeliveryNotesProvider.notifier)
                    .setSortOption(val);
              },
              options: const [
                SortOption.recent,
                SortOption.oldest,
                SortOption.nameAZ,
                SortOption.nameZA,
                SortOption.orderNumberDesc,
                SortOption.orderNumberAsc,
              ],
            ),
          ],
        ),
      ),
      filters: [
        FilterChipData(
          label: _getStatusChipLabel(),
          isActive: _selectedStatuses.isNotEmpty,
          onTap: _showStatusFilter,
        ),
        FilterChipData(
          label: _dateRange == null
              ? 'Fecha'
              : '${dateFormat.format(_dateRange!.start)} - ${dateFormat.format(_dateRange!.end)}',
          isActive: _dateRange != null,
          onTap: _showDateFilter,
        ),
      ],
      filter: (note, query) {
        // Status filter
        if (_selectedStatuses.isNotEmpty &&
            !_selectedStatuses.contains(note.status.dbValue)) {
          return false;
        }

        // Date range filter
        if (_dateRange != null) {
          final noteDate = note.date;
          if (noteDate.isBefore(_dateRange!.start) ||
              noteDate.isAfter(_dateRange!.end.add(const Duration(days: 1)))) {
            return false;
          }
        }

        return true;
      },
      itemBuilder: (context, note) {
        return DeliveryNoteCard(
          note: note,
          onTap: () {
            context.push('/delivery-notes/view/${note.id}');
          },
        );
      },
    );
  }
}
