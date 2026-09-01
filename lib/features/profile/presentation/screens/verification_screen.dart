import 'dart:io';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:d_una_app/shared/widgets/status_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/profile_provider.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/verification_document.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/custom_dialog.dart';
import '../../../../shared/widgets/form_bottom_bar.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();

  bool _isBusiness = false;
  bool _isLoading = false;

  // Store selected files: Key = Document Label, Value = PlatformFile
  final Map<String, PlatformFile?> _individualFiles = {
    'Cédula de identidad o DNI': null,
    'Certificado de curso o taller': null,
    'Referencia comercial': null,
  };

  final Map<String, PlatformFile?> _businessFiles = {
    'Documento o acta constitutiva': null,
    'RIF de la empresa (vigente)': null,
    'Referencia comercial': null,
  };

  // Map label to document_type for backend
  String _mapLabelToType(String label) {
    switch (label) {
      case 'Cédula de identidad o DNI':
        return 'identity_card';
      case 'Certificado de curso o taller':
        return 'course_certificate';
      case 'Referencia comercial':
        return 'commercial_reference';
      case 'Documento o acta constitutiva':
        return 'articles_of_incorporation';
      case 'RIF de la empresa (vigente)':
        return 'fiscal_id';
      default:
        return 'other';
    }
  }

  // Company Controllers
  late TextEditingController _companyNameController;
  late TextEditingController _rifController;
  late TextEditingController _fiscalAddressController;
  PlatformFile? _companyLogo;

  // Initial state for change detection
  bool _initialIsBusiness = false;
  String _initialCompanyName = '';
  String _initialRif = '';
  String _initialFiscalAddress = '';

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _companyNameController = TextEditingController();
    _rifController = TextEditingController();
    _fiscalAddressController = TextEditingController();
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _rifController.dispose();
    _fiscalAddressController.dispose();
    super.dispose();
  }

  void _initializeData(UserProfile profile) {
    if (_isInitialized) return;
    setState(() {
      _isBusiness = profile.isBusinessOwner;
      _companyNameController.text = profile.companyName ?? '';
      _rifController.text = profile.companyRif ?? '';
      _fiscalAddressController.text = profile.companyAddress ?? '';

      // Capture initial state
      _initialIsBusiness = profile.isBusinessOwner;
      _initialCompanyName = profile.companyName ?? '';
      _initialRif = profile.companyRif ?? '';
      _initialFiscalAddress = profile.companyAddress ?? '';

      _isInitialized = true;
    });
  }

  bool get _hasChanges {
    // 1. Check Business Toggle
    if (_isBusiness != _initialIsBusiness) return true;

    // 2. Check Text Fields and Logo (only if Business mode is active)
    if (_isBusiness) {
      if (_companyNameController.text.trim() != _initialCompanyName.trim()) return true;
      if (_rifController.text.trim() != _initialRif.trim()) return true;
      if (_fiscalAddressController.text.trim() != _initialFiscalAddress.trim()) return true;
      if (_companyLogo != null) return true;
    }

    // 3. Check for new files selected (in the ACTIVE map)
    final activeFiles = _currentFiles;
    for (var file in activeFiles.values) {
      if (file != null) return true;
    }

    return false;
  }

  // Helper to access current active map
  Map<String, PlatformFile?> get _currentFiles =>
      _isBusiness ? _businessFiles : _individualFiles;

  bool _isUploaded(String label, List<VerificationDocument> uploadedDocs) {
    final type = _mapLabelToType(label);
    return uploadedDocs.any((doc) => doc.documentType == type);
  }

  VerificationDocument? _getUploadedDoc(
    String label,
    List<VerificationDocument> uploadedDocs,
  ) {
    final type = _mapLabelToType(label);
    try {
      return uploadedDocs.firstWhere((doc) => doc.documentType == type);
    } catch (_) {
      return null;
    }
  }

  Future<void> _pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 5 * 1024 * 1024) {
          if (mounted) {
            AppToast.warning(
              context,
              message: 'La imagen excede el límite máximo de 5 MB.',
            );
          }
          return;
        }
        setState(() {
          _companyLogo = file;
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          message: 'Error al seleccionar logo: $e',
        );
      }
    }
  }

  Future<void> _pickFile(String key) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.size > 10 * 1024 * 1024) {
          if (mounted) {
            AppToast.warning(
              context,
              message: 'El archivo excede el límite máximo de 10 MB.',
            );
          }
          return;
        }
        setState(() {
          _currentFiles[key] = file;
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          message: 'Error al seleccionar archivo: $e',
        );
      }
    }
  }

  void _removeFile(String key) {
    setState(() {
      _currentFiles[key] = null;
    });
  }

  bool _validateDocumentRules(List<VerificationDocument> uploadedDocs) {
    if (_isBusiness) {
      // Form fields validation for Business
      if (!_formKey.currentState!.validate()) {
        AppToast.warning(
          context,
          message: 'Completa todos los campos obligatorios de la empresa.',
        );
        return false;
      }

      // Business Document Rules: Acta and RIF required, Reference optional
      final hasActa = _businessFiles['Documento o acta constitutiva'] != null ||
          _isUploaded('Documento o acta constitutiva', uploadedDocs);
      if (!hasActa) {
        AppToast.warning(
          context,
          message: 'El Documento o acta constitutiva es obligatorio.',
        );
        return false;
      }

      final hasRif = _businessFiles['RIF de la empresa (vigente)'] != null ||
          _isUploaded('RIF de la empresa (vigente)', uploadedDocs);
      if (!hasRif) {
        AppToast.warning(
          context,
          message: 'El RIF de la empresa (vigente) es obligatorio.',
        );
        return false;
      }
    } else {
      // Personal Document Rules: Cedula required + (Certificado OR Referencia required)
      final hasCedula = _individualFiles['Cédula de identidad o DNI'] != null ||
          _isUploaded('Cédula de identidad o DNI', uploadedDocs);
      if (!hasCedula) {
        AppToast.warning(
          context,
          message: 'La Cédula de identidad o DNI es obligatoria.',
        );
        return false;
      }

      final hasCert = _individualFiles['Certificado de curso o taller'] != null ||
          _isUploaded('Certificado de curso o taller', uploadedDocs);
      final hasRef = _individualFiles['Referencia comercial'] != null ||
          _isUploaded('Referencia comercial', uploadedDocs);

      if (!hasCert && !hasRef) {
        AppToast.warning(
          context,
          message:
              'Debes adjuntar al menos un Certificado de curso o una Referencia comercial.',
        );
        return false;
      }
    }
    return true;
  }

  Future<void> _save(
    UserProfile currentProfile,
    List<VerificationDocument> uploadedDocs,
  ) async {
    final colors = Theme.of(context).colorScheme;

    // Validate business and personal document rules
    if (!_validateDocumentRules(uploadedDocs)) return;

    // Check if verification status is active (verified)
    final isVerified = currentProfile.verificationStatus == 'verified';

    if (isVerified) {
      final confirmed = await CustomDialog.show<bool>(
        context: context,
        dialog: CustomDialog.destructive(
          title: 'Modificar información',
          contentText:
              'Al modificar tus documentos o datos, perderás tu estatus de verificación actual y tu perfil pasará nuevamente a revisión. ¿Deseas continuar?',
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => context.pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() => _isLoading = true);
    final repo = ref.read(profileRepositoryProvider);

    try {
      // 1. Upload Logo if selected
      String? newLogoUrl = currentProfile.companyLogoUrl;
      if (_isBusiness && _companyLogo != null && _companyLogo!.path != null) {
        final file = File(_companyLogo!.path!);
        final bytes = await file.readAsBytes();
        final ext = _companyLogo!.path!.split('.').last;
        newLogoUrl = await repo.uploadCompanyLogo(
          currentProfile.id,
          bytes,
          ext,
        );
      }

      // 2. Update Profile Data
      final updatedProfile = currentProfile.copyWith(
        isBusinessOwner: _isBusiness,
        companyName: _isBusiness ? _companyNameController.text.trim() : null,
        companyRif: _isBusiness ? _rifController.text.trim() : null,
        companyAddress: _isBusiness ? _fiscalAddressController.text.trim() : null,
        companyLogoUrl: _isBusiness ? newLogoUrl : null,
        verificationStatus: 'pending',
      );
      await repo.updateProfile(updatedProfile);

      // 3. Upload Selected Documents
      final filesToUpload = _currentFiles;
      for (var entry in filesToUpload.entries) {
        final label = entry.key;
        final file = entry.value;

        if (file != null && file.path != null) {
          final fileObj = File(file.path!);
          final bytes = await fileObj.readAsBytes();
          final ext = file.path!.split('.').last;

          await repo.uploadVerificationDocument(
            currentProfile.id,
            _mapLabelToType(label),
            bytes,
            ext,
          );
        }
      }

      ref.invalidate(userProfileProvider);
      ref.invalidate(verificationDocumentsProvider);

      if (mounted) {
        AppToast.success(
          context,
          message: 'Datos guardados y documentos enviados a revisión.',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          message: 'Error guardando datos: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildDocumentStatusBadge(
    BuildContext context,
    PlatformFile? selectedFile,
    VerificationDocument? uploadedDoc,
  ) {
    final colors = Theme.of(context).colorScheme;

    if (selectedFile != null) {
      return StatusBadge(
        icon: Image.asset(
          'assets/icons/status_review.png',
          width: 14,
          height: 14,
        ),
        text: 'Listo para enviar',
        backgroundColor: Colors.orange.withValues(alpha: 0.1),
        textColor: Colors.orange.shade800,
      );
    }

    if (uploadedDoc != null) {
      final status = uploadedDoc.status.toLowerCase();
      if (status == 'approved' || status == 'verified') {
        return StatusBadge(
          icon: Image.asset(
            'assets/icons/status_approved.png',
            width: 14,
            height: 14,
          ),
          text: 'Aprobado',
          backgroundColor: Colors.green.withValues(alpha: 0.1),
          textColor: Colors.green.shade700,
        );
      } else if (status == 'rejected') {
        return StatusBadge(
          icon: Image.asset(
            'assets/icons/status_rejected.png',
            width: 14,
            height: 14,
          ),
          text: 'Rechazado',
          backgroundColor: colors.error.withValues(alpha: 0.1),
          textColor: colors.error,
        );
      } else {
        return StatusBadge(
          icon: Image.asset(
            'assets/icons/status_review.png',
            width: 14,
            height: 14,
          ),
          text: 'En revisión',
          backgroundColor: Colors.orange.withValues(alpha: 0.1),
          textColor: Colors.orange.shade800,
        );
      }
    }

    return Text(
      'No adjuntado',
      style: TextStyle(
        fontSize: 12,
        color: colors.onSurfaceVariant,
      ),
    );
  }

  String _getDocumentDisplayLabel(String key) {
    if (_isBusiness) {
      if (key == 'Documento o acta constitutiva' ||
          key == 'RIF de la empresa (vigente)') {
        return '$key*';
      }
      return '$key (Opcional)';
    } else {
      if (key == 'Cédula de identidad o DNI') {
        return '$key*';
      }
      return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final userProfileAsync = ref.watch(userProfileProvider);
    final verificationDocsAsync = ref.watch(verificationDocumentsProvider);

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
          'Verificación',
          style: textTheme.titleLarge?.copyWith(
            color: colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: false,
      ),
      body: userProfileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, stack) => FriendlyErrorWidget(error: e),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Perfil no encontrado'));
          }

          if (!_isInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _initializeData(profile);
              }
            });
          }

          return verificationDocsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error al cargar documentos: $e')),
            data: (uploadedDocs) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Illustration
                      Center(
                        child: Image.asset(
                          'assets/images/verification_illustration.png',
                          height: 200,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Verification Status Alert Card
                      if (profile.verificationStatus == 'verified')
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.green.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/icons/status_approved.png',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '¡Cuenta Verificada!',
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tus documentos han sido aprobados con éxito.',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (profile.verificationStatus == 'rejected')
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colors.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: colors.error.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/icons/status_rejected.png',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Verificación Rechazada',
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: colors.error,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Uno o más documentos fueron rechazados. Por favor reemplaza los documentos marcados en rojo.',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      else if (profile.verificationStatus == 'pending')
                        Container(
                          margin: const EdgeInsets.only(bottom: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Image.asset(
                                'assets/icons/status_review.png',
                                width: 24,
                                height: 24,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Documentos en Revisión',
                                      style: textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade900,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tus documentos están siendo validados por nuestro equipo.',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Description
                      Text(
                        'Dentro de nuestra plataforma encontrarás proveedores que podrán solicitarte que estés verificado, ya sea con el fin de poder venderte algún producto u ofrecerte mejores precios.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.justify,
                      ),
                      const SizedBox(height: 24),

                      // Switch
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Soy propietario de una empresa',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colors.onSurface,
                            ),
                          ),
                          Transform.scale(
                            scale: 0.9,
                            child: Switch(
                              value: _isBusiness,
                              onChanged: (val) {
                                setState(() => _isBusiness = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (_isBusiness) ...[
                        // Company Data Section
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colors.primaryContainer.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: colors.primary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    children: [
                                      TextSpan(
                                        text: 'Importante: ',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colors.onSurface,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      TextSpan(
                                        text:
                                            'El objeto de tu empresa debe estar estrechamente ligado a tus ocupaciones, de lo contrario no podremos usarla para verificar tu cuenta.',
                                        style: textTheme.bodyMedium?.copyWith(
                                          color: colors.onSurface,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Datos de tu empresa',
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _companyNameController,
                          label: 'Nombre o razón social*',
                          validator: (v) {
                            if (_isBusiness && (v == null || v.trim().isEmpty)) {
                              return 'Ingresa el nombre o razón social';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _rifController,
                          label: 'RIF/NIF/RUT* (Identificación Tributaria)',
                          validator: (v) {
                            if (_isBusiness && (v == null || v.trim().isEmpty)) {
                              return 'Ingresa el RIF/NIF/RUT';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),
                        CustomTextField(
                          controller: _fiscalAddressController,
                          label: 'Dirección fiscal*',
                          helperText:
                              'Debe ser igual a la que aparece en el RIF/NIF/RUT.',
                          maxLines: 2,
                          validator: (v) {
                            if (_isBusiness && (v == null || v.trim().isEmpty)) {
                              return 'Ingresa la dirección fiscal';
                            }
                            return null;
                          },
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 16),

                        // Logo Picker
                        InkWell(
                          onTap: _pickLogo,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: _companyLogo != null &&
                                    _companyLogo!.path != null
                                ? Stack(
                                    children: [
                                      Center(
                                        child: Image.file(
                                          File(_companyLogo!.path!),
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      Positioned(
                                        top: 8,
                                        right: 8,
                                        child: CircleAvatar(
                                          backgroundColor: Colors.white,
                                          radius: 16,
                                          child: IconButton(
                                            padding: EdgeInsets.zero,
                                            icon: const Icon(
                                              Icons.edit,
                                              size: 16,
                                            ),
                                            onPressed: _pickLogo,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : (profile.companyLogoUrl != null
                                    ? Stack(
                                        children: [
                                          Center(
                                            child: Image.network(
                                              profile.companyLogoUrl!,
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                          Positioned(
                                            top: 8,
                                            right: 8,
                                            child: CircleAvatar(
                                              backgroundColor: Colors.white,
                                              radius: 16,
                                              child: IconButton(
                                                padding: EdgeInsets.zero,
                                                icon: const Icon(
                                                  Icons.edit,
                                                  size: 16,
                                                ),
                                                onPressed: _pickLogo,
                                              ),
                                            ),
                                          ),
                                        ],
                                      )
                                    : Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 40,
                                            color: colors.primary,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Cargar Logo',
                                            style: TextStyle(
                                              color: colors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      )),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Documents Section Title
                      Text(
                        'Carga los siguientes documentos',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (!_isBusiness)
                        Text(
                          'Cédula obligatoria + al menos un certificado o referencia comercial.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        )
                      else
                        Text(
                          'Documento constitutivo y RIF obligatorios. Referencia opcional.',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 16),

                      ..._currentFiles.keys.map((key) {
                        final selectedFile = _currentFiles[key];
                        final uploadedDoc = _getUploadedDoc(key, uploadedDocs);
                        final isSelected = selectedFile != null;
                        final isDone = uploadedDoc != null || isSelected;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDone
                                  ? colors.primary.withValues(alpha: 0.3)
                                  : Colors.grey.shade300,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Status Icon Container
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? colors.primary.withValues(alpha: 0.1)
                                      : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isDone
                                      ? Icons.description_outlined
                                      : Icons.file_upload_outlined,
                                  color: isDone
                                      ? colors.primary
                                      : Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // Text Info and Status Badge
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getDocumentDisplayLabel(key),
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (isSelected)
                                      Text(
                                        selectedFile.name,
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colors.primary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    const SizedBox(height: 2),
                                    _buildDocumentStatusBadge(
                                      context,
                                      selectedFile,
                                      uploadedDoc,
                                    ),
                                  ],
                                ),
                              ),

                              // Action Button
                              if (isSelected)
                                IconButton(
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.grey,
                                  ),
                                  tooltip: 'Eliminar selección',
                                  onPressed: () => _removeFile(key),
                                )
                              else
                                IconButton(
                                  icon: Icon(
                                    uploadedDoc != null
                                        ? Icons.edit_outlined
                                        : Icons.arrow_forward_ios,
                                    size: uploadedDoc != null ? 20 : 16,
                                    color: colors.primary,
                                  ),
                                  tooltip: uploadedDoc != null
                                      ? 'Reemplazar documento'
                                      : 'Adjuntar documento',
                                  onPressed: () => _pickFile(key),
                                ),
                            ],
                          ),
                        );
                      }),

                      const SizedBox(height: 16),

                      // Verification Note
                      Text(
                        'La verificación de la documentación puede tomar de 48h a 72h hábiles.',
                        style: textTheme.bodySmall?.copyWith(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // Actions
                      FormBottomBar(
                        onCancel: () => context.pop(),
                        onSave: (_isLoading || !_hasChanges)
                            ? null
                            : () => _save(profile, uploadedDocs),
                        isSaveEnabled: !_isLoading && _hasChanges,
                        isLoading: _isLoading,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
