import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/generic_list_screen.dart';
import 'package:d_una_app/shared/widgets/standard_list_item.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/features/quotes/data/models/commercial_condition.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import '../widgets/add_edit_commercial_condition_sheet.dart';

class CommercialConditionsListScreen extends ConsumerWidget {
  const CommercialConditionsListScreen({super.key});

  void _showAddSheet(BuildContext context) {
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

  void _showEditSheet(BuildContext context, CommercialCondition condition) {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final conditionsAsync = ref.watch(commercialConditionsProvider);

    return GenericListScreen<CommercialCondition>(
      title: 'Condiciones comerciales',
      descriptionText:
          'Define todas aquellas condiciones comerciales que pudieses ofrecerles a tus cliente dentro de tus cotizaciones o reportes.',
      itemsAsync: conditionsAsync,
      emptyListMessage: 'No tienes condiciones registradas',
      onAddPressed: () => _showAddSheet(context),
      sortOptions: const [SortOption.nameAZ, SortOption.nameZA],
      initialSort: SortOption.nameAZ,
      preFilter: (items) {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        return items.where((c) => c.userId == currentUserId).toList();
      },
      onSearch: (item, query) =>
          item.description.toLowerCase().contains(query.toLowerCase()),
      onSort: (a, b, sort) {
        if (sort == SortOption.nameZA) {
          return b.description.compareTo(a.description);
        }
        return a.description.compareTo(b.description);
      },
      itemBuilder: (context, condition) {
        return StandardListItem(
          title: condition.description,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (condition.isDefaultQuote)
                Tooltip(
                  message: 'Por defecto en cotizaciones',
                  child: Image.asset(
                    'assets/icons/request_quote_checked.png',
                    width: 20,
                    height: 20,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              if (condition.isDefaultReport) ...[
                if (condition.isDefaultQuote) const SizedBox(width: 4),
                Tooltip(
                  message: 'Por defecto en reportes',
                  child: Image.asset(
                    'assets/icons/contract_checked.png',
                    width: 20,
                    height: 20,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
          onTap: () => _showEditSheet(context, condition),
        );
      },
    );
  }
}
