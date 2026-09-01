import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/generic_list_screen.dart';
import 'package:d_una_app/shared/widgets/standard_list_item.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/shared/widgets/filter_bottom_sheet.dart';
import 'package:d_una_app/shared/widgets/horizontal_filter_bar.dart';
import 'package:d_una_app/features/portfolio/data/models/category_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import '../../data/models/quick_phrase.dart';
import '../providers/quick_phrases_provider.dart';
import '../widgets/add_edit_quick_phrase_sheet.dart';

const String _allCategoryKey = '__all__';

class QuickPhrasesListScreen extends ConsumerStatefulWidget {
  const QuickPhrasesListScreen({super.key});

  @override
  ConsumerState<QuickPhrasesListScreen> createState() =>
      _QuickPhrasesListScreenState();
}

class _QuickPhrasesListScreenState
    extends ConsumerState<QuickPhrasesListScreen> {
  final Set<QuickPhraseFieldType> _selectedFields = {};
  final Set<String> _selectedCategoryIds = {};

  void _showAddSheet(BuildContext context) {
    QuickPhraseFieldType? defaultField;
    if (_selectedFields.length == 1) {
      defaultField = _selectedFields.first;
    }
    String? defaultCatId;
    if (_selectedCategoryIds.length == 1 &&
        !_selectedCategoryIds.contains(_allCategoryKey)) {
      defaultCatId = _selectedCategoryIds.first;
    }

    AddEditQuickPhraseSheet.show(
      context,
      defaultFieldType: defaultField,
      defaultCategoryId: defaultCatId,
    );
  }

  void _showEditSheet(BuildContext context, QuickPhrase phrase) {
    AddEditQuickPhraseSheet.show(context, quickPhrase: phrase);
  }

  void _showFieldsFilter() {
    FilterBottomSheet.showMulti(
      context: context,
      title: 'Campos',
      options: QuickPhraseFieldType.values.map((f) => f.dbValue).toList(),
      selectedValues: _selectedFields.map((f) => f.dbValue).toSet(),
      labelBuilder: (dbVal) => QuickPhraseFieldType.fromString(dbVal).label,
      sortOptions: false,
      onApply: (selected) {
        setState(() {
          _selectedFields.clear();
          _selectedFields.addAll(
            selected.map((v) => QuickPhraseFieldType.fromString(v)),
          );
        });
      },
    );
  }

  void _showCategoriesFilter(List<Category> activeCategories) {
    final options = [_allCategoryKey, ...activeCategories.map((c) => c.id)];

    FilterBottomSheet.showMulti(
      context: context,
      title: 'Categorías',
      options: options,
      selectedValues: _selectedCategoryIds,
      sortOptions: false,
      labelBuilder: (id) {
        if (id == _allCategoryKey) {
          return 'Todas las categorías (General)';
        }
        final match = activeCategories.where((c) => c.id == id);
        return match.isNotEmpty ? match.first.name : 'Categoría no disponible';
      },
      onApply: (selected) {
        setState(() {
          _selectedCategoryIds.clear();
          _selectedCategoryIds.addAll(selected);
        });
      },
    );
  }

  String _getFieldsChipLabel() {
    return HorizontalFilterBar.formatLabel(
      defaultLabel: 'Campos',
      selectedValues: _selectedFields.map((f) => f.dbValue).toList(),
      valueToLabelMap: {
        for (final f in QuickPhraseFieldType.values) f.dbValue: f.shortLabel,
      },
    );
  }

  String _getCategoriesChipLabel(List<Category> activeCategories) {
    final map = {
      _allCategoryKey: 'General',
      for (final c in activeCategories) c.id: c.name,
    };
    return HorizontalFilterBar.formatLabel(
      defaultLabel: 'Categoría',
      selectedValues: _selectedCategoryIds.toList(),
      valueToLabelMap: map,
    );
  }

  @override
  Widget build(BuildContext context) {
    final phrasesAsync = ref.watch(quickPhrasesProvider);
    final categoriesAsync = ref.watch(categoriesProvider);

    final activeCategories = categoriesAsync.valueOrNull ?? [];

    return GenericListScreen<QuickPhrase>(
      title: 'Frases de acceso rápido',
      descriptionText:
          'Configura frases predefinidas organizadas por campo y categoría para agilizar la redacción técnica en tus reportes de servicio.',
      itemsAsync: phrasesAsync,
      emptyListMessage: 'No tienes frases registradas para este filtro',
      onAddPressed: () => _showAddSheet(context),
      sortOptions: const [SortOption.nameAZ, SortOption.nameZA],
      initialSort: SortOption.nameAZ,
      onSearch: (item, query) =>
          item.phrase.toLowerCase().contains(query.toLowerCase()) ||
          (item.categoryName?.toLowerCase().contains(query.toLowerCase()) ??
              false),
      onSort: (a, b, sort) {
        if (sort == SortOption.nameZA) {
          return b.phrase.compareTo(a.phrase);
        }
        return a.phrase.compareTo(b.phrase);
      },
      headerWidget: HorizontalFilterBar(
        filters: [
          FilterChipData(
            label: _getFieldsChipLabel(),
            isActive: _selectedFields.isNotEmpty,
            onTap: _showFieldsFilter,
          ),
          FilterChipData(
            label: _getCategoriesChipLabel(activeCategories),
            isActive: _selectedCategoryIds.isNotEmpty,
            onTap: () => _showCategoriesFilter(activeCategories),
          ),
        ],
        onResetFilters:
            (_selectedFields.isNotEmpty || _selectedCategoryIds.isNotEmpty)
                ? () {
                    setState(() {
                      _selectedFields.clear();
                      _selectedCategoryIds.clear();
                    });
                  }
                : null,
      ),
      preFilter: (items) {
        return items.where((phrase) {
          // Filter by fields (if any selected)
          if (_selectedFields.isNotEmpty &&
              !_selectedFields.contains(phrase.fieldType)) {
            return false;
          }
          // Filter by category (if any selected)
          if (_selectedCategoryIds.isNotEmpty) {
            final phraseCatKey = phrase.categoryId ?? _allCategoryKey;
            if (!_selectedCategoryIds.contains(phraseCatKey)) {
              return false;
            }
          }
          return true;
        }).toList();
      },
      itemBuilder: (context, phrase) {
        final colors = Theme.of(context).colorScheme;
        final bool isCategoryInactive =
            phrase.categoryId != null &&
            !activeCategories.any((c) => c.id == phrase.categoryId);

        final categoryLabel = isCategoryInactive
            ? (phrase.categoryName != null
                  ? '${phrase.categoryName} (No disponible)'
                  : 'Categoría no disponible')
            : (phrase.categoryName ?? 'Todas las categorías');

        return StandardListItem(
          title: phrase.phrase,
          subtitle: Text('${phrase.fieldType.shortLabel} • $categoryLabel'),
          trailing: isCategoryInactive
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colors.errorContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Categoría no disponible',
                    style: TextStyle(
                      color: colors.onErrorContainer,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
              : null,
          onTap: () => _showEditSheet(context, phrase),
        );
      },
    );
  }
}
