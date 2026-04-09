import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/features/clients/data/models/client_model.dart';
import 'package:d_una_app/features/clients/presentation/providers/clients_provider.dart';
import 'package:d_una_app/features/clients/presentation/widgets/contact_form.dart';

class AddEditContactScreen extends ConsumerStatefulWidget {
  final String clientId;
  final String? companyName;
  final Contact? contact;
  final int? contactCount;

  const AddEditContactScreen({
    super.key,
    required this.clientId,
    this.companyName,
    this.contact,
    this.contactCount,
  });

  @override
  ConsumerState<AddEditContactScreen> createState() =>
      _AddEditContactScreenState();
}

class _AddEditContactScreenState extends ConsumerState<AddEditContactScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _roleController;
  late TextEditingController _departmentController;

  String _selectedPhoneCode = '0424';
  late bool _isPrimary;
  bool _isSubmitting = false;
  bool _hasChanges = false;

  late String _initialName;
  late String _initialPhone;
  late String _initialEmail;
  late String _initialRole;
  late String _initialDepartment;
  late String _initialPhoneCode;
  late bool _initialIsPrimary;

  bool get _isEditing => widget.contact != null;

  String? get _returnTo =>
      GoRouterState.of(context).uri.queryParameters['returnTo'];

  @override
  void initState() {
    super.initState();
    final contact = widget.contact;

    _nameController = TextEditingController(text: contact?.name ?? '');

    // Phone parsing logic
    final phoneFull = contact?.phone ?? '';
    final parts = phoneFull.split('-');
    const phoneCodes = ['0412', '0422', '0414', '0424', '0416', '0426'];

    if (parts.length > 1) {
      if (phoneCodes.contains(parts[0])) {
        _selectedPhoneCode = parts[0];
      }
      _phoneController = TextEditingController(text: parts[1]);
    } else {
      if (phoneFull.length > 4) {
        // Try to check if starts with known code
        String? foundCode;
        for (final code in phoneCodes) {
          if (phoneFull.startsWith(code)) {
            foundCode = code;
            break;
          }
        }

        if (foundCode != null) {
          _selectedPhoneCode = foundCode;
          _phoneController = TextEditingController(
            text: phoneFull.substring(foundCode.length),
          );
        } else {
          // Fallback, maybe just first 4 chars
          _selectedPhoneCode = phoneFull.substring(0, 4);
          _phoneController = TextEditingController(
            text: phoneFull.substring(4),
          );
        }
      } else {
        _phoneController = TextEditingController(text: phoneFull);
      }
    }
    // If empty (Add mode), defaults are already set in variable declaration (except controller which we init empty if not covered)
    if (!_isEditing) {
      _phoneController = TextEditingController(); // Clear text if creating new
      _selectedPhoneCode = '0424'; // Reset default
    }

    _emailController = TextEditingController(text: contact?.email ?? '');
    _roleController = TextEditingController(text: contact?.role ?? '');
    _departmentController = TextEditingController(
      text: contact?.department ?? 'Tecnología de la Información',
    );

    // Primary Logic
    if (_isEditing) {
      _isPrimary = contact!.isPrimary;
      // Force primary if it's the only contact
      if (widget.contactCount == 1) {
        _isPrimary = true;
      }
    } else {
      _isPrimary = false;
    }

    // Initialize initial values for change detection
    _initialName = _nameController.text;
    _initialPhone = _phoneController.text;
    _initialEmail = _emailController.text;
    _initialRole = _roleController.text;
    _initialDepartment = _departmentController.text;
    _initialPhoneCode = _selectedPhoneCode;
    _initialIsPrimary = _isPrimary;

    // Listeners
    _nameController.addListener(_checkChanges);
    _phoneController.addListener(_checkChanges);
    _emailController.addListener(_checkChanges);
    _roleController.addListener(_checkChanges);
    _departmentController.addListener(_checkChanges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  void _checkChanges() {
    final hasChanges =
        _nameController.text != _initialName ||
        _phoneController.text != _initialPhone ||
        _emailController.text != _initialEmail ||
        _roleController.text != _initialRole ||
        _departmentController.text != _initialDepartment ||
        _selectedPhoneCode != _initialPhoneCode ||
        _isPrimary != _initialIsPrimary;

    if (_hasChanges != hasChanges) {
      setState(() => _hasChanges = hasChanges);
    }
  }

  Future<void> _onSave() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      final fullPhone =
          '$_selectedPhoneCode${_phoneController.text.replaceAll(RegExp(r'\D'), '')}';

      final contactData = {
        'name': _nameController.text,
        'role': _roleController.text,
        'email': _emailController.text,
        'phone': fullPhone,
        'department': _departmentController.text,
        'isPrimary': _isPrimary,
      };

      try {
        if (_isEditing) {
          await ref
              .read(clientsProvider.notifier)
              .updateContact(widget.contact!.id, contactData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Contacto actualizado exitosamente'),
              ),
            );
          }
        } else {
          await ref
              .read(clientsProvider.notifier)
              .addContact(widget.clientId, contactData);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contacto agregado exitosamente')),
            );

            // Auto-select contact (using ID returned? No, AddEditContact currently returns void! Wait.)
            // But CreateQuoteScreen already has ref.refresh and auto-select logic running for Contacts because it uses await `context.push()`! Wait, if we use `context.go()`, the `await` is lost.
          }
        }
        if (mounted) {
          if (_returnTo != null) {
            context.go(Uri.decodeComponent(_returnTo!));
          } else {
            context.pop();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isSubmitting = false);
      }
    }
  }

  Future<bool?> _showDiscardDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text(
          'Si sales ahora, perderás toda la información que has ingresado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Descartar',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onCancelWithConfirmation() async {
    if (!_hasChanges) {
      if (_returnTo != null) {
        context.go(Uri.decodeComponent(_returnTo!));
      } else {
        context.pop();
      }
      return;
    }

    final confirmed = await _showDiscardDialog();
    if (confirmed == true && mounted) {
      if (_returnTo != null) {
        context.go(Uri.decodeComponent(_returnTo!));
      } else {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return PopScope(
      canPop: !_hasChanges || _isSubmitting,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await _showDiscardDialog();
        if (confirmed == true && context.mounted) {
          if (_returnTo != null) {
            context.go(Uri.decodeComponent(_returnTo!));
          } else {
            context.pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onCancelWithConfirmation,
          ),
          centerTitle: false,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _isEditing ? 'Modificar contacto' : 'Agregar contacto',
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                  fontSize: 20,
                ),
              ),
              if (widget.companyName != null)
                Text(
                  widget.companyName!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontSize: 14,
                  ),
                ),
            ],
          ),
          foregroundColor: colors.onSurface,
          backgroundColor: colors.surface,
          elevation: 0,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child: ContactForm(
            formKey: _formKey,
            nameController: _nameController,
            phoneController: _phoneController,
            emailController: _emailController,
            roleController: _roleController,
            departmentController: _departmentController,
            selectedPhoneCode: _selectedPhoneCode,
            onPhoneCodeChanged: (val) {
              setState(() {
                _selectedPhoneCode = val!;
                _checkChanges();
              });
            },
            isPrimary: _isPrimary,
            onIsPrimaryChanged: (val) {
              setState(() {
                _isPrimary = val;
                _checkChanges();
              });
            },
            onSave: _onSave,
            onCancel: _onCancelWithConfirmation,
            saveLabel: _isEditing ? 'Guardar' : 'Agregar',
            isLoading: _isSubmitting,
            isSaveEnabled: !_isSubmitting && _hasChanges,
            isPrimaryReadOnly:
                _isEditing &&
                (widget.contactCount == 1 || widget.contact!.isPrimary),
          ),
        ),
      ),
    );
  }
}
