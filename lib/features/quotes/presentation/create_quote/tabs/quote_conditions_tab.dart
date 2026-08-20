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
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Symbols.notes,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No hay condiciones comerciales agregadas',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(
        top: 12,
        left: 0,
        right: 0,
        bottom: 88,
      ),
      itemCount: state.conditions.length,
      onReorder: (oldIndex, newIndex) {
        ref
            .read(createQuoteProvider.notifier)
            .reorderConditions(oldIndex, newIndex);
      },
      itemBuilder: (context, index) {
        final condition = state.conditions[index];
        return Card(
          key: ValueKey(
            condition.id.isNotEmpty ? condition.id : index.toString(),
          ),
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide.none,
          ),
          child: ListTile(
            leading: Icon(
              Icons.drag_handle,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
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
