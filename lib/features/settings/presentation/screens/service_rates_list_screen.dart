import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/generic_list_screen.dart';
import 'package:d_una_app/shared/widgets/standard_list_item.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/features/portfolio/data/models/service_rate_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/settings/presentation/widgets/add_edit_service_rate_sheet.dart';

class ServiceRatesListScreen extends ConsumerWidget {
  const ServiceRatesListScreen({super.key});

  void _showAddServiceRateSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => const AddEditServiceRateSheet(),
    );
  }

  void _showEditServiceRateSheet(BuildContext context, ServiceRate rate) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => AddEditServiceRateSheet(rate: rate),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final ratesAsync = ref.watch(serviceRatesProvider);

    return GenericListScreen<ServiceRate>(
      title: 'Tarifas de servicios',
      descriptionText:
          'Registra los tipos de tarifas con los que cobras tus servicios (ej: por hora, por proyecto, por día).',
      itemsAsync: ratesAsync,
      emptyListMessage: 'No tienes tarifas de servicios registradas',
      onAddPressed: () => _showAddServiceRateSheet(context),
      sortOptions: const [SortOption.nameAZ, SortOption.nameZA],
      initialSort: SortOption.nameAZ,
      preFilter: (items) {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        return items.where((r) => r.userId == currentUserId).toList();
      },
      onSearch: (item, query) {
        final lowerQuery = query.toLowerCase();
        return item.name.toLowerCase().contains(lowerQuery) ||
            item.symbol.toLowerCase().contains(lowerQuery);
      },
      onSort: (a, b, sort) {
        if (sort == SortOption.nameZA) {
          return b.name.compareTo(a.name);
        }
        return a.name.compareTo(b.name);
      },
      itemBuilder: (context, rate) {
        final bool canEdit = !rate.isVerified;

        Widget item = StandardListItem(
          title: rate.name,
          subtitle: Text(rate.symbol),
          titleTrailing: rate.isVerified
              ? Icon(
                  Icons.verified,
                  color: colors.primary.withValues(alpha: 0.5),
                  size: 20,
                )
              : null,
          onTap: canEdit
              ? () => _showEditServiceRateSheet(context, rate)
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

        if (!canEdit) {
          item = Opacity(opacity: 0.5, child: item);
        }

        return item;
      },
    );
  }
}
