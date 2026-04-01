import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/features/portfolio/data/models/category_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/shared/utils/string_similarity.dart';

class AddEditCategorySheet extends ConsumerStatefulWidget {
  final Category? category;

  const AddEditCategorySheet({super.key, this.category});

  static Future<Category?> show(BuildContext context, {Category? category}) {
    return showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => AddEditCategorySheet(category: category),
    );
  }

  @override
  ConsumerState<AddEditCategorySheet> createState() =>
      _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends ConsumerState<AddEditCategorySheet> {
  late TextEditingController _nameController;
  bool _isLoading = false;
  bool _hasChanged = false;
  String? _errorText;

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
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
    final isChanged = _nameController.text.trim() != widget.category!.name;
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
    final existingCategories = ref.read(categoriesProvider).valueOrNull ?? [];
    final isDuplicate = existingCategories.any((c) {
      if (isEditing && c.id == widget.category!.id) return false;
      return _normalizeName(c.name) == _normalizeName(name);
    });

    if (isDuplicate) {
      setState(() => _errorText = 'La categoría "$name" ya existe.');
      return;
    }

    // Check for similar categories (fuzzy match) against verified ones
    final normalizedTarget = _normalizeName(name);
    final similarCategory = StringSimilarity.findSimilar<Category>(
      existingCategories.where((c) => c.isVerified).toList(),
      normalizedTarget,
      (c) => _normalizeName(c.name),
      threshold: 0.75,
      excludeId: isEditing ? widget.category!.id : null,
      idBuilder: (c) => c.id,
    );

    if (similarCategory != null) {
      setState(
        () => _errorText =
            'Muy similar a la categoría oficial "${similarCategory.name}".',
      );
      return;
    }

    setState(() => _isLoading = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final repo = ref.read(lookupRepositoryProvider);
      Category? resultCategory;
      if (isEditing) {
        await repo.updateCategory(widget.category!.id, name);
        resultCategory = Category(
          id: widget.category!.id,
          name: name,
          type: widget.category!.type,
        );
      } else {
        resultCategory = await repo.addCategory(name);
      }
      ref.invalidate(categoriesProvider);
      navigator.pop(resultCategory);
      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            isEditing
                ? 'Categoría actualizada a "$name"'
                : 'Categoría "$name" agregada',
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);

      // Handle specific database similarity error
      final errorMessage = e.toString();
      if (errorMessage.contains('similar a la categoría oficial')) {
        // Try to extract the official category name from the message
        final regExp = RegExp(r'oficial "(.*?)"');
        final match = regExp.firstMatch(errorMessage);
        final officialName = match?.group(1);

        setState(() {
          _errorText = officialName != null
              ? 'Muy similar a la categoría oficial "$officialName".'
              : 'El nombre es muy similar a una categoría oficial.';
        });
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Error: $e'),
          ),
        );
      }
    }
  }

  Future<void> _delete() async {
    final colors = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoría'),
        content: Text(
          '¿Estás seguro de que deseas eliminar la categoría "${widget.category!.name}"?',
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
          .deleteCategory(widget.category!.id);
      ref.invalidate(categoriesProvider);
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text('Categoría "${widget.category!.name}" eliminada'),
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
      title: isEditing ? 'Modificar categoría' : 'Agregar categoría',
      showDivider: false,
      actions: actions,
      content: CustomTextField(
        label: 'Nombre de la categoría',
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        autofocus: true,
        errorText: _errorText,
      ),
    );
  }
}
