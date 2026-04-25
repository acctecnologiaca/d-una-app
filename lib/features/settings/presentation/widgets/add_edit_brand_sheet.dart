import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/features/portfolio/data/models/brand_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/shared/utils/string_similarity.dart';

class AddEditBrandSheet extends ConsumerStatefulWidget {
  final Brand? brand;

  const AddEditBrandSheet({super.key, this.brand});

  static Future<Brand?> show(BuildContext context, {Brand? brand}) {
    return showModalBottomSheet<Brand>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => AddEditBrandSheet(brand: brand),
    );
  }

  @override
  ConsumerState<AddEditBrandSheet> createState() => _AddEditBrandSheetState();
}

class _AddEditBrandSheetState extends ConsumerState<AddEditBrandSheet> {
  late TextEditingController _nameController;
  bool _isLoading = false;
  bool _hasChanged = false;
  String? _errorText;

  bool get isEditing => widget.brand != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.brand?.name ?? '');
    _nameController.addListener(_updateHasChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _updateHasChanged() {
    // Clear inline error when user types
    if (_errorText != null) {
      setState(() => _errorText = null);
    }
    if (!isEditing) return;
    final isChanged = _nameController.text.trim() != widget.brand!.name;
    if (_hasChanged != isChanged) {
      setState(() => _hasChanged = isChanged);
    }
  }

  String _normalizeName(String name) {
    String withOutAccents = name
        .replaceAll(RegExp(r'[áàäâÁÀÄÂ]'), 'a')
        .replaceAll(RegExp(r'[éèëêÉÈËÊ]'), 'e')
        .replaceAll(RegExp(r'[íìïîÍÌÏÎ]'), 'i')
        .replaceAll(RegExp(r'[óòöôÓÒÖÔ]'), 'o')
        .replaceAll(RegExp(r'[úùüûÚÙÜÛ]'), 'u')
        .replaceAll(RegExp(r'[ñÑ]'), 'n');
    return withOutAccents.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    // Check for exact duplicates (normalized)
    final existingBrands = ref.read(brandsProvider).valueOrNull ?? [];
    final isDuplicate = existingBrands.any((b) {
      if (isEditing && b.id == widget.brand!.id) return false;
      return _normalizeName(b.name) == _normalizeName(name);
    });

    if (isDuplicate) {
      setState(() => _errorText = 'La marca "$name" ya existe.');
      return;
    }

    // Check for similar brands (fuzzy match)
    final similarBrand = StringSimilarity.findSimilar<Brand>(
      existingBrands,
      name,
      (b) => b.name,
      threshold: 0.70,
      excludeId: isEditing ? widget.brand!.id : null,
      idBuilder: (b) => b.id,
    );

    if (similarBrand != null) {
      if (!mounted) return;
      final shouldContinue = await CustomDialog.show<bool>(
        context: context,
        dialog: CustomDialog.confirmation(
          title: 'Marca similar detectada',
          contentText:
              'Ya existe una marca similar: "${similarBrand.name}".\n\n¿Estás seguro de que deseas agregar "$name"?',
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Corregir'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
      if (shouldContinue != true) return;
      if (!mounted) return;
    }

    setState(() => _isLoading = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final repo = ref.read(lookupRepositoryProvider);
      Brand? resultBrand;
      if (isEditing) {
        await repo.updateBrand(widget.brand!.id, name);
        resultBrand = Brand(
          id: widget.brand!.id,
          name: name,
          userId: widget.brand!.userId,
          isVerified: widget.brand!.isVerified,
        );
      } else {
        resultBrand = await repo.addBrand(name);
      }
      // Refresh the provider
      ref.invalidate(brandsProvider);
      navigator.pop(resultBrand);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            isEditing
                ? 'Marca actualizada a "$name"'
                : 'Marca "$name" agregada',
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Error: $e'),
        ),
      );
    }
  }

  Future<void> _delete() async {
    final colors = Theme.of(context).colorScheme;
    final confirm = await CustomDialog.show<bool>(
      context: context,
      dialog: CustomDialog.destructive(
        title: 'Eliminar marca',
        contentText:
            '¿Estás seguro de que deseas eliminar la marca "${widget.brand!.name}"?',
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

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ref.read(lookupRepositoryProvider).deleteBrand(widget.brand!.id);
      ref.invalidate(brandsProvider);
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Marca "${widget.brand!.name}" eliminada'),
        ),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Error: $e'),
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
      title: isEditing ? 'Modificar marca' : 'Agregar marca',
      showDivider: false,
      actions: actions,
      content: CustomTextField(
        label: 'Nombre de la marca',
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        autofocus: true,
        errorText: _errorText,
      ),
    );
  }
}
