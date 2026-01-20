import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/profile_provider.dart';
import '../../domain/models/user_profile.dart'; // Import user_profile
import '../../domain/models/verification_document.dart'; // Import verification_document
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/form_bottom_bar.dart';

class VerificationScreen extends ConsumerStatefulWidget {
  const VerificationScreen({super.key});

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
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

    // 2. Check Text Fields and Logo (only if Business mode matches initial or is active)
    if (_isBusiness) {
      if (_companyNameController.text != _initialCompanyName) return true;
      if (_rifController.text != _initialRif) return true;
      if (_fiscalAddressController.text != _initialFiscalAddress) return true;
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

  Future<void> _pickLogo() async {
    try {
      final result = await FilePicker.platform.pickFiles(type: FileType.image);
      if (result != null) {
        setState(() {
          _companyLogo = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar logo: $e')),
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

      if (result != null) {
        setState(() {
          _currentFiles[key] = result.files.first;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar archivo: $e')),
        );
      }
    }
  }

  void _removeFile(String key) {
    setState(() {
      _currentFiles[key] = null;
    });
  }

  Future<void> _save(
    UserProfile currentProfile,
    List<VerificationDocument> uploadedDocs,
  ) async {
    // Check if verification status is active (verified or pending)
    final isVerifiedOrPending =
        currentProfile.verificationStatus == 'verified' ||
        currentProfile.verificationStatus == 'pending';

    if (isVerifiedOrPending) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Modificar información'),
          content: const Text(
            'Al modificar tus documentos o datos, perderás tu estatus de verificación actual y tu perfil pasará nuevamente a revisión. ¿Deseas continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              child: const Text('Aceptar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() => _isLoading = true);
    final repo = ref.read(profileRepositoryProvider);

    try {
      // 1. Update Profile Data
      String? newLogoUrl = currentProfile.companyLogoUrl;

      // 2. Upload Logo if selected
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

      // 1. Update Profile Data (Moved after logo upload to include URL)
      final updatedProfile = currentProfile.copyWith(
        isBusinessOwner: _isBusiness,
        companyName: _isBusiness ? _companyNameController.text : null,
        companyRif: _isBusiness ? _rifController.text : null,
        companyAddress: _isBusiness ? _fiscalAddressController.text : null,
        companyLogoUrl: _isBusiness ? newLogoUrl : null,
        // Set to pending if submitting changes
        verificationStatus: 'pending',
      );
      await repo.updateProfile(updatedProfile);

      // 3. Upload Documents
      final filesToUpload = _currentFiles;
      for (var entry in filesToUpload.entries) {
        final label = entry.key;
        final file = entry.value;

        // If file is selected
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Datos guardados y documentos enviados.'),
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error guardando datos: $e')));
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
        error: (e, st) => Center(child: Text('Error: $e')),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('User not found'));
          }

          if (!_isInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _initializeData(profile);
            });
          }

          return verificationDocsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, st) => Center(child: Text('Error loading docs: $e')),
            data: (uploadedDocs) {
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
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
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _rifController,
                        label: 'RIF/NIF/RUT* (Identificación Tributaria)',
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _fiscalAddressController,
                        label: 'Dirección fiscal*',
                        helperText:
                            'Debe ser igual a la que aparece en el RIF/NIF/RUT.',
                        maxLines: 2,
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
                          child:
                              _companyLogo != null && _companyLogo!.path != null
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
                    const SizedBox(height: 16),

                    ..._currentFiles.keys.map((key) {
                      final selectedFile = _currentFiles[key];
                      final alreadyUploaded = _isUploaded(key, uploadedDocs);
                      final isSelected = selectedFile != null;
                      final isDone = alreadyUploaded || isSelected;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            // Status Icon
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isDone
                                    ? Colors.green.withValues(alpha: 0.1)
                                    : colors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isDone
                                    ? Icons.check
                                    : Icons.file_upload_outlined,
                                color: isDone ? Colors.green : colors.primary,
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Text Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    key,
                                    style: textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (isSelected)
                                    Text(
                                      selectedFile.name,
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.grey,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                  else if (alreadyUploaded)
                                    Text(
                                      'Subido - Toca para cambiar',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: Colors.green,
                                      ),
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
                                onPressed: () => _removeFile(key),
                              )
                            else
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                onPressed: () => _pickFile(key),
                              ),
                          ],
                        ),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Verification Note
                    Text(
                      'La verificación de la documentación puede tomar de 48h a 72h.',
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
              );
            },
          );
        },
      ),
    );
  }
}
