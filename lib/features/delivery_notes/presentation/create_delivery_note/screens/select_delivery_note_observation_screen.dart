import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/generic_list_screen.dart';
import 'package:d_una_app/features/settings/data/models/observation.dart';
import 'package:d_una_app/features/settings/presentation/widgets/add_edit_observation_sheet.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import '../../../domain/models/delivery_note_observation_model.dart';
import '../providers/create_delivery_note_provider.dart';

class SelectDeliveryNoteObservationScreen extends ConsumerStatefulWidget {
  const SelectDeliveryNoteObservationScreen({super.key});

  @override
  ConsumerState<SelectDeliveryNoteObservationScreen> createState() =>
      _SelectDeliveryNoteObservationScreenState();
}

class _SelectDeliveryNoteObservationScreenState
    extends ConsumerState<SelectDeliveryNoteObservationScreen> {
  final Set<Observation> _selectedObservations = {};

  void _toggleSelection(Observation observation) {
    setState(() {
      if (_selectedObservations.contains(observation)) {
        _selectedObservations.remove(observation);
      } else {
        _selectedObservations.add(observation);
      }
    });
  }

  void _confirmSelection() {
    if (_selectedObservations.isNotEmpty) {
      final models = _selectedObservations.map((o) {
        return DeliveryNoteObservationModel(
          observationId: o.id,
          description: o.description,
        );
      }).toList();
      ref
          .read(createDeliveryNoteProvider.notifier)
          .addObservations(models);
    }

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final observationsAsync = ref.watch(observationsProvider);
    final noteState = ref.watch(createDeliveryNoteProvider);
    final noteNumber = noteState.deliveryNoteNumber ?? 'NE-...';

    return GenericListScreen<Observation>(
      title: 'Agregar observaciones',
      subtitle: 'Nota de entrega #$noteNumber',
      itemsAsync: observationsAsync,
      emptyListMessage: 'No hay observaciones predefinidas.',
      onSearch: (obs, query) =>
          obs.description.toLowerCase().contains(query.toLowerCase()),
      preFilter: (items) {
        final existingIds = ref
            .read(createDeliveryNoteProvider)
            .observations
            .where((o) => o.observationId != null)
            .map((o) => o.observationId!)
            .toSet();
        return items
            .where((o) => o.isActive && !existingIds.contains(o.id))
            .toList();
      },
      headerWidget: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Agrega las observaciones que consideres necesarias para que queden reflejadas en la nota de entrega.',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 14),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => const AddEditObservationSheet(),
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
                'Agregar nueva observación',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
      itemBuilder: (context, observation) {
        final isSelected = _selectedObservations.contains(observation);
        return CheckboxListTile(
          value: isSelected,
          onChanged: (val) => _toggleSelection(observation),
          title: Text(
            observation.description,
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
      fabLabel: _selectedObservations.isNotEmpty
          ? 'Confirmar (${_selectedObservations.length})'
          : 'Confirmar',
      fabIcon: Icons.check,
      isFabEnabled: _selectedObservations.isNotEmpty,
    );
  }
}
