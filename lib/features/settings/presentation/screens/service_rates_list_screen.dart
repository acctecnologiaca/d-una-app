import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/features/portfolio/data/models/service_rate_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';

class ServiceRatesListScreen extends ConsumerStatefulWidget {
  const ServiceRatesListScreen({super.key});

  @override
  ConsumerState<ServiceRatesListScreen> createState() =>
      _ServiceRatesListScreenState();
}

class _ServiceRatesListScreenState
    extends ConsumerState<ServiceRatesListScreen> {
  SortOption _currentSort = SortOption.nameAZ;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddServiceRateDialog() {
    final nameController = TextEditingController();
    final symbolController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Agregar tarifa de servicio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Nombre (ej: Por hora)',
                controller: nameController,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                label: 'Símbolo (ej: /hr)',
                controller: symbolController,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.outlineVariant),
                foregroundColor: colors.primary,
              ),
              onPressed: () async {
                final name = nameController.text.trim();
                final symbol = symbolController.text.trim();
                if (name.isNotEmpty && symbol.isNotEmpty) {
                  try {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    await ref
                        .read(lookupRepositoryProvider)
                        .addServiceRate(name, symbol);
                    final _ = await ref.refresh(serviceRatesProvider.future);
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Tarifa "$name" agregada')),
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error al agregar: $e',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onError,
                            ),
                          ),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showEditServiceRateDialog(ServiceRate rate) {
    final nameController = TextEditingController(text: rate.name);
    final symbolController = TextEditingController(text: rate.symbol);

    showDialog(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Modificar'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(
                label: 'Nombre',
                controller: nameController,
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              CustomTextField(label: 'Símbolo', controller: symbolController),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            IconButton(
              icon: Icon(Icons.delete_outline, color: colors.primary),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar tarifa'),
                    content: Text(
                      '¿Estás seguro de que deseas eliminar "${rate.name}"?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: const Text('Cancelar'),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.error,
                        ),
                        onPressed: () => Navigator.pop(ctx, true),
                        child: const Text('Eliminar'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  if (!context.mounted) return;
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  try {
                    await ref
                        .read(lookupRepositoryProvider)
                        .deleteServiceRate(rate.id);
                    final _ = await ref.refresh(serviceRatesProvider.future);
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Tarifa "${rate.name}" eliminada'),
                      ),
                    );
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Error al eliminar: $e',
                            style: TextStyle(color: colors.onError),
                          ),
                        ),
                      );
                    }
                  }
                }
              },
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: colors.primary),
                    foregroundColor: colors.primary,
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final symbol = symbolController.text.trim();
                    final changed = name != rate.name || symbol != rate.symbol;
                    if (name.isNotEmpty && symbol.isNotEmpty && changed) {
                      try {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        await ref
                            .read(lookupRepositoryProvider)
                            .updateServiceRate(rate.id, name, symbol);
                        final _ = await ref.refresh(
                          serviceRatesProvider.future,
                        );
                        navigator.pop();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Tarifa actualizada a "$name"'),
                          ),
                        );
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Error al actualizar: $e',
                                style: TextStyle(color: colors.onError),
                              ),
                            ),
                          );
                        }
                      }
                    } else if (!changed) {
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final ratesAsync = ref.watch(serviceRatesProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: StandardAppBar(
        backgroundColor: _isSearching ? colors.surfaceContainerHigh : null,
        title: 'Tarifas de servicios',
        customTitle: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar tarifa...',
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
              onPressed: () => setState(() => _isSearching = true),
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
          onPressed: _showAddServiceRateDialog,
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
              'Registra los tipos de tarifas con los que cobras tus servicios (ej: por hora, por proyecto, por día).',
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
              onSortChanged: (sort) => setState(() => _currentSort = sort),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ratesAsync.when(
              data: (rates) {
                final currentUserId =
                    Supabase.instance.client.auth.currentUser?.id;

                var filtered = rates.where((r) {
                  final isOwner = r.createdBy == currentUserId;
                  final matchesSearch =
                      r.name.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      ) ||
                      r.symbol.toLowerCase().contains(
                        _searchQuery.toLowerCase(),
                      );
                  return isOwner && matchesSearch;
                }).toList();

                filtered.sort((a, b) {
                  if (_currentSort == SortOption.nameZA) {
                    return b.name.compareTo(a.name);
                  }
                  return a.name.compareTo(b.name);
                });

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No tienes tarifas de servicios registradas',
                      style: textTheme.bodyLarge,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final rate = filtered[index];
                    final bool canEdit = !rate.isVerified;

                    return ListTile(
                      title: Row(
                        children: [
                          Text(
                            rate.name,
                            style: textTheme.bodyLarge?.copyWith(
                              color: canEdit
                                  ? colors.onSurface
                                  : colors.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          if (rate.isVerified) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.verified,
                              color: colors.primary.withValues(alpha: 0.5),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      subtitle: Text(
                        rate.symbol,
                        style: textTheme.bodySmall?.copyWith(
                          color: canEdit
                              ? colors.onSurfaceVariant
                              : colors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      onTap: canEdit
                          ? () => _showEditServiceRateDialog(rate)
                          : () {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    duration: const Duration(seconds: 5),
                                    content: Row(
                                      children: [
                                        const Expanded(
                                          child: Text(
                                            'Esta tarifa ha sido verificada y ya no puede ser modificada ni eliminada.',
                                            style: TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                          ),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          onPressed: () => ScaffoldMessenger.of(
                                            context,
                                          ).hideCurrentSnackBar(),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                            },
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Center(
                child: Text('Error al cargar tarifas de servicios'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
