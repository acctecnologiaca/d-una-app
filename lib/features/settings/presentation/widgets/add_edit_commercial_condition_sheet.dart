import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/features/quotes/data/models/commercial_condition.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/core/utils/error_handler.dart';

class AddEditCommercialConditionSheet extends ConsumerStatefulWidget {
  final CommercialCondition? condition;

  const AddEditCommercialConditionSheet({super.key, this.condition});

  @override
  ConsumerState<AddEditCommercialConditionSheet> createState() =>
      _AddEditCommercialConditionSheetState();
}

class _AddEditCommercialConditionSheetState
    extends ConsumerState<AddEditCommercialConditionSheet> {
  late TextEditingController _descriptionController;
  bool _isDefaultQuote = false;
  bool _isDefaultReport = false;
  bool _isLoading = false;
  bool _hasChanged = false;

  bool get isEditing => widget.condition != null;

  @override
  void initState() {
    super.initState();
    final c = widget.condition;
    _descriptionController = TextEditingController(text: c?.description ?? '');
    if (c != null) {
      _isDefaultQuote = c.isDefaultQuote;
      _isDefaultReport = c.isDefaultReport;
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

    final c = widget.condition!;
    final isChanged =
        _descriptionController.text.trim() != c.description ||
        _isDefaultQuote != c.isDefaultQuote ||
        _isDefaultReport != c.isDefaultReport;

    if (_hasChanged != isChanged) {
      setState(() => _hasChanged = isChanged);
    }
  }

  Future<void> _save() async {
    final description = _descriptionController.text.trim();
    if (description.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(lookupRepositoryProvider);
      if (isEditing) {
        await repo.updateCommercialCondition(
          id: widget.condition!.id,
          description: description,
          isDefaultQuote: _isDefaultQuote,
          isDefaultReport: _isDefaultReport,
        );
      } else {
        await repo.addCommercialCondition(
          description: description,
          isDefaultQuote: _isDefaultQuote,
          isDefaultReport: _isDefaultReport,
        );
      }
      ref.invalidate(commercialConditionsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              isEditing
                  ? 'Condición actualizada'
                  : 'Condición "$description" agregada',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ErrorHandler.showErrorSnackBar(context, e);
      }
    }
  }

  Future<void> _delete() async {
    final colors = Theme.of(context).colorScheme;
    final confirm = await CustomDialog.show<bool>(
      context: context,
      dialog: CustomDialog.destructive(
        title: 'Eliminar condición',
        contentText:
            '¿Estás seguro de que deseas eliminar esta condición comercial?',
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      await ref
          .read(lookupRepositoryProvider)
          .deleteCommercialCondition(widget.condition!.id);
      ref.invalidate(commercialConditionsProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Condición eliminada'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e);
      }
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
      title: isEditing ? 'Modificar condición' : 'Agregar condición',
      showDivider: false,
      actions: actions,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Condición comercial',
            helperText: 'Ej: 50% de anticipo y 50% contra entrega.',
            controller: _descriptionController,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 16),
          Text(
            'Agregar por defecto en',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Cotizaciones nuevas'),
            value: _isDefaultQuote,
            onChanged: (value) {
              setState(() {
                _isDefaultQuote = value;
                _updateHasChanged();
              });
            },
          ),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reportes de servicios nuevos'),
            value: _isDefaultReport,
            onChanged: (value) {
              setState(() {
                _isDefaultReport = value;
                _updateHasChanged();
              });
            },
          ),
        ],
      ),
    );
  }
}
