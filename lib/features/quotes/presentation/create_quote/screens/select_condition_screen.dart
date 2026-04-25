import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/generic_list_screen.dart';
import '../../../../settings/presentation/widgets/add_edit_commercial_condition_sheet.dart';
import '../../../data/models/commercial_condition.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';
import '../providers/create_quote_provider.dart';

class SelectConditionScreen extends ConsumerStatefulWidget {
  final String? quoteId;

  const SelectConditionScreen({super.key, this.quoteId});

  @override
  ConsumerState<SelectConditionScreen> createState() =>
      _SelectConditionScreenState();
}

class _SelectConditionScreenState extends ConsumerState<SelectConditionScreen> {
  final Set<CommercialCondition> _selectedConditions = {};

  void _toggleSelection(CommercialCondition condition) {
    setState(() {
      if (_selectedConditions.contains(condition)) {
        _selectedConditions.remove(condition);
      } else {
        _selectedConditions.add(condition);
      }
    });
  }

  void _confirmSelection() {
    if (_selectedConditions.isNotEmpty) {
      ref
          .read(createQuoteProvider.notifier)
          .addConditions(_selectedConditions.toList());
    }

    final uri = Uri.parse(GoRouterState.of(context).uri.toString());
    final returnTo = uri.queryParameters['returnTo'];

    if (returnTo != null) {
      context.go(Uri.decodeComponent(returnTo));
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/quotes/create');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final conditionsAsync = ref.watch(commercialConditionsProvider);
    final quoteState = ref.watch(createQuoteProvider);
    final quoteNumber =
        quoteState.quote?.quoteNumber ?? quoteState.currentQuoteNumber ?? '';

    return GenericListScreen<CommercialCondition>(
      title: 'Agregar condiciones',
      subtitle: 'Cotización #$quoteNumber',
      itemsAsync: conditionsAsync,
      emptyListMessage: 'No hay condiciones predefinidas.',
      onSearch: (condition, query) =>
          condition.description.toLowerCase().contains(query.toLowerCase()),
      preFilter: (items) {
        final existingIds = ref
            .read(createQuoteProvider)
            .conditions
            .where((c) => c.conditionId != null)
            .map((c) => c.conditionId!)
            .toSet();
        return items.where((c) => !existingIds.contains(c.id)).toList();
      },
      headerWidget: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Agrega las condiciones que creas necesarias para que tu cliente las tenga en cuenta al momento de evaluar tu cotización',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const AddEditCommercialConditionSheet(),
                );
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: colors.outlineVariant),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                foregroundColor: colors.onSurface,
              ),
              child: const Text(
                'Agregar nueva condición comercial',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context, condition) {
        final isSelected = _selectedConditions.contains(condition);
        return CheckboxListTile(
          value: isSelected,
          onChanged: (val) => _toggleSelection(condition),
          title: Text(
            condition.description,
            style: TextStyle(color: colors.onSurface, fontSize: 16),
          ),
          controlAffinity: ListTileControlAffinity.trailing,
          activeColor: colors.primary,
          checkboxShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
        );
      },
      onAddPressed: _confirmSelection,
      fabLabel: _selectedConditions.isNotEmpty
          ? 'Confirmar (${_selectedConditions.length})'
          : 'Confirmar',
      fabIcon: Icons.check,
      isFabEnabled: _selectedConditions.isNotEmpty,
    );
  }
}
