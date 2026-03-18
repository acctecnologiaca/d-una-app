import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/shipping_method.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../../../shared/widgets/generic_list_screen.dart';
import '../../../../../shared/widgets/standard_list_item.dart';
import '../../../portfolio/presentation/providers/lookup_providers.dart';

class ShippingMethodsScreen extends ConsumerStatefulWidget {
  const ShippingMethodsScreen({super.key});

  @override
  ConsumerState<ShippingMethodsScreen> createState() =>
      _ShippingMethodsScreenState();
}

class _ShippingMethodsScreenState extends ConsumerState<ShippingMethodsScreen> {
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

    return userProfileAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (profile) {
        if (profile == null) {
          return const Scaffold(
            body: Center(child: Text('Perfil no encontrado')),
          );
        }

        final shippingMethodsAsync = ref.watch(shippingMethodsProvider);
        final shippingCompaniesAsync = ref.watch(shippingCompaniesProvider);
        final companies = shippingCompaniesAsync.valueOrNull ?? [];

        return GenericListScreen<ShippingMethod>(
          title: 'Métodos de envío',
          itemsAsync: shippingMethodsAsync,
          onSearch: (method, query) {
            return method.label.toLowerCase().contains(query.toLowerCase());
          },
          onAddPressed: () async {
            await context.push('/settings/shipping-methods/add');
            ref.invalidate(shippingMethodsProvider);
          },
          emptyListMessage: 'No hay método de envío agregado',
          itemBuilder: (context, method) {
            final isPrimary = method.isPrimary;

            final company = companies
                .where((c) => c.id == method.companyId)
                .firstOrNull;
            final companyName = company?.displayName ?? 'Desconocida';

            return StandardListItem(
              onTap: () async {
                await context.push(
                  '/settings/shipping-methods/edit',
                  extra: method,
                );
              },
              title: method.label,
              titleTrailing: isPrimary
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.2),
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
                    )
                  : null,
              subtitle: Text(
                companyName,
                style: textTheme.bodyMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
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
            );
          },
        );
      },
    );
  }
}
