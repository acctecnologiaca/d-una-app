import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/generic_search_screen.dart';
import '../../../data/models/commercial_condition.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';
import '../../../../../core/utils/search_utils.dart';

class QuoteConditionSearchScreen extends ConsumerWidget {
  const QuoteConditionSearchScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final conditionsAsync = ref.watch(commercialConditionsProvider);

    return GenericSearchScreen<CommercialCondition>(
      title: 'Buscar condición',
      hintText: 'Buscar condición...',
      historyKey: 'quote_condition_search_history',
      data: conditionsAsync,
      filter: (condition, query) =>
          SearchUtils.matchesCombo(query, [condition.description]),
      itemBuilder: (context, condition) {
        return Column(
          children: [
            ListTile(
              title: Text(
                condition.description,
                style: TextStyle(color: colors.onSurface, fontSize: 16),
              ),
              onTap: () {
                context.pop(condition);
              },
            ),
            const Divider(height: 1),
          ],
        );
      },
    );
  }
}
