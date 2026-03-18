import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/generic_list_screen.dart';
import 'package:d_una_app/shared/widgets/standard_list_item.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/features/portfolio/data/models/uom_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/settings/presentation/widgets/add_edit_uom_sheet.dart';

class UomsListScreen extends ConsumerWidget {
  const UomsListScreen({super.key});

  void _showAddUomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => const AddEditUomSheet(),
    );
  }

  void _showEditUomSheet(BuildContext context, Uom uom) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => AddEditUomSheet(uom: uom),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final uomsAsync = ref.watch(uomsProvider);

    return GenericListScreen<Uom>(
      title: 'Unidades de medida',
      descriptionText:
          'Registra aquellas unidades de medidas que consideres necesarias para cotizar productos.',
      itemsAsync: uomsAsync,
      emptyListMessage: 'No tienes unidades de medida registradas',
      onAddPressed: () => _showAddUomSheet(context),
      sortOptions: const [SortOption.nameAZ, SortOption.nameZA],
      initialSort: SortOption.nameAZ,
      preFilter: (items) {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        return items.where((u) => u.userId == currentUserId).toList();
      },
      onSearch: (item, query) =>
          item.name.toLowerCase().contains(query.toLowerCase()) ||
          item.symbol.toLowerCase().contains(query.toLowerCase()),
      onSort: (a, b, sort) {
        if (sort == SortOption.nameZA) return b.name.compareTo(a.name);
        return a.name.compareTo(b.name);
      },
      itemBuilder: (context, uom) {
        final bool canEdit = !uom.isVerified;

        return Opacity(
          opacity: canEdit ? 1.0 : 0.5,
          child: StandardListItem(
            title: uom.name,
            subtitle: Text(
              uom.symbol,
              style: textTheme.bodySmall?.copyWith(
                color: canEdit
                    ? colors.onSurfaceVariant
                    : colors.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ),
            titleTrailing: uom.isVerified
                ? Icon(
                    Icons.verified,
                    color: colors.primary.withValues(alpha: 0.5),
                    size: 20,
                  )
                : null,
            onTap: canEdit
                ? () => _showEditUomSheet(context, uom)
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
                                  'Esta unidad ha sido verificada y ya no puede ser modificada ni eliminada.',
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
