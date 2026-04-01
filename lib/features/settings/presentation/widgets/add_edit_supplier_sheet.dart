import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/features/portfolio/domain/models/unaffiliated_supplier_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';

class AddEditSupplierSheet extends ConsumerStatefulWidget {
  final UnaffiliatedSupplier? supplier;

  const AddEditSupplierSheet({super.key, this.supplier});

  @override
  ConsumerState<AddEditSupplierSheet> createState() => _AddEditSupplierSheetState();
}

class _AddEditSupplierSheetState extends ConsumerState<AddEditSupplierSheet> {
  late TextEditingController _legalNameController;
  late TextEditingController _taxIdController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  
  bool _isLoading = false;
  bool _hasChanged = false;

  bool get isEditing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    _legalNameController = TextEditingController(text: widget.supplier?.legalName ?? '');
    _taxIdController = TextEditingController(text: widget.supplier?.taxId ?? '');
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _phoneController = TextEditingController(text: widget.supplier?.phone ?? '');
    _emailController = TextEditingController(text: widget.supplier?.email ?? '');

    _legalNameController.addListener(_updateHasChanged);
    _taxIdController.addListener(_updateHasChanged);
    _nameController.addListener(_updateHasChanged);
    _phoneController.addListener(_updateHasChanged);
    _emailController.addListener(_updateHasChanged);
  }

  @override
  void dispose() {
    _legalNameController.dispose();
    _taxIdController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _updateHasChanged() {
    if (!isEditing) return;
    final supplier = widget.supplier!;
    final isChanged = _legalNameController.text.trim() != (supplier.legalName ?? '') ||
        _taxIdController.text.trim() != (supplier.taxId ?? '') ||
        _nameController.text.trim() != supplier.name ||
        _phoneController.text.trim() != (supplier.phone ?? '') ||
        _emailController.text.trim() != (supplier.email ?? '');

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

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final repo = ref.read(lookupRepositoryProvider);
      UnaffiliatedSupplier? result;

      if (isEditing) {
        await repo.updateUnaffiliatedSupplier(
          id: widget.supplier!.id,
          name: commercialName,
          legalName: legalName,
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          taxId: taxId,
        );
        result = UnaffiliatedSupplier(
          id: widget.supplier!.id,
          name: commercialName,
          legalName: legalName,
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          taxId: taxId,
          userId: widget.supplier!.userId,
          isVerified: widget.supplier!.isVerified,
        );
      } else {
        result = await repo.addUnaffiliatedSupplier(
          name: commercialName,
          legalName: legalName,
          phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
          email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
          taxId: taxId,
        );
      }
      
      ref.invalidate(unaffiliatedSuppliersProvider);
      ref.invalidate(allSuppliersProvider); // Also invalidate allSuppliersProvider used in Purchases
      
      if (mounted) {
        navigator.pop(result);
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            isEditing
                ? 'Proveedor actualizado a "$legalName"'
                : 'Proveedor "$legalName" agregado',
          ),
        ),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      scaffoldMessenger.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text('Error: $e')));
    }
  }

  Future<void> _delete() async {
    final colors = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar proveedor'),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${widget.supplier!.legalName ?? widget.supplier!.name}"?',
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

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await ref.read(lookupRepositoryProvider).deleteUnaffiliatedSupplier(widget.supplier!.id);
      ref.invalidate(unaffiliatedSuppliersProvider);
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(behavior: SnackBarBehavior.floating, content: Text('Proveedor "${widget.supplier!.legalName ?? widget.supplier!.name}" eliminado')),
      );
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(behavior: SnackBarBehavior.floating, content: Text('Error: $e')));
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
      title: isEditing ? 'Modificar proveedor' : 'Agregar proveedor',
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
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Teléfono',
            controller: _phoneController,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Correo electrónico',
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
