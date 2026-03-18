import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/generic_list_screen.dart';
import 'package:d_una_app/shared/widgets/standard_list_item.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/features/portfolio/data/models/category_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/settings/presentation/widgets/add_edit_category_sheet.dart';

class CategoriesListScreen extends ConsumerWidget {
  const CategoriesListScreen({super.key});

  void _showAddCategorySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => const AddEditCategorySheet(),
    );
  }

  void _showEditCategorySheet(BuildContext context, Category category) {
    showModalBottomSheet(
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final categoriesAsync = ref.watch(categoriesProvider);

    return GenericListScreen<Category>(
      title: 'Categorías',
      descriptionText:
          'Establece las categorías que quieras usar, estas te ayudarán a clasificar las cotizaciones, reportes y otros.',
      itemsAsync: categoriesAsync,
      emptyListMessage: 'No tienes categorías registradas',
      onAddPressed: () => _showAddCategorySheet(context),
      sortOptions: const [SortOption.nameAZ, SortOption.nameZA],
      initialSort: SortOption.nameAZ,
      preFilter: (items) {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        return items.where((c) => c.userId == currentUserId).toList();
      },
      onSearch: (item, query) =>
          item.name.toLowerCase().contains(query.toLowerCase()),
      onSort: (a, b, sort) {
        if (sort == SortOption.nameZA) return b.name.compareTo(a.name);
        return a.name.compareTo(b.name);
      },
      itemBuilder: (context, category) {
        final bool canEdit = !category.isVerified;

        return Opacity(
          opacity: canEdit ? 1.0 : 0.5,
          child: StandardListItem(
            title: category.name,
            titleTrailing: category.isVerified
                ? Icon(
                    Icons.verified,
                    color: colors.primary.withValues(alpha: 0.5),
                    size: 20,
                  )
                : null,
            onTap: canEdit
                ? () => _showEditCategorySheet(context, category)
                : () {
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 5),
                          content: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Esta categoría ha sido verificada y ya no puede ser modificada ni eliminada.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => ScaffoldMessenger.of(
                                  context,
                                ).hideCurrentSnackBar(),
                              ),
                            ],
                          ),
                        ),
                      );
                  },
          ),
        );
      },
    );
  }
}
