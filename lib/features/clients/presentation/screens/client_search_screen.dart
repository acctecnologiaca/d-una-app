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
import '../../../../core/utils/string_extensions.dart';
import '../../../../shared/widgets/standard_list_item.dart';

class ClientSearchScreen extends ConsumerStatefulWidget {
  const ClientSearchScreen({super.key});

  @override
  ConsumerState<ClientSearchScreen> createState() => _ClientSearchScreenState();
}

class _ClientSearchScreenState extends ConsumerState<ClientSearchScreen> {
  String? _selectedFilterType; // null = All, 'company', 'person'
  final Set<String> _selectedFilterCities = {};
  String _searchQuery = '';
  SortOption _currentSort = SortOption.recent;

  String _getHistoryKey() {
    final user = ref.read(authRepositoryProvider).currentUser;
    return 'client_search_history_${user?.id ?? "guest"}';
  }

  @override
  Widget build(BuildContext context) {
    final clientsAsync = ref.watch(clientsProvider);
    final colors = Theme.of(context).colorScheme;

    return GenericSearchScreen<Client>(
      hintText: 'Buscar cliente...',
      historyKey: _getHistoryKey(),
      data: clientsAsync,
      onResetFilters: () {
        setState(() {
          _selectedFilterType = null;
          _selectedFilterCities.clear();
          _searchQuery = '';
          _currentSort = SortOption.recent;
        });
      },
      onQueryChanged: (query) {
        setState(() {
          _searchQuery = query;
        });
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
            clientsAsync.whenData((clients) {
              final queryNormalized = _searchQuery.normalized;
              final availableCities = clients
                  .where((c) {
                    return queryNormalized.isEmpty ||
                        c.name.normalized.contains(queryNormalized) ||
                        (c.taxId?.normalized ?? '').contains(queryNormalized) ||
                        (c.alias?.normalized ?? '').contains(queryNormalized) ||
                        (c.email?.normalized ?? '').contains(queryNormalized);
                  })
                  .map((c) => c.city)
                  .whereType<String>()
                  .where((c) => c.isNotEmpty)
                  .toSet()
                  .toList();

              FilterBottomSheet.showMulti(
                context: context,
                title: 'Ciudad',
                options: availableCities,
                selectedValues: _selectedFilterCities,
                onApply: (newSet) {
                  setState(() {
                    _selectedFilterCities.clear();
                    _selectedFilterCities.addAll(newSet);
                  });
                },
              );
            });
          },
        ),
      ],
      filter: (client, query) {
        final normalizedQuery = query.normalized;
        final matchesQuery =
            normalizedQuery.isEmpty ||
            client.name.normalized.contains(normalizedQuery) ||
            (client.taxId?.normalized ?? '').contains(normalizedQuery) ||
            (client.alias?.normalized ?? '').contains(normalizedQuery) ||
            (client.email?.normalized ?? '').contains(normalizedQuery);

        final matchesType =
            _selectedFilterType == null || client.type == _selectedFilterType;

        final matchesCity =
            _selectedFilterCities.isEmpty ||
            (client.city != null &&
                _selectedFilterCities.contains(client.city));

        return matchesQuery && matchesType && matchesCity;
      },
      comparator: (a, b) {
        switch (_currentSort) {
          case SortOption.recent:
            return b.createdAt.compareTo(a.createdAt);
          case SortOption.nameAZ:
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          case SortOption.nameZA:
            return b.name.toLowerCase().compareTo(a.name.toLowerCase());
          default:
            return 0;
        }
      },
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
