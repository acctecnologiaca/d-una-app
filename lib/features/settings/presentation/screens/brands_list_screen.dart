import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/generic_list_screen.dart';
import 'package:d_una_app/shared/widgets/standard_list_item.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/features/portfolio/data/models/brand_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/settings/presentation/widgets/add_edit_brand_sheet.dart';

class BrandsListScreen extends ConsumerWidget {
  const BrandsListScreen({super.key});

  void _showAddBrandSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => const AddEditBrandSheet(),
    );
  }

  void _showEditBrandSheet(BuildContext context, Brand brand) {
    showModalBottomSheet(
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
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final brandsAsync = ref.watch(brandsProvider);

    return GenericListScreen<Brand>(
      title: 'Marcas de productos',
      descriptionText:
          'Registra las marcas de aquellos productos, que no veas listadas aún en nuestra plataforma.',
      itemsAsync: brandsAsync,
      emptyListMessage: 'No tienes marcas registradas',
      onAddPressed: () => _showAddBrandSheet(context),
      sortOptions: const [SortOption.nameAZ, SortOption.nameZA],
      initialSort: SortOption.nameAZ,
      preFilter: (items) {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        return items.where((b) => b.userId == currentUserId).toList();
      },
      onSearch: (item, query) =>
          item.name.toLowerCase().contains(query.toLowerCase()),
      onSort: (a, b, sort) {
        if (sort == SortOption.nameZA) return b.name.compareTo(a.name);
        return a.name.compareTo(b.name);
      },
      itemBuilder: (context, brand) {
        final bool canEdit = !brand.isVerified;

        return Opacity(
          opacity: canEdit ? 1.0 : 0.5,
          child: StandardListItem(
            title: brand.name,
            titleTrailing: brand.isVerified
                ? Icon(
                    Icons.verified,
                    color: colors.primary.withValues(alpha: 0.5),
                    size: 20,
                  )
                : null,
            onTap: canEdit
                ? () => _showEditBrandSheet(context, brand)
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
                                  'Esta marca ha sido verificada y ya no puede ser modificada ni eliminada.',
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
