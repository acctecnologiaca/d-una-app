import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/features/settings/data/models/shipping_company.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import 'package:d_una_app/core/utils/error_handler.dart';

class AddEditShippingCompanySheet extends ConsumerStatefulWidget {
  final ShippingCompany? company;

  const AddEditShippingCompanySheet({super.key, this.company});

  @override
  ConsumerState<AddEditShippingCompanySheet> createState() => _AddEditShippingCompanySheetState();
}

class _AddEditShippingCompanySheetState extends ConsumerState<AddEditShippingCompanySheet> {
  late TextEditingController _legalNameController;
  late TextEditingController _taxIdController;
  late TextEditingController _nameController;
  
  bool _isLoading = false;
  bool _hasChanged = false;

  bool get isEditing => widget.company != null;

  @override
  void initState() {
    super.initState();
    _legalNameController = TextEditingController(text: widget.company?.legalName ?? '');
    _taxIdController = TextEditingController(text: widget.company?.taxId ?? '');
    _nameController = TextEditingController(text: widget.company?.name ?? '');

    _legalNameController.addListener(_updateHasChanged);
    _taxIdController.addListener(_updateHasChanged);
    _nameController.addListener(_updateHasChanged);
  }

  @override
  void dispose() {
    _legalNameController.dispose();
    _taxIdController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _updateHasChanged() {
    if (!isEditing) return;
    final company = widget.company!;
    final isChanged = _legalNameController.text.trim() != company.legalName ||
        _taxIdController.text.trim() != company.taxId ||
        _nameController.text.trim() != (company.name ?? '');

    if (_hasChanged != isChanged) {
      setState(() => _hasChanged = isChanged);
    }
  }

  Future<void> _save() async {
    final legalName = _legalNameController.text.trim();
    final taxId = _taxIdController.text.trim();
    final commercialName = _nameController.text.trim().isEmpty ? legalName : _nameController.text.trim();

    if (legalName.isEmpty || taxId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(behavior: SnackBarBehavior.floating, content: Text('La Razón Social y el RIF son obligatorios.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(lookupRepositoryProvider);
      if (isEditing) {
        await repo.updateShippingCompany(
          id: widget.company!.id,
          legalName: legalName,
          taxId: taxId,
          name: commercialName,
        );
      } else {
        await repo.addShippingCompany(
          legalName: legalName,
          taxId: taxId,
          name: commercialName,
        );
      }
      ref.invalidate(shippingCompaniesProvider);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              isEditing
                  ? 'Empresa actualizada a "$legalName"'
                  : 'Empresa "$legalName" agregada',
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar empresa'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${widget.company!.displayName}"?',
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

    try {
      await ref.read(lookupRepositoryProvider).deleteShippingCompany(widget.company!.id);
      ref.invalidate(shippingCompaniesProvider);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(behavior: SnackBarBehavior.floating, content: Text('Empresa "${widget.company!.displayName}" eliminada')),
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

    final actions = <Widget>[
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: isEditing ? MainAxisAlignment.start : MainAxisAlignment.end,
          children: [
            if (isEditing)
              IconButton(
                icon: Icon(Icons.delete_outline, color: colors.onSurfaceVariant),
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
      title: isEditing ? 'Modificar empresa' : 'Agregar empresa',
      showDivider: isEditing,
      isContentScrollable: true,
      actions: actions,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Razón Social *',
            controller: _legalNameController,
            textCapitalization: TextCapitalization.words,
            autofocus: !isEditing,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'RIF / ID Fiscal *',
            controller: _taxIdController,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Nombre comercial',
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
