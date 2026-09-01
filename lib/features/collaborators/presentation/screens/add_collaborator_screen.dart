import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/standard_app_bar.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_dropdown.dart';
import '../../../../shared/widgets/custom_dialog.dart';
import '../../../../shared/widgets/form_bottom_bar.dart';
import '../providers/collaborators_providers.dart';

import '../../domain/models/collaborator.dart';

class AddCollaboratorScreen extends ConsumerStatefulWidget {
  final Collaborator? collaborator;

  const AddCollaboratorScreen({super.key, this.collaborator});

  @override
  ConsumerState<AddCollaboratorScreen> createState() =>
      _AddCollaboratorScreenState();
}

class _AddCollaboratorScreenState extends ConsumerState<AddCollaboratorScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isDeleting = false;

  // Controllers
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _chargeController = TextEditingController();

  // State
  String _selectedCode = '0412';
  final List<String> _phoneCodes = [
    '0412',
    '0422',
    '0414',
    '0424',
    '0416',
    '0426',
  ];
  bool _isActive = true;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initData();
    _nameController.addListener(_checkChanges);
    _idController.addListener(_checkChanges);
    _phoneController.addListener(_checkChanges);
    _emailController.addListener(_checkChanges);
    _chargeController.addListener(_checkChanges);
  }

  void _initData() {
    if (widget.collaborator != null) {
      _nameController.text = widget.collaborator!.fullName;
      _idController.text = widget.collaborator!.identificationId ?? '';
      _emailController.text = widget.collaborator!.email ?? '';
      _chargeController.text = widget.collaborator!.charge ?? '';
      _isActive = widget.collaborator!.isActive;

      final phone = widget.collaborator!.phone;
      if (phone != null && phone.length >= 4) {
        final code = phone.substring(0, 4);
        if (_phoneCodes.contains(code)) {
          _selectedCode = code;
          _phoneController.text = phone.substring(4);
        } else {
          _phoneController.text = phone;
        }
      } else {
        _phoneController.text = phone ?? '';
      }
    }
  }

  void _checkChanges() {
    if (widget.collaborator == null) {
      if (!_hasChanges) setState(() => _hasChanges = true);
      return;
    }

    final currentPhone = '$_selectedCode${_phoneController.text.trim()}';
    final hasChanged =
        _nameController.text.trim() != widget.collaborator!.fullName ||
        _idController.text.trim() !=
            (widget.collaborator!.identificationId ?? '') ||
        currentPhone != (widget.collaborator!.phone ?? '') ||
        _emailController.text.trim() != (widget.collaborator!.email ?? '') ||
        _chargeController.text.trim() != (widget.collaborator!.charge ?? '') ||
        _isActive != widget.collaborator!.isActive;

    if (_hasChanges != hasChanged) {
      setState(() => _hasChanges = hasChanged);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _chargeController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    if (widget.collaborator == null || _isDeleting) return;

    final confirmed = await CustomDialog.show<bool>(
      context: context,
      dialog: CustomDialog.destructive(
        title: '¿Eliminar colaborador?',
        contentText:
            '¿Estás seguro de que deseas eliminar permanentemente a "${widget.collaborator!.fullName}"? Esta acción no se puede deshacer.',
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      await ref
          .read(collaboratorsRepositoryProvider)
          .deleteCollaborator(widget.collaborator!.id);

      ref.invalidate(allCollaboratorsProvider);
      ref.invalidate(activeCollaboratorsProvider);

      if (mounted) {
        context.pop();
        AppToast.success(
          context,
          message: 'Colaborador eliminado exitosamente.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          message: 'Error al eliminar: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  Future<void> _saveForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final phone = '$_selectedCode${_phoneController.text.trim()}';

      if (widget.collaborator == null) {
        await ref
            .read(collaboratorsRepositoryProvider)
            .addCollaborator(
              fullName: _nameController.text.trim(),
              identificationId: _idController.text.trim().isNotEmpty
                  ? _idController.text.trim()
                  : null,
              phone: phone.isNotEmpty ? phone : null,
              email: _emailController.text.trim().isNotEmpty
                  ? _emailController.text.trim()
                  : null,
              charge: _chargeController.text.trim().isNotEmpty
                  ? _chargeController.text.trim()
                  : null,
              isActive: _isActive,
            );
      } else {
        await ref
            .read(collaboratorsRepositoryProvider)
            .updateCollaborator(
              id: widget.collaborator!.id,
              fullName: _nameController.text.trim(),
              identificationId: _idController.text.trim().isNotEmpty
                  ? _idController.text.trim()
                  : null,
              phone: phone.isNotEmpty ? phone : null,
              email: _emailController.text.trim().isNotEmpty
                  ? _emailController.text.trim()
                  : null,
              charge: _chargeController.text.trim().isNotEmpty
                  ? _chargeController.text.trim()
                  : null,
              isActive: _isActive,
            );
      }

      // Refresh the collaborators list
      ref.invalidate(allCollaboratorsProvider);
      ref.invalidate(activeCollaboratorsProvider);

      if (mounted) {
        context.pop();
        AppToast.success(
          context,
          message: widget.collaborator == null
              ? 'Colaborador agregado exitosamente.'
              : 'Colaborador actualizado exitosamente.',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          message: 'Error al guardar: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hasDocsAsync = widget.collaborator != null
        ? ref.watch(collaboratorHasDocumentsProvider(widget.collaborator!.id))
        : const AsyncValue.data(false);

    return Scaffold(
      appBar: StandardAppBar(
        title: widget.collaborator == null
            ? 'Agregar colaborador'
            : 'Modificar colaborador',
        actions: [
          if (widget.collaborator != null &&
              !widget.collaborator!.isUserRecord)
            hasDocsAsync.when(
              data: (hasDocs) {
                final canDelete = !hasDocs && !_isLoading && !_isDeleting;
                return Tooltip(
                  message: hasDocs
                      ? 'No se puede eliminar: tiene documentos asociados'
                      : 'Eliminar colaborador',
                  child: IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: canDelete
                          ? colors.onSurface
                          : colors.onSurface.withValues(alpha: 0.38),
                    ),
                    onPressed: canDelete ? _confirmDelete : null,
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, _) => const SizedBox.shrink(),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Estado del colaborador
                    if (widget.collaborator != null &&
                        !widget.collaborator!.isUserRecord) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colors.outlineVariant.withValues(alpha: 0.5),
                          ),
                        ),
                        child: SwitchListTile.adaptive(
                          value: _isActive,
                          onChanged: (val) {
                            setState(() {
                              _isActive = val;
                              _checkChanges();
                            });
                          },
                          title: Text(
                            'Colaborador activo',
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _isActive
                                ? 'Disponible para cotizaciones, reportes y órdenes'
                                : 'Inactivo: Oculto en la selección de nuevos documentos',
                            style: textTheme.bodySmall?.copyWith(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Datos personales
                    Text(
                      'Datos personales',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Nombre y apellido*',
                      controller: _nameController,
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Este campo es obligatorio';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Cédula/DNI/CC/Pasaporte',
                      controller: _idController,
                    ),

                    const SizedBox(height: 32),

                    // Datos de contacto
                    Text(
                      'Datos de contacto',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 110,
                          child: CustomDropdown<String>(
                            label: 'Código',
                            value: _selectedCode,
                            items: _phoneCodes,
                            itemLabelBuilder: (item) => item,
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCode = val);
                                _checkChanges();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: CustomTextField(
                            label: 'Teléfono*',
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requerido';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Correo electrónico',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),

                    const SizedBox(height: 32),

                    // Funciones
                    Text(
                      'Funciones',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: 'Función',
                      controller: _chargeController,
                      helperText: 'Ej: Asesor comercial',
                    ),

                    const SizedBox(height: 48),

                    // Actions
                    FormBottomBar(
                      onCancel: () => context.pop(),
                      onSave:
                          (_isLoading ||
                              _isDeleting ||
                              (widget.collaborator != null && !_hasChanges))
                          ? null
                          : _saveForm,
                      saveLabel: 'Guardar',
                      isLoading: _isLoading,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
