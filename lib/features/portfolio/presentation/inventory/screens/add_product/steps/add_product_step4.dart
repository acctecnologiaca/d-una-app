import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../../data/models/brand_model.dart';
import '../../../../../../../shared/widgets/wizard_bottom_bar.dart';
import '../../../../../../../shared/widgets/info_block.dart';
import 'package:material_symbols_icons/symbols.dart';

class AddProductStep4 extends StatelessWidget {
  final Brand? brand;
  final String model;
  final String name;
  final String specs;
  final String? category;
  final File? image;
  final Future<void> Function(ImageSource) onPickImage;
  final VoidCallback onBack;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const AddProductStep4({
    super.key,
    required this.brand,
    required this.model,
    required this.name,
    required this.specs,
    required this.category,
    required this.image,
    required this.onPickImage,
    required this.onBack,
    required this.onCancel,
    required this.onSave,
  });

  Future<void> _pickImage(BuildContext context) async {
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
                  onPickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Cámara'),
                onTap: () {
                  Navigator.pop(context);
                  onPickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Resúmen',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    fontSize: 24,
                    color: colors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Product Icon/Image Circle
                GestureDetector(
                  onTap: () => _pickImage(context),
                  child: Stack(
                    children: [
                      image != null
                          ? CircleAvatar(
                              radius: 60,
                              backgroundImage: FileImage(image!),
                              backgroundColor: colors.surfaceContainerHighest,
                            )
                          : Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: colors.secondaryContainer,
                              ),
                              child: Center(
                                child: Icon(
                                  Symbols.package_2,
                                  weight: 300,
                                  size: 92,
                                  color: colors.onSecondaryContainer,
                                ),
                              ),
                            ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: colors.surface,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: colors.outlineVariant,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.edit,
                            size: 18,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Brand
                Text(
                  brand?.name ?? 'Sin marca',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),

                // Name
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),

                // Model
                Text(
                  model.isNotEmpty ? model : 'Sin modelo',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 32),

                // Details Section
                InfoBlock.text(
                  icon: Icons.category_outlined,
                  label: 'Categoría',
                  value: category ?? 'Sin categoría',
                ),
                const SizedBox(height: 24),
                InfoBlock.text(
                  icon: Icons.description_outlined,
                  label: 'Características',
                  value: specs.isNotEmpty ? specs : 'Sin especificaciones',
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: WizardButtonBar(
            onCancel: onCancel,
            onBack: onBack,
            onNext: onSave,
            labelNext: 'Finalizar',
          ),
        ),
      ],
    );
  }
}
