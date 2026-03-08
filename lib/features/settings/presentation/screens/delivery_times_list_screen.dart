import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/features/portfolio/data/models/delivery_time_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import '../widgets/add_edit_delivery_time_sheet.dart';

class DeliveryTimesListScreen extends ConsumerStatefulWidget {
  const DeliveryTimesListScreen({super.key});

  @override
  ConsumerState<DeliveryTimesListScreen> createState() =>
      _DeliveryTimesListScreenState();
}

class _DeliveryTimesListScreenState
    extends ConsumerState<DeliveryTimesListScreen> {
  SortOption _currentSort = SortOption.durationAsc;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddEditSheet([DeliveryTime? deliveryTime]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          AddEditDeliveryTimeSheet(deliveryTime: deliveryTime),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final timesAsync = ref.watch(deliveryTimesProvider);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: StandardAppBar(
        backgroundColor: _isSearching ? colors.surfaceContainerHigh : null,
        title: 'Tiempos de entrega y ejecución',
        customTitle: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar tiempo...',
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
          onPressed: () => _showAddEditSheet(),
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
              'Configura los tiempos de entrega de productos y los tiempos de ejecución para servicios.',
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
              options: const [
                SortOption.durationAsc,
                SortOption.durationDesc,
                SortOption.type,
                SortOption.nameAZ,
                SortOption.nameZA,
              ],
              onSortChanged: (sort) {
                setState(() => _currentSort = sort);
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: timesAsync.when(
              data: (times) {
                var filtered = times.where((t) {
                  final isGlobal = t.userId == null;
                  if (isGlobal) return false;

                  return t.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
                }).toList();

                int getDurationInHours(DeliveryTime t) {
                  if (t.minValue == null && t.maxValue == null) return 999999;
                  final val = t.maxValue ?? t.minValue ?? 0;
                  switch (t.unit) {
                    case 'hours':
                      return val;
                    case 'days':
                      return val * 24;
                    case 'weeks':
                      return val * 24 * 7;
                    case 'months':
                      return val * 24 * 30;
                    default:
                      return val;
                  }
                }

                filtered.sort((a, b) {
                  if (_currentSort == SortOption.nameZA) {
                    return b.name.compareTo(a.name);
                  } else if (_currentSort == SortOption.durationAsc) {
                    return getDurationInHours(
                      a,
                    ).compareTo(getDurationInHours(b));
                  } else if (_currentSort == SortOption.durationDesc) {
                    return getDurationInHours(
                      b,
                    ).compareTo(getDurationInHours(a));
                  } else if (_currentSort == SortOption.type) {
                    return a.type.compareTo(b.type);
                  }
                  return a.name.compareTo(b.name);
                });

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No se encontraron configuraciones.',
                      style: textTheme.bodyLarge,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final time = filtered[index];
                    final isGlobal = time.userId == null;
                    final isOwned = time.userId == currentUserId;
                    final canEdit = isOwned;

                    return ListTile(
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              time.name,
                              style: textTheme.bodyLarge?.copyWith(
                                color: canEdit
                                    ? colors.onSurface
                                    : colors.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isGlobal)
                            Icon(
                              Icons.public,
                              size: 14,
                              color: colors.primary.withValues(alpha: 0.5),
                            ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (time.type == 'delivery' || time.type == 'both')
                            Icon(
                              Icons.local_shipping_outlined,
                              color: colors.onSurfaceVariant,
                            ),
                          if (time.type == 'both') const SizedBox(width: 8),
                          if (time.type == 'execution' || time.type == 'both')
                            Icon(
                              Icons.timer_outlined,
                              color: colors.onSurfaceVariant,
                            ),
                        ],
                      ),
                      onTap: () {
                        if (canEdit) {
                          _showAddEditSheet(time);
                        } else {
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Este es un ajuste global fijado por el sistema, no puede ser modificado.',
                                ),
                              ),
                            );
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  Center(child: Text('Error al cargar la lista: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
