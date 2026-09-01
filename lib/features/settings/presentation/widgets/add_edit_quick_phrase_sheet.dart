import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/features/portfolio/data/models/category_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/core/utils/error_handler.dart';
import '../../data/models/quick_phrase.dart';
import '../providers/quick_phrases_provider.dart';

const _allCategoriesOption = Category(
  id: '',
  name: 'Todas las categorías (General)',
  type: 'service',
);

class AddEditQuickPhraseSheet extends ConsumerStatefulWidget {
  final QuickPhrase? quickPhrase;
  final QuickPhraseFieldType? defaultFieldType;
  final String? defaultCategoryId;

  const AddEditQuickPhraseSheet({
    super.key,
    this.quickPhrase,
    this.defaultFieldType,
    this.defaultCategoryId,
  });

  static Future<void> show(
    BuildContext context, {
    QuickPhrase? quickPhrase,
    QuickPhraseFieldType? defaultFieldType,
    String? defaultCategoryId,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => AddEditQuickPhraseSheet(
        quickPhrase: quickPhrase,
        defaultFieldType: defaultFieldType,
        defaultCategoryId: defaultCategoryId,
      ),
    );
  }

  @override
  ConsumerState<AddEditQuickPhraseSheet> createState() =>
      _AddEditQuickPhraseSheetState();
}

class _AddEditQuickPhraseSheetState
    extends ConsumerState<AddEditQuickPhraseSheet> {
  late TextEditingController _phraseController;
  late QuickPhraseFieldType _selectedFieldType;
  String? _selectedCategoryId;
  bool _isLoading = false;
  bool _hasChanged = false;

  bool get isEditing => widget.quickPhrase != null;

  @override
  void initState() {
    super.initState();
    final p = widget.quickPhrase;
    _phraseController = TextEditingController(text: p?.phrase ?? '');
    _selectedFieldType =
        p?.fieldType ?? widget.defaultFieldType ?? QuickPhraseFieldType.request;
    _selectedCategoryId = p?.categoryId ?? widget.defaultCategoryId;

    _phraseController.addListener(_updateHasChanged);
  }

  @override
  void dispose() {
    _phraseController.dispose();
    super.dispose();
  }

  void _updateHasChanged() {
    if (!isEditing) return;

    final p = widget.quickPhrase!;
    final isChanged =
        _phraseController.text.trim() != p.phrase ||
        _selectedFieldType != p.fieldType ||
        _selectedCategoryId != p.categoryId;

    if (_hasChanged != isChanged) {
      setState(() => _hasChanged = isChanged);
    }
  }

  Future<void> _save() async {
    final phrase = _phraseController.text.trim();
    if (phrase.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(quickPhrasesRepositoryProvider);
      if (isEditing) {
        await repo.updateQuickPhrase(
          id: widget.quickPhrase!.id,
          fieldType: _selectedFieldType,
          phrase: phrase,
          categoryId: _selectedCategoryId,
        );
      } else {
        await repo.addQuickPhrase(
          fieldType: _selectedFieldType,
          phrase: phrase,
          categoryId: _selectedCategoryId,
        );
      }

      ref.invalidate(quickPhrasesProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              isEditing ? 'Frase actualizada' : 'Frase agregada exitosamente',
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
        title: 'Eliminar frase',
        contentText:
            '¿Estás seguro de que deseas eliminar esta frase de acceso rápido?',
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
          .read(quickPhrasesRepositoryProvider)
          .deleteQuickPhrase(widget.quickPhrase!.id);
      ref.invalidate(quickPhrasesProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Frase eliminada'),
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
    final categoriesAsync = ref.watch(categoriesProvider);

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
              onPressed: _phraseController.text.trim().isNotEmpty &&
                      (!isEditing || _hasChanged)
                  ? _save
                  : null,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ];

    return CustomActionSheet(
      title: isEditing ? 'Editar frase rápida' : 'Nueva frase rápida',
      showDivider: false,
      actions: actions,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // 1. Selector de Campo
          CustomDropdown<QuickPhraseFieldType>(
            label: 'Campo de destino',
            value: _selectedFieldType,
            items: QuickPhraseFieldType.values,
            itemLabelBuilder: (f) => f.label,
            onChanged: (f) {
              if (f != null) {
                setState(() {
                  _selectedFieldType = f;
                  _updateHasChanged();
                });
              }
            },
          ),
          const SizedBox(height: 16),

          // 2. Selector de Categoría
          categoriesAsync.when(
            data: (categories) {
              final isCategoryInactive = _selectedCategoryId != null &&
                  !categories.any((c) => c.id == _selectedCategoryId);

              final List<Category> categoryOptions = [
                _allCategoriesOption,
                ...categories,
              ];

              Category selectedCategory = _allCategoriesOption;
              if (_selectedCategoryId != null) {
                final match = categories.where(
                  (c) => c.id == _selectedCategoryId,
                );
                if (match.isNotEmpty) {
                  selectedCategory = match.first;
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomDropdown<Category>(
                    label: 'Categoría',
                    value: selectedCategory,
                    items: categoryOptions,
                    itemLabelBuilder: (c) => c.name,
                    onChanged: (c) {
                      setState(() {
                        _selectedCategoryId =
                            (c != null && c.id.isNotEmpty) ? c.id : null;
                        _updateHasChanged();
                      });
                    },
                  ),
                  if (isCategoryInactive) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.errorContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.error.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            size: 20,
                            color: colors.error,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Categoría no disponible en tu rubro actual. Puedes reasignarla a una de tus categorías activas o a "Todas las categorías".',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onErrorContainer,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
            loading: () => const CustomDropdown<String>(
              label: 'Categoría',
              value: null,
              items: [],
              itemLabelBuilder: _dummyLabel,
              enabled: false,
            ),
            error: (err, _) => Text(
              'Error al cargar categorías: $err',
              style: TextStyle(color: colors.error, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Campo de Texto de la Frase
          CustomTextField(
            label: 'Texto de la frase*',
            controller: _phraseController,
            helperText:
                'Frase que se insertará al tocar el botón de acceso rápido.',
            maxLength: 250,
            maxLines: 3,
            onChanged: (_) => _updateHasChanged(),
          ),
        ],
      ),
    );
  }
}

String _dummyLabel(String s) => s;
