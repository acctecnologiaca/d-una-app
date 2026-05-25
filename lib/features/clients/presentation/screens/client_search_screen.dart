import 'package:d_una_app/shared/widgets/horizontal_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/clients_provider.dart';
import '../../data/models/client_model.dart';
import '../../../../shared/widgets/generic_search_screen.dart';
import '../../../../shared/widgets/filter_bottom_sheet.dart';
import '../../../../shared/widgets/sort_selector.dart';
import '../../../auth/presentation/providers/register_provider.dart';
import '../../../../shared/widgets/standard_list_item.dart';

class ClientSearchScreen extends ConsumerStatefulWidget {
  const ClientSearchScreen({super.key});

  @override
  ConsumerState<ClientSearchScreen> createState() => _ClientSearchScreenState();
}

class _ClientSearchScreenState extends ConsumerState<ClientSearchScreen> {
  String? _selectedFilterType; // null = All, 'company', 'person'
  final Set<String> _selectedFilterCities = {};
  SortOption _currentSort = SortOption.recent;

  String _getHistoryKey() {
    final user = ref.read(authRepositoryProvider).currentUser;
    return 'client_search_history_${user?.id ?? "guest"}';
  }

  @override
  Widget build(BuildContext context) {
    final paginatedAsync = ref.watch(paginatedClientSearchProvider);
    final colors = Theme.of(context).colorScheme;

    return GenericSearchScreen<Client>(
      hintText: 'Buscar cliente...',
      historyKey: _getHistoryKey(),
      isPaginatedMode: true,
      paginatedDataAsync: paginatedAsync,
      onServerSearch: (query) {
        ref.read(paginatedClientSearchProvider.notifier).updateSearch(query);
      },
      onLoadMore: () {
        ref.read(paginatedClientSearchProvider.notifier).loadMore();
      },
      onResetFilters: () {
        setState(() {
          _selectedFilterType = null;
          _selectedFilterCities.clear();
          _currentSort = SortOption.recent;
        });
        ref.read(paginatedClientSearchProvider.notifier).updateSearch(null);
        ref.read(paginatedClientSearchProvider.notifier).updateFilters(typeFilter: null);
        ref.read(paginatedClientSearchProvider.notifier).updateSort('created_at', false);
      },
      onQueryChanged: (query) {
        // Handle query if needed locally, though server search debounce takes care of it
      },
      filters: [
        FilterChipData(
          label: _selectedFilterType == null
              ? 'Tipo'
              : (_selectedFilterType == 'company' ? 'Empresas' : 'Personas'),
          isActive: _selectedFilterType != null,
          onTap: () {
            FilterBottomSheet.showSingle(
              context: context,
              title: 'Tipo',
              options: [
                const FilterOption(
                  label: 'Todos',
                  value: 'all',
                  icon: Icons.grid_view,
                ),
                const FilterOption(
                  label: 'Empresas',
                  value: 'company',
                  icon: Icons.domain,
                ),
                const FilterOption(
                  label: 'Personas',
                  value: 'person',
                  icon: Icons.person_outline,
                ),
              ],
              selectedValue: _selectedFilterType ?? 'all',
              onSelect: (value) {
                setState(() {
                  _selectedFilterType = value == 'all' ? null : value;
                });
                ref.read(paginatedClientSearchProvider.notifier).updateFilters(typeFilter: _selectedFilterType);
              },
            );
          },
        ),
        FilterChipData(
          label: HorizontalFilterBar.formatLabel(
            defaultLabel: 'Ciudad',
            selectedValues: _selectedFilterCities.toList(),
          ),
          isActive: _selectedFilterCities.isNotEmpty,
          onTap: () {
            final currentClients = paginatedAsync.valueOrNull?.items ?? [];
            final validCities = currentClients
                .map((c) => c.city)
                .whereType<String>()
                .where((c) => c.trim().isNotEmpty)
                .toSet();

            final options = {...validCities, ..._selectedFilterCities}.toList()..sort();

            FilterBottomSheet.showMulti(
              context: context,
              title: 'Ciudad',
              options: options,
              selectedValues: _selectedFilterCities,
              onApply: (newSet) {
                setState(() {
                  _selectedFilterCities.clear();
                  _selectedFilterCities.addAll(newSet);
                });
              },
            );
          },
        ),
      ],
      filter: (client, query) {
        if (_selectedFilterCities.isNotEmpty) {
          if (client.city == null || !_selectedFilterCities.contains(client.city)) {
            return false;
          }
        }
        return true;
      },
      comparator: null,
      bottomFilterWidget: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            SortSelector(
              currentSort: _currentSort,
              options: const [
                SortOption.recent,
                SortOption.nameAZ,
                SortOption.nameZA,
              ],
              onSortChanged: (val) {
                setState(() {
                  _currentSort = val;
                });
                
                String orderBy = 'created_at';
                bool ascending = false;
                if (val == SortOption.nameAZ) {
                  orderBy = 'name';
                  ascending = true;
                } else if (val == SortOption.nameZA) {
                  orderBy = 'name';
                  ascending = false;
                }
                ref.read(paginatedClientSearchProvider.notifier).updateSort(orderBy, ascending);
              },
            ),
          ],
        ),
      ),
      itemBuilder: (context, client) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: StandardListItem(
            leading: Icon(
              client.type == 'company'
                  ? Icons.domain_outlined
                  : Icons.person_outlined,
              size: 32,
              color: colors.onSurfaceVariant,
            ),
            title: client.name,
            subtitle: Text(client.taxId ?? 'Sin ID'),
            onTap: () {
              context.push('/clients/${client.id}', extra: client);
            },
          ),
        );
      },
    );
  }
}
