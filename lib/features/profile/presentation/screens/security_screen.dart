import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/form_bottom_bar.dart';
import '../../../auth/presentation/providers/register_provider.dart';

class SecurityScreen extends ConsumerStatefulWidget {
  const SecurityScreen({super.key});

  @override
  ConsumerState<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends ConsumerState<SecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_updateState);
    _newPasswordController.addListener(_updateState);
    _confirmPasswordController.addListener(_updateState);
  }

  void _updateState() {
    setState(() {});
  }

  @override
  void dispose() {
    _currentPasswordController.removeListener(_updateState);
    _newPasswordController.removeListener(_updateState);
    _confirmPasswordController.removeListener(_updateState);
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleCurrent() => setState(() => _obscureCurrent = !_obscureCurrent);
  void _toggleNew() => setState(() => _obscureNew = !_obscureNew);
  void _toggleConfirm() => setState(() => _obscureConfirm = !_obscureConfirm);

  // Validation Regex: 8 chars, 1 uppercase, 1 number, 1 symbol
  // Regex: ^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$
  bool _isPasswordValid(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    if (!password.contains(RegExp(r'[!@#\$&*~_.,-]'))) return false;
    return true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final repo = ref.read(authRepositoryProvider);
    try {
      final user = repo.currentUser;
      if (user?.email == null) throw 'No se pudo verificar el usuario';

      // Verify current password by signing in (re-auth)
      await repo.signIn(
        email: user!.email!,
        password: _currentPasswordController.text,
      );

      // If successful, update to new password
      await repo.updatePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Contraseña actualizada')));
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
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
      backgroundColor: colors.surface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Seguridad',
          style: textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ingresa una contraseña segura.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Current Password
                    CustomTextField(
                      label: 'Contraseña actual*',
                      controller: _currentPasswordController,
                      obscureText: _obscureCurrent,
                      maxLines: 1,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrent
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: _toggleCurrent,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Requerido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // New Password
                    CustomTextField(
                      label: 'Nueva contraseña*',
                      controller: _newPasswordController,
                      obscureText: _obscureNew,
                      maxLines: 1,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: _toggleNew,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Requerido';
                        if (!_isPasswordValid(val)) {
                          return 'La contraseña no cumple con los requisitos';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Debe contener al menos 8 caractéres, números, símbolos y mayúsculas.',
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Confirm Password
                    CustomTextField(
                      label: 'Confirma nueva contraseña*',
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      maxLines: 1,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: _toggleConfirm,
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Requerido';
                        if (val != _newPasswordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 48),

                    // Actions
                    FormBottomBar(
                      onCancel: () => context.pop(),
                      onSave:
                          (_currentPasswordController.text.isNotEmpty &&
                              _newPasswordController.text.isNotEmpty &&
                              _confirmPasswordController.text.isNotEmpty)
                          ? _save
                          : null,
                      isSaveEnabled:
                          _currentPasswordController.text.isNotEmpty &&
                          _newPasswordController.text.isNotEmpty &&
                          _confirmPasswordController.text.isNotEmpty,
                      isLoading: _isLoading,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
