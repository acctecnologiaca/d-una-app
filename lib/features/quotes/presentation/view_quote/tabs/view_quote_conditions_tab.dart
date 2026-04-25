import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/view_quote_provider.dart';

class ViewQuoteConditionsTab extends ConsumerWidget {
  final String quoteId;
  const ViewQuoteConditionsTab({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(viewQuoteProvider(quoteId));

    if (state.isLoading && state.quote == null) {
      return const Center(child: CircularProgressIndicator());
    }

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
            'No hay condiciones comerciales en esta cotización',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontSize: 16,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: state.conditions.length,
      itemBuilder: (context, index) {
        final condition = state.conditions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Symbols.check_circle,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    condition.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
