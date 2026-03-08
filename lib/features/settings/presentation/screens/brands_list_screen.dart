import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/features/portfolio/data/models/brand_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';

class BrandsListScreen extends ConsumerStatefulWidget {
  const BrandsListScreen({super.key});

  @override
  ConsumerState<BrandsListScreen> createState() => _BrandsListScreenState();
}

class _BrandsListScreenState extends ConsumerState<BrandsListScreen> {
  SortOption _currentSort = SortOption.nameAZ;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _normalizeName(String name) {
    String withOutAccents = name
        .replaceAll(RegExp(r'[áàäâÁÀÄÂ]'), 'a')
        .replaceAll(RegExp(r'[éèëêÉÈËÊ]'), 'e')
        .replaceAll(RegExp(r'[íìïîÍÌÏÎ]'), 'i')
        .replaceAll(RegExp(r'[óòöôÓÒÖÔ]'), 'o')
        .replaceAll(RegExp(r'[úùüûÚÙÜÛ]'), 'u')
        .replaceAll(RegExp(r'[ñÑ]'), 'n');
    return withOutAccents.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  void _showAddBrandDialog() {
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Agregar marca'),
          content: CustomTextField(
            label: 'Nombre de la marca',
            controller: textController,
            textCapitalization: TextCapitalization.words,
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
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  final existingBrands =
                      ref.read(brandsProvider).valueOrNull ?? [];
                  final isDuplicate = existingBrands.any(
                    (b) => _normalizeName(b.name) == _normalizeName(name),
                  );

                  if (isDuplicate) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'La marca "$name" ya existe.',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onError,
                          ),
                        ),
                      ),
                    );
                    return;
                  }

                  // Add to DB
                  try {
                    final scaffoldMessenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    await ref.read(lookupRepositoryProvider).addBrand(name);
                    // Refresh the provider and wait for it
                    final _ = await ref.refresh(brandsProvider.future);
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Marca "$name" agregada')),
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

  void _showEditBrandDialog(Brand brand) {
    final textController = TextEditingController(text: brand.name);

    showDialog(
      context: context,
      builder: (context) {
        final colors = Theme.of(context).colorScheme;
        return AlertDialog(
          title: const Text('Modificar'),
          content: CustomTextField(
            label: 'Nombre de la marca',
            controller: textController,
            textCapitalization: TextCapitalization.words,
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            IconButton(
              icon: Icon(Icons.delete_outline, color: colors.primary),
              onPressed: () async {
                // Show confirmation dialog before deleting
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar marca'),
                    content: Text(
                      '¿Estás seguro de que deseas eliminar la marca "${brand.name}"?',
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
                        .deleteBrand(brand.id);
                    final _ = await ref.refresh(brandsProvider.future);
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Marca "${brand.name}" eliminada'),
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
                    final name = textController.text.trim();
                    if (name.isNotEmpty && name != brand.name) {
                      final existingBrands =
                          ref.read(brandsProvider).valueOrNull ?? [];
                      final isDuplicate = existingBrands.any(
                        (b) =>
                            b.id != brand.id &&
                            _normalizeName(b.name) == _normalizeName(name),
                      );

                      if (isDuplicate) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'La marca "$name" ya existe.',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onError,
                              ),
                            ),
                          ),
                        );
                        return;
                      }

                      try {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        await ref
                            .read(lookupRepositoryProvider)
                            .updateBrand(brand.id, name);
                        final _ = await ref.refresh(brandsProvider.future);
                        navigator.pop();
                        scaffoldMessenger.showSnackBar(
                          SnackBar(
                            content: Text('Marca actualizada a "$name"'),
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
                    } else if (name == brand.name) {
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

    final brandsAsync = ref.watch(brandsProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: StandardAppBar(
        backgroundColor: _isSearching ? colors.surfaceContainerHigh : null,
        title: 'Marcas de productos',
        customTitle: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar marca...',
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
          onPressed: _showAddBrandDialog,
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
              'Registra las marcas de aquellos productos, que no veas listadas aún en nuestra plataforma.',
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
            child: brandsAsync.when(
              data: (brands) {
                final currentUserId =
                    Supabase.instance.client.auth.currentUser?.id;

                // 1. Filter: Solo mostrar marcas creadas por el usuario, luego filtrar por búsqueda
                var filtered = brands.where((b) {
                  final isOwner = b.createdBy == currentUserId;
                  final matchesSearch = b.name.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  );
                  return isOwner && matchesSearch;
                }).toList();

                // 2. Sort
                filtered.sort((a, b) {
                  if (_currentSort == SortOption.nameZA) {
                    return b.name.compareTo(a.name);
                  }
                  return a.name.compareTo(b.name);
                });

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No tienes marcas registradas',
                      style: textTheme.bodyLarge,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final brand = filtered[index];
                    final bool canEdit = !brand.isVerified;

                    return ListTile(
                      title: Row(
                        children: [
                          Text(
                            brand.name,
                            style: textTheme.bodyLarge?.copyWith(
                              color: canEdit
                                  ? colors.onSurface
                                  : colors.onSurface.withValues(alpha: 0.5),
                            ),
                          ),
                          if (brand.isVerified) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.verified,
                              color: colors.primary.withValues(alpha: 0.5),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      onTap: canEdit
                          ? () => _showEditBrandDialog(brand)
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
                                            'Esta marca ha sido verificada y ya no puede ser modificada ni eliminada.',
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
              error: (err, stack) =>
                  Center(child: Text('Error al cargar marcas')),
            ),
          ),
        ],
      ),
    );
  }
}
