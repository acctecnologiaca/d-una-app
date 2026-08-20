import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/create_report_provider.dart';

class ReportConditionsTab extends ConsumerWidget {
  const ReportConditionsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createReportProvider);
    final notifier = ref.read(createReportProvider.notifier);

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
        if (!state.isReadOnly) {
          notifier.reorderConditions(oldIndex, newIndex);
        }
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
            trailing: !state.isReadOnly
                ? IconButton(
                    icon: Icon(
                      Symbols.close_small,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () {
                      notifier.removeCondition(index);
                    },
                  )
                : null,
          ),
        );
      },
    );
  }
}
