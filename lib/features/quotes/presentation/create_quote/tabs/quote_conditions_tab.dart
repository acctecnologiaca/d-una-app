import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/create_quote_provider.dart';
import 'package:material_symbols_icons/symbols.dart';

class QuoteConditionsTab extends ConsumerWidget {
  const QuoteConditionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createQuoteProvider);

    if (state.conditions.isEmpty) {
      return Center(
        child: Text(
          'No hay condiciones comerciales agregadas',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 16,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(0, 12, 0, 12),
      itemCount: state.conditions.length,
      itemBuilder: (context, index) {
        final condition = state.conditions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide.none,
          ),
          child: ListTile(
            title: Text(condition.description),
            trailing: IconButton(
              icon: Icon(
                Symbols.close_small,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () {
                ref
                    .read(createQuoteProvider.notifier)
                    .removeCondition(condition.id);
              },
            ),
          ),
        );
      },
    );
  }
}
