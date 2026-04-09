import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../../../../../shared/widgets/custom_search_bar.dart';
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
    final quoteNumber =
        ref.watch(createQuoteProvider).quote?.quoteNumber ?? '#C-00000011';

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: StandardAppBar(
        title: 'Agregar condiciones',
        subtitle: 'Cotización $quoteNumber',
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: GestureDetector(
              onTap: () async {
                final uri = Uri.parse(GoRouterState.of(context).uri.toString());
                final returnTo = uri.queryParameters['returnTo'];
                final quoteId = widget.quoteId;

                String searchPath;
                if (quoteId != null) {
                  searchPath = '/quotes/$quoteId/conditions/search';
                } else {
                  searchPath = '/quotes/create/conditions/search';
                }

                if (returnTo != null) {
                  searchPath = '$searchPath?returnTo=$returnTo';
                }

                final selected = await context.push<CommercialCondition>(
                  searchPath,
                );
                if (selected != null) {
                  _toggleSelection(selected);
                }
              },
              child: const CustomSearchBar(
                hintText: 'Buscar condición...',
                readOnly: true,
                onTap: null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: OutlinedButton(
              onPressed: () {
                // Add custom condition action
              },
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24.0),
                ),
              ),
              child: const Text('Agregar nueva condición comercial'),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: conditionsAsync.when(
              data: (conditions) {
                if (conditions.isEmpty) {
                  return const Center(
                    child: Text('No hay condiciones predefinidas.'),
                  );
                }

                // Exclude conditions already in the quote
                final existingIds = ref
                    .read(createQuoteProvider)
                    .conditions
                    .where((c) => c.conditionId != null)
                    .map((c) => c.conditionId!)
                    .toSet();

                final availableConditions = conditions
                    .where((c) => !existingIds.contains(c.id))
                    .toList();

                if (availableConditions.isEmpty) {
                  return const Center(
                    child: Text('Todas las condiciones ya han sido agregadas.'),
                  );
                }

                return ListView.separated(
                  itemCount: availableConditions.length,
                  padding: const EdgeInsets.only(bottom: 80), // Fab space
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1, color: Colors.transparent),
                  itemBuilder: (context, index) {
                    final condition = availableConditions[index];
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
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => FriendlyErrorWidget(error: err),
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: CustomExtendedFab(
          onPressed: _selectedConditions.isNotEmpty ? _confirmSelection : null,
          icon: Icons.check,
          label: _selectedConditions.isNotEmpty
              ? 'Confirmar (${_selectedConditions.length})'
              : 'Confirmar',
          isEnabled: _selectedConditions.isNotEmpty,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
