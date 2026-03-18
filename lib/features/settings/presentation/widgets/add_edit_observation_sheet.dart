import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/features/settings/data/models/observation.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';

class AddEditObservationSheet extends ConsumerStatefulWidget {
  final Observation? observation;

  const AddEditObservationSheet({super.key, this.observation});

  @override
  ConsumerState<AddEditObservationSheet> createState() =>
      _AddEditObservationSheetState();
}

class _AddEditObservationSheetState
    extends ConsumerState<AddEditObservationSheet> {
  late TextEditingController _descriptionController;
  bool _isDefaultDeliveryNote = false;
  bool _isLoading = false;
  bool _hasChanged = false;

  bool get isEditing => widget.observation != null;

  @override
  void initState() {
    super.initState();
    final o = widget.observation;
    _descriptionController = TextEditingController(text: o?.description ?? '');
    if (o != null) {
      _isDefaultDeliveryNote = o.isDefaultDeliveryNote;
    }
    _descriptionController.addListener(_updateHasChanged);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _updateHasChanged() {
    if (!isEditing) return;

    final o = widget.observation!;
    final isChanged =
        _descriptionController.text.trim() != o.description ||
        _isDefaultDeliveryNote != o.isDefaultDeliveryNote;

    if (_hasChanged != isChanged) {
      setState(() => _hasChanged = isChanged);
    }
  }

  Future<void> _save() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) return;

    setState(() => _isLoading = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final repo = ref.read(lookupRepositoryProvider);
      if (isEditing) {
        await repo.updateObservation(
          id: widget.observation!.id,
          description: description,
          isDefaultDeliveryNote: _isDefaultDeliveryNote,
        );
      } else {
        await repo.addObservation(
          description: description,
          isDefaultDeliveryNote: _isDefaultDeliveryNote,
        );
      }
      ref.invalidate(observationsProvider);
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            isEditing ? 'Observación actualizada' : 'Observación agregada',
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colors = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Eliminar observación'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar esta observación?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: colors.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ref
          .read(lookupRepositoryProvider)
          .deleteObservation(widget.observation!.id);
      ref.invalidate(observationsProvider);
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Observación eliminada')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final actions = <Widget>[
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: isEditing
              ? MainAxisAlignment.start
              : MainAxisAlignment.end,
          children: [
            if (isEditing)
              IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  color: colors.onSurfaceVariant,
                ),
                onPressed: _delete,
              ),
            if (isEditing) const Spacer(),
            CustomButton(
              text: 'Confirmar',
              isFullWidth: false,
              isLoading: _isLoading,
              onPressed: (!isEditing || _hasChanged) ? _save : null,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ];

    return CustomActionSheet(
      title: isEditing ? 'Modificar observación' : 'Agregar observación',
      showDivider: false,
      actions: actions,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomTextField(
            label: 'Observación',
            controller: _descriptionController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          Text(
            'Agregar por defecto',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Notas de entrega nuevas'),
            value: _isDefaultDeliveryNote,
            onChanged: (value) {
              setState(() {
                _isDefaultDeliveryNote = value;
                _updateHasChanged();
              });
            },
          ),
        ],
      ),
    );
  }
}
