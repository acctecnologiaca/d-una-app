import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/features/quotes/data/models/commercial_condition.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import '../widgets/add_edit_commercial_condition_sheet.dart';

class CommercialConditionsListScreen extends ConsumerStatefulWidget {
  const CommercialConditionsListScreen({super.key});

  @override
  ConsumerState<CommercialConditionsListScreen> createState() =>
      _CommercialConditionsListScreenState();
}

class _CommercialConditionsListScreenState
    extends ConsumerState<CommercialConditionsListScreen> {
  SortOption _currentSort = SortOption.nameAZ;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => const AddEditCommercialConditionSheet(),
    );
  }

  void _showEditSheet(CommercialCondition condition) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) =>
          AddEditCommercialConditionSheet(condition: condition),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final conditionsAsync = ref.watch(commercialConditionsProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: StandardAppBar(
        backgroundColor: _isSearching ? colors.surfaceContainerHigh : null,
        title: 'Condiciones comerciales',
        customTitle: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar condición...',
                  border: InputBorder.none,
                  fillColor: colors.surfaceContainerHigh,
                ),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: colors.onSurface,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              )
            : null,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: Icon(Icons.search, color: colors.onSurface),
              onPressed: () {
                setState(() => _isSearching = true);
              },
            )
          else
            IconButton(
              icon: Icon(Icons.close, color: colors.onSurface),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: CustomExtendedFab(
          onPressed: _showAddSheet,
          label: 'Agregar',
          icon: Icons.add,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Define todas aquellas condiciones comerciales que pudieses ofrecerles a tus cliente dentro de tus cotizaciones o reportes.',
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
                height: 1.5,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: SortSelector(
              currentSort: _currentSort,
              options: const [SortOption.nameAZ, SortOption.nameZA],
              onSortChanged: (sort) {
                setState(() => _currentSort = sort);
              },
            ),
          ),

          const SizedBox(height: 8),

          Expanded(
            child: conditionsAsync.when(
              data: (conditions) {
                final currentUserId =
                    Supabase.instance.client.auth.currentUser?.id;

                // Filter by current user and search query
                var filtered = conditions.where((c) {
                  final isOwner = c.userId == currentUserId;
                  final matchesSearch = c.description.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
                  return isOwner && matchesSearch;
                }).toList();

                filtered.sort((a, b) {
                  switch (_currentSort) {
                    case SortOption.nameZA:
                      return b.description.compareTo(a.description);
                    case SortOption.nameAZ:
                      return a.description.compareTo(b.description);
                    default:
                      return 0;
                  }
                });

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No tienes condiciones registradas',
                      style: textTheme.bodyLarge,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final condition = filtered[index];
                    return ListTile(
                      title: Text(
                        condition.description,
                        style: textTheme.bodyLarge?.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (condition.isDefaultQuote)
                            Tooltip(
                              message: 'Por defecto en cotizaciones',
                              child: Icon(
                                Icons.description_outlined,
                                size: 20,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          if (condition.isDefaultReport) ...[
                            if (condition.isDefaultQuote)
                              const SizedBox(width: 4),
                            Tooltip(
                              message: 'Por defecto en reportes',
                              child: Icon(
                                Icons.assignment_outlined,
                                size: 20,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                      onTap: () => _showEditSheet(condition),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  const Center(child: Text('Error al cargar condiciones')),
            ),
          ),
        ],
      ),
    );
  }
}
