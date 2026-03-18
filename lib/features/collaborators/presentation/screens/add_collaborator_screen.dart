import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/standard_app_bar.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_dropdown.dart';
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

  // Controllers
  final _nameController = TextEditingController();
  final _idController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _chargeController = TextEditingController();

  // State
  String _selectedCode = '0412';
  final List<String> _phoneCodes = ['0412', '0414', '0424', '0416', '0426'];
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
        _chargeController.text.trim() != (widget.collaborator!.charge ?? '');

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
            );
      }

      // Refresh the collaborators list
      ref.invalidate(collaboratorsProvider);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Colaborador agregado exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
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

    return Scaffold(
      appBar: StandardAppBar(
        title: widget.collaborator == null
            ? 'Agregar colaborador'
            : 'Modificar colaborador',
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
                          width: 100,
                          child: CustomDropdown<String>(
                            label: 'Código*',
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
