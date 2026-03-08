import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/features/settings/data/models/shipping_company.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';

class ShippingCompaniesListScreen extends ConsumerStatefulWidget {
  const ShippingCompaniesListScreen({super.key});

  @override
  ConsumerState<ShippingCompaniesListScreen> createState() =>
      _ShippingCompaniesListScreenState();
}

class _ShippingCompaniesListScreenState
    extends ConsumerState<ShippingCompaniesListScreen> {
  SortOption _currentSort = SortOption.nameAZ;
  String _searchQuery = '';
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _buildForm({
    required TextEditingController legalNameController,
    required TextEditingController taxIdController,
    required TextEditingController nameController,
  }) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Razón Social *',
            controller: legalNameController,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'RIF / ID Fiscal *',
            controller: taxIdController,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Nombre comercial',
            controller: nameController,
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
    );
  }

  // ── Add ─────────────────────────────────────────────────────────────────────

  void _showAddCompanySheet() {
    final legalNameController = TextEditingController();
    final taxIdController = TextEditingController();
    final nameController = TextEditingController();

    CustomActionSheet.show(
      context: context,
      title: 'Agregar empresa',
      showDivider: true,
      isContentScrollable: true,
      content: _buildForm(
        legalNameController: legalNameController,
        taxIdController: taxIdController,
        nameController: nameController,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomButton(
                text: 'Confirmar',
                isFullWidth: false,
                onPressed: () async {
                  final legalName = legalNameController.text.trim();
                  final taxId = taxIdController.text.trim();
                  // If no commercial name, use legal name as fallback
                  final commercialName = nameController.text.trim().isEmpty
                      ? legalName
                      : nameController.text.trim();

                  if (legalName.isEmpty || taxId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'La Razón Social y el RIF son obligatorios.',
                        ),
                      ),
                    );
                    return;
                  }

                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final errorColor = Theme.of(context).colorScheme.onError;

                  try {
                    await ref
                        .read(lookupRepositoryProvider)
                        .addShippingCompany(
                          legalName: legalName,
                          taxId: taxId,
                          name: commercialName,
                        );
                    final _ = await ref.refresh(
                      shippingCompaniesProvider.future,
                    );
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Empresa "$legalName" agregada')),
                    );
                  } catch (e) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text(
                          'Error al agregar: $e',
                          style: TextStyle(color: errorColor),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Edit ─────────────────────────────────────────────────────────────────────

  void _showEditCompanySheet(ShippingCompany company) {
    final legalNameController = TextEditingController(text: company.legalName);
    final taxIdController = TextEditingController(text: company.taxId);
    final nameController = TextEditingController(text: company.name ?? '');

    // State to track if there are unsaved changes
    bool hasChanged = false;

    void updateHasChanged(StateSetter setState) {
      final currentLegalName = legalNameController.text.trim();
      final currentTaxId = taxIdController.text.trim();
      final currentName = nameController.text.trim();

      final previousLegalName = company.legalName;
      final previousTaxId = company.taxId;
      final previousName = company.name ?? '';

      final isChanged =
          currentLegalName != previousLegalName ||
          currentTaxId != previousTaxId ||
          currentName != previousName;

      if (hasChanged != isChanged) {
        setState(() => hasChanged = isChanged);
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            // Attach listeners once
            legalNameController.addListener(
              () => updateHasChanged(setSheetState),
            );
            taxIdController.addListener(() => updateHasChanged(setSheetState));
            nameController.addListener(() => updateHasChanged(setSheetState));

            return CustomActionSheet(
              title: 'Modificar empresa',
              showDivider: true,
              isContentScrollable: true,
              content: _buildForm(
                legalNameController: legalNameController,
                taxIdController: taxIdController,
                nameController: nameController,
              ),
              actions: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      // Delete action
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        onPressed: () async {
                          final scaffoldMessenger = ScaffoldMessenger.of(
                            context,
                          );
                          final navigator = Navigator.of(context);
                          final errorColor = Theme.of(
                            context,
                          ).colorScheme.onError;

                          navigator.pop();

                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Eliminar empresa'),
                              content: Text(
                                '¿Estás seguro de que deseas eliminar "${company.displayName}"?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.error,
                                  ),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Eliminar'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && mounted) {
                            try {
                              await ref
                                  .read(lookupRepositoryProvider)
                                  .deleteShippingCompany(company.id);
                              final _ = await ref.refresh(
                                shippingCompaniesProvider.future,
                              );
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Empresa "${company.displayName}" eliminada',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Error al eliminar: $e',
                                      style: TextStyle(color: errorColor),
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                      const Spacer(),
                      CustomButton(
                        text: 'Confirmar',
                        isFullWidth: false,
                        // Disable if no changes or if required fields are empty
                        onPressed: !hasChanged
                            ? null
                            : () async {
                                final legalName = legalNameController.text
                                    .trim();
                                final taxId = taxIdController.text.trim();
                                final commercialName =
                                    nameController.text.trim().isEmpty
                                    ? legalName
                                    : nameController.text.trim();

                                if (legalName.isEmpty || taxId.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'La Razón Social y el RIF son obligatorios.',
                                      ),
                                    ),
                                  );
                                  return;
                                }

                                final scaffoldMessenger = ScaffoldMessenger.of(
                                  context,
                                );
                                final navigator = Navigator.of(context);
                                final errorColor = Theme.of(
                                  context,
                                ).colorScheme.onError;

                                try {
                                  await ref
                                      .read(lookupRepositoryProvider)
                                      .updateShippingCompany(
                                        id: company.id,
                                        legalName: legalName,
                                        taxId: taxId,
                                        name: commercialName,
                                      );
                                  final _ = await ref.refresh(
                                    shippingCompaniesProvider.future,
                                  );
                                  navigator.pop();
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Empresa actualizada a "$legalName"',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error al actualizar: $e',
                                        style: TextStyle(color: errorColor),
                                      ),
                                    ),
                                  );
                                }
                              },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          },
        );
      },
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final companiesAsync = ref.watch(shippingCompaniesProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: StandardAppBar(
        backgroundColor: _isSearching ? colors.surfaceContainerHigh : null,
        title: 'Empresas de encomienda',
        customTitle: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar empresa...',
                  border: InputBorder.none,
                  fillColor: colors.surfaceContainerHigh,
                ),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: colors.onSurface,
                ),
                onChanged: (value) =>
                    setState(() => _searchQuery = value.toLowerCase()),
              )
            : null,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: Icon(Icons.search, color: colors.onSurface),
              onPressed: () => setState(() => _isSearching = true),
            )
          else
            IconButton(
              icon: Icon(Icons.close, color: colors.onSurface),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 40.0),
        child: CustomExtendedFab(
          onPressed: _showAddCompanySheet,
          label: 'Agregar',
          icon: Icons.add,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Registra las empresas de encomienda con las que trabajas que aún no estén verificadas en la plataforma.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.onSurface,
                height: 1.5,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: SortSelector(
              currentSort: _currentSort,
              options: const [SortOption.nameAZ, SortOption.nameZA],
              onSortChanged: (sort) {
                setState(() => _currentSort = sort);
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: companiesAsync.when(
              data: (companies) {
                // 1. Filter
                var filtered = companies.where((c) {
                  final currentUserId =
                      Supabase.instance.client.auth.currentUser?.id;
                  final isOwner = c.createdBy == currentUserId;
                  final query = _searchQuery.toLowerCase();
                  final matchesSearch =
                      (c.name?.toLowerCase().contains(query) ?? false) ||
                      c.legalName.toLowerCase().contains(query) ||
                      c.taxId.toLowerCase().contains(query);

                  return isOwner && matchesSearch;
                }).toList();

                // 2. Sort
                filtered.sort((a, b) {
                  final nameA = a.legalName;
                  final nameB = b.legalName;
                  if (_currentSort == SortOption.nameZA) {
                    return nameB.compareTo(nameA);
                  }
                  return nameA.compareTo(nameB);
                });

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No tienes empresas registradas',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final company = filtered[index];
                    final bool canEdit = !company.isVerified;
                    final displayName = company.legalName;
                    final subtitle = [
                      company.taxId,
                      if (company.name != null &&
                          company.name != company.legalName)
                        company.name!,
                    ].where((s) => s.isNotEmpty).join(' · ');

                    return ListTile(
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: canEdit
                                        ? colors.onSurface
                                        : colors.onSurface.withValues(
                                            alpha: 0.5,
                                          ),
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (company.isVerified) ...[
                            const SizedBox(width: 8),
                            Icon(
                              Icons.verified,
                              color: colors.primary.withValues(alpha: 0.5),
                              size: 16,
                            ),
                          ],
                        ],
                      ),
                      subtitle: subtitle.isNotEmpty
                          ? Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: canEdit
                                        ? colors.onSurfaceVariant
                                        : colors.onSurfaceVariant.withValues(
                                            alpha: 0.5,
                                          ),
                                  ),
                            )
                          : null,
                      onTap: canEdit
                          ? () => _showEditCompanySheet(company)
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
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) =>
                  const Center(child: Text('Error al cargar empresas')),
            ),
          ),
        ],
      ),
    );
  }
}
