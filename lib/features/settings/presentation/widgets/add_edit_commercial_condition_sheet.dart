import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/features/quotes/data/models/commercial_condition.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';

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

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

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
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            isEditing
                ? 'Condición actualizada'
                : 'Condición "$description" agregada',
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
          title: const Text('Eliminar condición'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar esta condición comercial?',
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
    final errorColor = Theme.of(context).colorScheme.onError;

    try {
      await ref
          .read(lookupRepositoryProvider)
          .deleteCommercialCondition(widget.condition!.id);
      ref.invalidate(commercialConditionsProvider);
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Condición eliminada')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error: $e', style: TextStyle(color: errorColor)),
        ),
      );
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
      actions: actions,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          CustomTextField(
            label: 'Condición comercial',
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
