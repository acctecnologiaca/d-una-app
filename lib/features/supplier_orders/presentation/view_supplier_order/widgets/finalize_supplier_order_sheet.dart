import 'dart:io';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_button.dart';

class FinalizeSupplierOrderSheet extends StatefulWidget {
  final String orderId;

  const FinalizeSupplierOrderSheet({super.key, required this.orderId});

  @override
  State<FinalizeSupplierOrderSheet> createState() =>
      _FinalizeSupplierOrderSheetState();
}

class _FinalizeSupplierOrderSheetState
    extends State<FinalizeSupplierOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  final _documentNumberController = TextEditingController();

  String _documentType = 'invoice'; // 'invoice' | 'delivery_note'
  File? _selectedFile;
  bool _createPurchaseRecord = true;
  bool _isPdf = false;

  @override
  void dispose() {
    _documentNumberController.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Tomar Foto (Cámara)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Elegir de Galería'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Elegir Documento (PDF)'),
                onTap: () {
                  Navigator.pop(context);
                  _pickPdf();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      if (pickedImage != null) {
        setState(() {
          _selectedFile = File(pickedImage.path);
          _isPdf = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al capturar imagen: $e')));
      }
    }
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
          _isPdf = true;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al seleccionar PDF: $e')));
      }
    }
  }

  void _removeAttachment() {
    setState(() {
      _selectedFile = null;
      _isPdf = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isFormValid =
        _selectedFile != null &&
        _documentNumberController.text.trim().isNotEmpty;

    return CustomActionSheet(
      title: 'Finalizar Orden de Compra',
      isContentScrollable: true,
      showDivider: false,
      content: Form(
        key: _formKey,
        onChanged: () =>
            setState(() {}), // Force rebuild to update button state
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Type selector
            Text(
              'Tipo de documento',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'invoice',
                  label: Text('Factura'),
                  icon: Icon(Icons.receipt_outlined),
                ),
                ButtonSegment(
                  value: 'delivery_note',
                  label: Text('Nota de Entrega'),
                  icon: Icon(Icons.description_outlined),
                ),
              ],
              selected: {_documentType},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _documentType = selection.first;
                });
              },
            ),
            const SizedBox(height: 20),

            // Document number input
            CustomTextField(
              label: 'Número de documento',
              hintText: 'Ej. F-92810 o NE-2831',
              controller: _documentNumberController,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Este campo es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),

            // File Attachment Area
            Text(
              'Soporte digital',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: colors.outlineVariant),
              ),
              color: colors.surface,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: _selectedFile == null
                    ? InkWell(
                        onTap: _pickAttachment,
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Column(
                            children: [
                              Icon(
                                Symbols.cloud_upload,
                                size: 40,
                                color: colors.primary,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Presione para adjuntar comprobante',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Formatos admitidos: Imagen o PDF',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : Row(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: colors.primaryContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              _isPdf
                                  ? Icons.picture_as_pdf_outlined
                                  : Icons.image_outlined,
                              color: colors.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFile!.path
                                      .split(Platform.pathSeparator)
                                      .last,
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _isPdf ? 'Documento PDF' : 'Imagen capturada',
                                  style: textTheme.bodySmall?.copyWith(
                                    color: colors.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: colors.error,
                            ),
                            onPressed: _removeAttachment,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Register purchase toggle
            SwitchListTile(
              title: const Text('Registrar como compra en inventario'),
              subtitle: const Text('Actualiza automáticamente el stock propio'),
              value: _createPurchaseRecord,
              onChanged: (bool value) {
                setState(() {
                  _createPurchaseRecord = value;
                });
              },
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: colors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Al finalizar, los créditos correspondientes serán otorgados a tu cuenta y el comprobante pasará a estatus "En revisión".',
                      style: textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomButton(
                text: 'Finalizar',
                isFullWidth: false,
                onPressed: isFormValid
                    ? () {
                        if (_formKey.currentState?.validate() == true) {
                          Navigator.pop(context, {
                            'photoFile': _selectedFile,
                            'documentType': _documentType,
                            'documentNumber': _documentNumberController.text
                                .trim(),
                            'createPurchaseRecord': _createPurchaseRecord,
                          });
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
