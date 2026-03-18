import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/generic_list_screen.dart';
import 'package:d_una_app/shared/widgets/standard_list_item.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/features/portfolio/domain/models/unaffiliated_supplier_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/settings/presentation/widgets/add_edit_supplier_sheet.dart';

class UnaffiliatedSuppliersListScreen extends ConsumerWidget {
  const UnaffiliatedSuppliersListScreen({super.key});

  void _showAddSupplierSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => const AddEditSupplierSheet(),
    );
  }

  void _showEditSupplierSheet(BuildContext context, UnaffiliatedSupplier supplier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => AddEditSupplierSheet(supplier: supplier),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final suppliersAsync = ref.watch(unaffiliatedSuppliersProvider);

    return GenericListScreen<UnaffiliatedSupplier>(
      title: 'Proveedores no afiliados',
      descriptionText:
          'Registra los proveedores con los que trabajas aunque aún no estén en la plataforma.',
      itemsAsync: suppliersAsync,
      sortOptions: const [SortOption.nameAZ, SortOption.nameZA],
      initialSort: SortOption.nameAZ,
      onSearch: (s, query) {
        final q = query.toLowerCase();
        return s.name.toLowerCase().contains(q) ||
            (s.legalName?.toLowerCase().contains(q) ?? false) ||
            (s.taxId?.toLowerCase().contains(q) ?? false);
      },
      preFilter: (items) {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        return items.where((s) => s.userId == currentUserId).toList();
      },
      onSort: (a, b, sort) {
        final nameA = a.legalName ?? a.name;
        final nameB = b.legalName ?? b.name;
        if (sort == SortOption.nameZA) {
          return nameB.compareTo(nameA);
        }
        return nameA.compareTo(nameB);
      },
      onAddPressed: () => _showAddSupplierSheet(context),
      emptyListMessage: 'No tienes proveedores registrados',
      itemBuilder: (context, supplier) {
        final bool canEdit = !supplier.isVerified;
        final displayName = supplier.legalName ?? supplier.name;
        final subtitle = [
          if (supplier.taxId != null) supplier.taxId!,
          if (supplier.name != supplier.legalName && supplier.legalName != null)
            supplier.name,
        ].join(' · ');

        return Opacity(
          opacity: canEdit ? 1.0 : 0.5,
          child: StandardListItem(
            title: displayName,
            subtitle: subtitle.isNotEmpty
                ? Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  )
                : null,
            titleTrailing: supplier.isVerified
                ? Icon(Icons.verified, color: colors.primary, size: 20)
                : null,
            onTap: canEdit
                ? () => _showEditSupplierSheet(context, supplier)
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
                                  'Este proveedor ha sido verificado y ya no puede ser modificado ni eliminado.',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
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
