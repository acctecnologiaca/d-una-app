import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/features/portfolio/data/models/service_rate_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';

class AddEditServiceRateSheet extends ConsumerStatefulWidget {
  final ServiceRate? rate;

  const AddEditServiceRateSheet({super.key, this.rate});

  @override
  ConsumerState<AddEditServiceRateSheet> createState() =>
      _AddEditServiceRateSheetState();
}

class _AddEditServiceRateSheetState
    extends ConsumerState<AddEditServiceRateSheet> {
  late TextEditingController _nameController;
  late TextEditingController _symbolController;
  bool _isLoading = false;
  bool _hasChanged = false;

  bool get isEditing => widget.rate != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.rate?.name ?? '');
    _symbolController = TextEditingController(text: widget.rate?.symbol ?? '');
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
    final r = widget.rate!;
    final isChanged =
        _nameController.text.trim() != r.name ||
        _symbolController.text.trim() != r.symbol;
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
        await repo.updateServiceRate(widget.rate!.id, name, symbol);
      } else {
        await repo.addServiceRate(name, symbol);
      }
      ref.invalidate(serviceRatesProvider);
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            isEditing
                ? 'Tarifa actualizada a "$name"'
                : 'Tarifa "$name" agregada',
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
        title: const Text('Eliminar tarifa'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la tarifa "${widget.rate!.name}"?',
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
      await ref
          .read(lookupRepositoryProvider)
          .deleteServiceRate(widget.rate!.id);
      ref.invalidate(serviceRatesProvider);
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text('Tarifa "${widget.rate!.name}" eliminada')),
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
      title: isEditing ? 'Modificar tarifa' : 'Agregar tarifa',
      showDivider: false,
      actions: actions,
      content: Column(
        children: [
          CustomTextField(
            label: 'Nombre (ej: Por hora)',
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            autofocus: true,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            label: 'Símbolo (ej: /hr)',
            controller: _symbolController,
          ),
        ],
      ),
    );
  }
}
