import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/generic_list_screen.dart';
import 'package:d_una_app/shared/widgets/standard_list_item.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/features/settings/data/models/observation.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import '../widgets/add_edit_observation_sheet.dart';

class ObservationsListScreen extends ConsumerWidget {
  const ObservationsListScreen({super.key});

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => const AddEditObservationSheet(),
    );
  }

  void _showEditSheet(BuildContext context, Observation observation) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => AddEditObservationSheet(observation: observation),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final observationsAsync = ref.watch(observationsProvider);

    return GenericListScreen<Observation>(
      title: 'Lista de observaciones',
      descriptionText:
          'Establece observaciones que quisieras plasmar en tus notas de entrega.',
      itemsAsync: observationsAsync,
      emptyListMessage: 'No tienes observaciones registradas',
      onAddPressed: () => _showAddSheet(context),
      sortOptions: const [SortOption.nameAZ, SortOption.nameZA],
      initialSort: SortOption.nameAZ,
      preFilter: (items) {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        return items.where((o) => o.userId == currentUserId).toList();
      },
      onSearch: (item, query) =>
          item.description.toLowerCase().contains(query.toLowerCase()),
      onSort: (a, b, sort) {
        if (sort == SortOption.nameZA) {
          return b.description.compareTo(a.description);
        }
        return a.description.compareTo(b.description);
      },
      itemBuilder: (context, observation) {
        return StandardListItem(
          title: observation.description,
          trailing: observation.isDefaultDeliveryNote
              ? Tooltip(
                  message: 'Por defecto en notas de entrega',
                  child: Image.asset(
                    'assets/icons/list_alt_check.png',
                    width: 20,
                    height: 20,
                    color: colors.onSurfaceVariant,
                  ),
                )
              : null,
          onTap: () => _showEditSheet(context, observation),
        );
      },
    );
  }
}
