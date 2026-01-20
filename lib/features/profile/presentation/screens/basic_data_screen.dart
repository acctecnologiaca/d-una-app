import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../domain/models/user_profile.dart';
import '../providers/profile_provider.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/form_bottom_bar.dart';

class BasicDataScreen extends ConsumerStatefulWidget {
  const BasicDataScreen({super.key});

  @override
  ConsumerState<BasicDataScreen> createState() => _BasicDataScreenState();
}

class _BasicDataScreenState extends ConsumerState<BasicDataScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _lastNameController;
  late TextEditingController _idController;
  late TextEditingController _dobController;

  String? _selectedGender;
  DateTime? _selectedDate;
  File? _avatarFile;
  String? _avatarUrl;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;
  bool _initialDataLoaded = false;

  // Initial state to track changes
  String _initialName = '';
  String _initialLastName = '';
  String _initialId = '';
  String? _initialGender;
  DateTime? _initialDate;
  String? _initialAvatarUrl;

  bool get _hasChanges {
    return _nameController.text != _initialName ||
        _lastNameController.text != _initialLastName ||
        _idController.text != _initialId ||
        _selectedGender != _initialGender ||
        _selectedDate != _initialDate ||
        _avatarFile != null;
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController()..addListener(_onFieldChanged);
    _lastNameController = TextEditingController()..addListener(_onFieldChanged);
    _idController = TextEditingController()..addListener(_onFieldChanged);
    _dobController = TextEditingController();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  UserProfile? _lastLoadedProfile;

  void _populateData(UserProfile profile) {
    if (_lastLoadedProfile == profile && _initialDataLoaded) return;
    _lastLoadedProfile = profile;

    _initialName = profile.firstName ?? '';
    _initialLastName = profile.lastName ?? '';
    _initialId = profile.nationalId ?? '';
    _initialGender = profile.gender;
    _initialAvatarUrl = profile.avatarUrl;
    _initialDate = profile.birthDate;

    // Force update pristine form
    _nameController.text = _initialName;
    _lastNameController.text = _initialLastName;
    _idController.text = _initialId;
    _selectedGender = _initialGender;
    _selectedDate = _initialDate;
    _avatarUrl = _initialAvatarUrl;

    if (_initialDate != null) {
      _dobController.text = DateFormat('dd/MM/yyyy').format(_initialDate!);
    }

    _initialDataLoaded = true;
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _lastNameController.dispose();
    _idController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromSource(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    try {
      final theme = Theme.of(context);
      final primaryColor = theme.colorScheme.primary;
      final onPrimaryColor = theme.colorScheme.onPrimary;

      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: image.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Recortar',
              toolbarColor: primaryColor,
              toolbarWidgetColor: onPrimaryColor,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(title: 'Recortar'),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _avatarFile = File(croppedFile.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }

  Future<void> _save(String userId, UserProfile currentProfile) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? newAvatarUrl = _avatarUrl;

      // Upload avatar if changed
      if (_avatarFile != null) {
        final repo = ref.read(profileRepositoryProvider);
        final bytes = await _avatarFile!.readAsBytes();
        final fileExt = _avatarFile!.path.split('.').last;
        newAvatarUrl = await repo.uploadAvatar(userId, bytes, fileExt);
      }

      // Update Profile
      final updatedProfile = currentProfile.copyWith(
        firstName: _nameController.text,
        lastName: _lastNameController.text,
        nationalId: _idController.text,
        gender: _selectedGender,
        birthDate: _selectedDate,
        avatarUrl: newAvatarUrl,
      );

      await ref.read(profileRepositoryProvider).updateProfile(updatedProfile);
      ref.invalidate(userProfileProvider);

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos actualizados correctamente')),
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dobController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  ImageProvider _getAvatarImage() {
    if (_avatarFile != null) {
      return FileImage(_avatarFile!);
    } else if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
      return NetworkImage(_avatarUrl!);
    } else {
      return const NetworkImage('https://i.pravatar.cc/300?img=11');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profileAsync = ref.watch(userProfileProvider);

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
          'Datos básicos',
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
          : profileAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
              data: (profile) {
                if (profile != null) {
                  _populateData(profile);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Avatar with Edit Icon
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundImage: _getAvatarImage(),
                                backgroundColor: colors.surfaceContainerHighest,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: _pickImage,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colors.primary,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colors.surface,
                                        width: 2,
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.edit,
                                      size: 20,
                                      color: colors.onPrimary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Name Field
                        CustomTextField(
                          controller: _nameController,
                          label: 'Nombre*',
                        ),
                        const SizedBox(height: 16),

                        // Last Name Field
                        CustomTextField(
                          controller: _lastNameController,
                          label: 'Apellido*',
                        ),
                        const SizedBox(height: 16),

                        // Date of Birth Field
                        GestureDetector(
                          onTap: () => _selectDate(context),
                          child: AbsorbPointer(
                            child: CustomTextField(
                              controller: _dobController,
                              label: 'Fecha de nacimiento*',
                              suffixIcon: const Icon(
                                Icons.calendar_today_outlined,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Gender Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DropdownButtonFormField<String>(
                              initialValue: _selectedGender,
                              decoration: InputDecoration(
                                labelText: 'Género*',
                                floatingLabelBehavior:
                                    FloatingLabelBehavior.always,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  borderSide: BorderSide(
                                    color: Colors.grey.shade400,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                                filled: true,
                                fillColor: Colors.white,
                              ),
                              items: ['Masculino', 'Femenino', 'Otro']
                                  .map(
                                    (label) => DropdownMenuItem(
                                      value: label,
                                      child: Text(label),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedGender = value;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ID Field
                        CustomTextField(
                          controller: _idController,
                          label: 'Cédula/DNI/ID*',
                        ),
                        const SizedBox(height: 48),

                        // Actions
                        FormBottomBar(
                          onCancel: () => context.pop(),
                          onSave: _hasChanges && profile != null
                              ? () => _save(profile.id, profile)
                              : null,
                          isSaveEnabled: _hasChanges && profile != null,
                          isLoading: _isLoading,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
