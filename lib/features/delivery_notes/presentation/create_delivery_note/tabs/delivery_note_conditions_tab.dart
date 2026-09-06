import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import '../../../domain/models/delivery_note_observation_model.dart';
import '../providers/create_delivery_note_provider.dart';

class DeliveryNoteConditionsTab extends ConsumerStatefulWidget {
  const DeliveryNoteConditionsTab({super.key});

  @override
  ConsumerState<DeliveryNoteConditionsTab> createState() =>
      _DeliveryNoteConditionsTabState();
}

class _DeliveryNoteConditionsTabState
    extends ConsumerState<DeliveryNoteConditionsTab> {
  final TextEditingController _customConditionController =
      TextEditingController();

  @override
  void dispose() {
    _customConditionController.dispose();
    super.dispose();
  }

  void _addCustomCondition() {
    final text = _customConditionController.text.trim();
    if (text.isEmpty) return;

    ref.read(createDeliveryNoteProvider.notifier).addObservation(
          DeliveryNoteObservationModel(description: text),
        );
    _customConditionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(createDeliveryNoteProvider);
    final observations = state.observations;
    final conditionsAsync = ref.watch(commercialConditionsProvider);
    final allConditions = conditionsAsync.value ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Selector rápido de condiciones comerciales predefinidas
        if (allConditions.isNotEmpty) ...[
          Text(
            'Condiciones y términos predefinidos',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: allConditions.map((cond) {
              final isAlreadyAdded = observations.any(
                (o) => o.description.toLowerCase() == cond.description.toLowerCase(),
              );

              return FilterChip(
                label: Text(
                  cond.description.length > 40
                      ? '${cond.description.substring(0, 40)}...'
                      : cond.description,
                  style: TextStyle(
                    fontSize: 12,
                    color: isAlreadyAdded ? colors.onPrimary : colors.onSurface,
                  ),
                ),
                selected: isAlreadyAdded,
                selectedColor: colors.primary,
                checkmarkColor: colors.onPrimary,
                onSelected: (selected) {
                  if (selected) {
                    ref
                        .read(createDeliveryNoteProvider.notifier)
                        .addObservation(
                          DeliveryNoteObservationModel(
                            observationId: cond.id,
                            description: cond.description,
                          ),
                        );
                  } else {
                    final idx = observations.indexWhere(
                      (o) =>
                          o.description.toLowerCase() ==
                          cond.description.toLowerCase(),
                    );
                    if (idx != -1) {
                      ref
                          .read(createDeliveryNoteProvider.notifier)
                          .removeObservation(idx);
                    }
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
        ],

        // 2. Agregar condición personalizada
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: CustomTextField(
                controller: _customConditionController,
                label: 'Agregar observación personalizada',
                hintText: 'Ej. La garantía solo cubre defectos de fábrica...',
                maxLines: 2,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: IconButton.filled(
                onPressed: _addCustomCondition,
                icon: const Icon(Icons.add),
                tooltip: 'Agregar',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // 3. Lista de condiciones aplicadas
        Text(
          'Observaciones a incluir en la nota (${observations.length})',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),

        if (observations.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                'No se han agregado observaciones o términos de entrega.',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: observations.length,
            onReorder: (oldIndex, newIndex) {
              ref
                  .read(createDeliveryNoteProvider.notifier)
                  .reorderObservations(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final obs = observations[index];
              return Card(
                key: ValueKey('obs_${index}_${obs.description.hashCode}'),
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: colors.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: ListTile(
                  leading: const Icon(Icons.drag_handle, size: 20),
                  title: Text(
                    obs.description,
                    style: const TextStyle(fontSize: 13),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    color: colors.error,
                    onPressed: () {
                      ref
                          .read(createDeliveryNoteProvider.notifier)
                          .removeObservation(index);
                    },
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 40),
      ],
    );
  }
}
