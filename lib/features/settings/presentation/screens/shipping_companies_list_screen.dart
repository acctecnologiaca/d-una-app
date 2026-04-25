import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/generic_list_screen.dart';
import 'package:d_una_app/shared/widgets/standard_list_item.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/features/settings/data/models/shipping_company.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/features/settings/presentation/widgets/add_edit_shipping_company_sheet.dart';

class ShippingCompaniesListScreen extends ConsumerWidget {
  const ShippingCompaniesListScreen({super.key});

  void _showAddCompanySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => const AddEditShippingCompanySheet(),
    );
  }

  void _showEditCompanySheet(BuildContext context, ShippingCompany company) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => AddEditShippingCompanySheet(company: company),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final companiesAsync = ref.watch(shippingCompaniesProvider);

    return GenericListScreen<ShippingCompany>(
      title: 'Empresas de encomienda',
      descriptionText:
          'Registra las empresas de encomienda con las que trabajas que aún no estén verificadas en la plataforma.',
      itemsAsync: companiesAsync,
      emptyListMessage: 'No tienes empresas registradas',
      onAddPressed: () => _showAddCompanySheet(context),
      sortOptions: const [SortOption.nameAZ, SortOption.nameZA],
      initialSort: SortOption.nameAZ,
      preFilter: (items) {
        final currentUserId = Supabase.instance.client.auth.currentUser?.id;
        return items.where((c) => c.userId == currentUserId).toList();
      },
      onSearch: (item, query) {
        final lowerQuery = query.toLowerCase();
        return (item.name?.toLowerCase().contains(lowerQuery) ?? false) ||
            item.legalName.toLowerCase().contains(lowerQuery) ||
            item.taxId.toLowerCase().contains(lowerQuery);
      },
      onSort: (a, b, sort) {
        final nameA = a.displayName;
        final nameB = b.displayName;
        if (sort == SortOption.nameZA) {
          return nameB.compareTo(nameA);
        }
        return nameA.compareTo(nameB);
      },
      itemBuilder: (context, company) {
        final bool canEdit = !company.isVerified;

        return Opacity(
          opacity: canEdit ? 1.0 : 0.5,
          child: StandardListItem(
            title: company.displayName,
            subtitle: Text(
              company.taxId,
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            titleTrailing: company.isVerified
                ? Icon(Icons.verified, color: colors.primary, size: 20)
                : null,
            onTap: canEdit
                ? () => _showEditCompanySheet(context, company)
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
                                  'Esta empresa ha sido verificada y ya no puede ser modificada ni eliminada.',
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
