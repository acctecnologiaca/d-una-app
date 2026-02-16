import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/shipping_method.dart';
import '../providers/profile_provider.dart';

class ShippingMethodsScreen extends ConsumerStatefulWidget {
  const ShippingMethodsScreen({super.key});

  @override
  ConsumerState<ShippingMethodsScreen> createState() =>
      _ShippingMethodsScreenState();
}

class _ShippingMethodsScreenState extends ConsumerState<ShippingMethodsScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _removeMethod(ShippingMethod method) async {
    // ... existing remove logic ...
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar método de envío'),
        content: const Text(
          '¿Estás seguro de que deseas eliminar este método de envío?',
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      try {
        await ref
            .read(profileRepositoryProvider)
            .deleteShippingMethod(method.id);
        ref.invalidate(shippingMethodsProvider);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Método eliminado')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userProfileAsync = ref.watch(userProfileProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () {
            if (_isSearching) {
              setState(() {
                _isSearching = false;
                _searchQuery = '';
                _searchController.clear();
              });
            } else {
              context.pop();
            }
          },
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: colors.onSurfaceVariant),
                ),
                style: TextStyle(color: colors.onSurface),
              )
            : Text(
                'Métodos de envío',
                style: textTheme.titleLarge?.copyWith(
                  color: colors.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Icons.search,
              color: colors.onSurface,
            ),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Perfil no encontrado'));
          }

          final shippingMethodsAsync = ref.watch(shippingMethodsProvider);

          return shippingMethodsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error cargando métodos: $e')),
            data: (methods) {
              final filteredMethods = methods.where((m) {
                return m.label.toLowerCase().contains(_searchQuery);
              }).toList();

              if (filteredMethods.isEmpty) {
                return Center(
                  child: Text(
                    methods.isEmpty
                        ? 'No hay método de envío agregado'
                        : 'No se encontraron resultados',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                itemCount: filteredMethods.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final method = filteredMethods[index];
                  final isPrimary = method.isPrimary;

                  return InkWell(
                    onTap: () async {
                      await context.push(
                        '/profile/shipping-methods/edit',
                        extra: method,
                        // Route expects ShippingMethod object?
                        // Note: In AddShippingMethodScreen I updated it to expect ShippingMethod?
                        // But I need to verify go_router route definition.
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0.0,
                        vertical: 16.0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    method.label,
                                    style: textTheme.bodyLarge?.copyWith(
                                      color: colors.onSurface,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (isPrimary) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'P',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            color: colors.onSurfaceVariant,
                            onPressed: () => _removeMethod(method),
                            splashRadius: 20,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
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
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: FloatingActionButton.extended(
          onPressed: () async {
            await context.push('/profile/shipping-methods/add');
            ref.invalidate(shippingMethodsProvider);
          },
          backgroundColor: colors.tertiaryContainer,
          foregroundColor: colors.onTertiaryContainer,
          elevation: 4,
          icon: const Icon(Icons.add),
          label: const Text(
            'Agregar',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}
