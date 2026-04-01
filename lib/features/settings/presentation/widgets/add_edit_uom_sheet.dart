import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/features/portfolio/data/models/uom_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';

class AddEditUomSheet extends ConsumerStatefulWidget {
  final Uom? uom;

  const AddEditUomSheet({super.key, this.uom});

  @override
  ConsumerState<AddEditUomSheet> createState() => _AddEditUomSheetState();
}

class _AddEditUomSheetState extends ConsumerState<AddEditUomSheet> {
  late TextEditingController _nameController;
  late TextEditingController _symbolController;
  bool _isLoading = false;
  bool _hasChanged = false;

  bool get isEditing => widget.uom != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.uom?.name ?? '');
    _symbolController = TextEditingController(text: widget.uom?.symbol ?? '');
    _nameController.addListener(_updateHasChanged);
    _symbolController.addListener(_updateHasChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    super.dispose();
  }

  void _updateHasChanged() {
    if (!isEditing) return;
    final u = widget.uom!;
    final isChanged =
        _nameController.text.trim() != u.name ||
        _symbolController.text.trim() != u.symbol;
    if (_hasChanged != isChanged) {
      setState(() => _hasChanged = isChanged);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    final symbol = _symbolController.text.trim();
    if (name.isEmpty || symbol.isEmpty) return;

    setState(() => _isLoading = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final repo = ref.read(lookupRepositoryProvider);
      if (isEditing) {
        await repo.updateUom(widget.uom!.id, name, symbol);
      } else {
        await repo.addUom(name, symbol);
      }
      ref.invalidate(uomsProvider);
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            isEditing
                ? 'Unidad actualizada a "$name"'
                : 'Unidad "$name" agregada',
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      scaffoldMessenger.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text('Error: $e')));
    }
  }

  Future<void> _delete() async {
    final colors = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar unidad de medida'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la unidad "${widget.uom!.name}"?',
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
      ),
    );

    if (confirm != true || !mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ref.read(lookupRepositoryProvider).deleteUom(widget.uom!.id);
      ref.invalidate(uomsProvider);
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text('Unidad "${widget.uom!.name}" eliminada')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text('Error: $e')));
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
      title: isEditing
          ? 'Modificar unidad de medida'
          : 'Agregar unidad de medida',
      showDivider: false,
      actions: actions,
      content: Column(
        children: [
          CustomTextField(
            label: 'Nombre (ej: Kilogramo)',
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Símbolo (ej: kg)',
            controller: _symbolController,
          ),
        ],
      ),
    );
  }
}
