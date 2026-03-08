import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/features/portfolio/domain/models/unaffiliated_supplier_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';

class UnaffiliatedSuppliersListScreen extends ConsumerStatefulWidget {
  const UnaffiliatedSuppliersListScreen({super.key});

  @override
  ConsumerState<UnaffiliatedSuppliersListScreen> createState() =>
      _UnaffiliatedSuppliersListScreenState();
}

class _UnaffiliatedSuppliersListScreenState
    extends ConsumerState<UnaffiliatedSuppliersListScreen> {
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
    required TextEditingController phoneController,
    required TextEditingController emailController,
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
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Teléfono',
            controller: phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Correo electrónico',
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  // ── Add ─────────────────────────────────────────────────────────────────────

  void _showAddSupplierSheet() {
    final legalNameController = TextEditingController();
    final taxIdController = TextEditingController();
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();

    CustomActionSheet.show(
      context: context,
      title: 'Agregar proveedor',
      showDivider: true,
      isContentScrollable: true,
      content: _buildForm(
        legalNameController: legalNameController,
        taxIdController: taxIdController,
        nameController: nameController,
        phoneController: phoneController,
        emailController: emailController,
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
                        .addUnaffiliatedSupplier(
                          name: commercialName,
                          legalName: legalName,
                          phone: phoneController.text.trim().isEmpty
                              ? null
                              : phoneController.text.trim(),
                          email: emailController.text.trim().isEmpty
                              ? null
                              : emailController.text.trim(),
                          taxId: taxId,
                        );
                    final _ = await ref.refresh(
                      unaffiliatedSuppliersProvider.future,
                    );
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Proveedor "$legalName" agregado'),
                      ),
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

  void _showEditSupplierSheet(UnaffiliatedSupplier supplier) {
    final legalNameController = TextEditingController(
      text: supplier.legalName ?? '',
    );
    final taxIdController = TextEditingController(text: supplier.taxId ?? '');
    final nameController = TextEditingController(text: supplier.name);
    final phoneController = TextEditingController(text: supplier.phone ?? '');
    final emailController = TextEditingController(text: supplier.email ?? '');

    // State to track if there are unsaved changes
    bool hasChanged = false;

    void updateHasChanged(StateSetter setState) {
      final currentLegalName = legalNameController.text.trim();
      final currentTaxId = taxIdController.text.trim();
      final currentName = nameController.text.trim();
      final currentPhone = phoneController.text.trim();
      final currentEmail = emailController.text.trim();

      final previousLegalName = supplier.legalName ?? '';
      final previousTaxId = supplier.taxId ?? '';
      final previousName = supplier.name;
      final previousPhone = supplier.phone ?? '';
      final previousEmail = supplier.email ?? '';

      final isChanged =
          currentLegalName != previousLegalName ||
          currentTaxId != previousTaxId ||
          currentName != previousName ||
          currentPhone != previousPhone ||
          currentEmail != previousEmail;

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
            phoneController.addListener(() => updateHasChanged(setSheetState));
            emailController.addListener(() => updateHasChanged(setSheetState));

            return CustomActionSheet(
              title: 'Modificar proveedor',
              showDivider: true,
              isContentScrollable: true,
              content: _buildForm(
                legalNameController: legalNameController,
                taxIdController: taxIdController,
                nameController: nameController,
                phoneController: phoneController,
                emailController: emailController,
              ),
              actions: [
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
                              title: const Text('Eliminar proveedor'),
                              content: Text(
                                '¿Estás seguro de que deseas eliminar "${supplier.legalName ?? supplier.name}"?',
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
                                  .deleteUnaffiliatedSupplier(supplier.id);
                              final _ = await ref.refresh(
                                unaffiliatedSuppliersProvider.future,
                              );
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Proveedor "${supplier.legalName ?? supplier.name}" eliminado',
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
                                      .updateUnaffiliatedSupplier(
                                        id: supplier.id,
                                        name: commercialName,
                                        legalName: legalName,
                                        phone:
                                            phoneController.text.trim().isEmpty
                                            ? null
                                            : phoneController.text.trim(),
                                        email:
                                            emailController.text.trim().isEmpty
                                            ? null
                                            : emailController.text.trim(),
                                        taxId: taxId,
                                      );
                                  final _ = await ref.refresh(
                                    unaffiliatedSuppliersProvider.future,
                                  );
                                  navigator.pop();
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Proveedor actualizado a "$legalName"',
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
              ],
            );
          },
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final suppliersAsync = ref.watch(unaffiliatedSuppliersProvider);

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: StandardAppBar(
        backgroundColor: _isSearching ? colors.surfaceContainerHigh : null,
        title: 'Proveedores no afiliados',
        customTitle: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Buscar proveedor...',
                  border: InputBorder.none,
                  fillColor: colors.surfaceContainerHigh,
                ),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: colors.onSurface,
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
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
          onPressed: _showAddSupplierSheet,
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
              'Registra los proveedores con los que trabajas aunque aún no estén en la plataforma.',
              style: textTheme.bodyMedium?.copyWith(
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
              onSortChanged: (sort) => setState(() => _currentSort = sort),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: suppliersAsync.when(
              data: (suppliers) {
                final currentUserId =
                    Supabase.instance.client.auth.currentUser?.id;

                var filtered = suppliers.where((s) {
                  final isOwner = s.createdBy == currentUserId;
                  final query = _searchQuery.toLowerCase();
                  final matchesSearch =
                      s.name.toLowerCase().contains(query) ||
                      (s.legalName?.toLowerCase().contains(query) ?? false) ||
                      (s.taxId?.toLowerCase().contains(query) ?? false);
                  return isOwner && matchesSearch;
                }).toList();

                filtered.sort((a, b) {
                  final nameA = a.legalName ?? a.name;
                  final nameB = b.legalName ?? b.name;
                  if (_currentSort == SortOption.nameZA) {
                    return nameB.compareTo(nameA);
                  }
                  return nameA.compareTo(nameB);
                });

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      'No tienes proveedores registrados',
                      style: textTheme.bodyLarge,
                    ),
                  );
                }

                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final supplier = filtered[index];
                    final bool canEdit = !supplier.isVerified;
                    final displayName = supplier.legalName ?? supplier.name;
                    final subtitle = [
                      if (supplier.taxId != null) supplier.taxId!,
                      if (supplier.name != supplier.legalName &&
                          supplier.legalName != null)
                        supplier.name,
                    ].join(' · ');

                    return ListTile(
                      title: Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: textTheme.bodyLarge?.copyWith(
                                color: canEdit
                                    ? colors.onSurface
                                    : colors.onSurface.withValues(alpha: 0.5),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (supplier.isVerified) ...[
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
                              style: textTheme.bodySmall?.copyWith(
                                color: canEdit
                                    ? colors.onSurfaceVariant
                                    : colors.onSurfaceVariant.withValues(
                                        alpha: 0.5,
                                      ),
                              ),
                            )
                          : null,
                      onTap: canEdit
                          ? () => _showEditSupplierSheet(supplier)
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
                  const Center(child: Text('Error al cargar proveedores')),
            ),
          ),
        ],
      ),
    );
  }
}
