import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import '../../../domain/models/delivery_note_model.dart';
import '../../../domain/models/delivery_note_status.dart';
import '../../delivery_notes_list/providers/delivery_notes_providers.dart';

class ConfirmDeliveryNoteReceptionDialog extends ConsumerStatefulWidget {
  final DeliveryNoteModel note;

  const ConfirmDeliveryNoteReceptionDialog({super.key, required this.note});

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    DeliveryNoteModel note,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => ConfirmDeliveryNoteReceptionDialog(note: note),
    );
  }

  @override
  ConsumerState<ConfirmDeliveryNoteReceptionDialog> createState() =>
      _ConfirmDeliveryNoteReceptionDialogState();
}

class _ConfirmDeliveryNoteReceptionDialogState
    extends ConsumerState<ConfirmDeliveryNoteReceptionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _phoneController;
  late TextEditingController _relationshipController;

  final List<Offset?> _points = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.note.receivedByName ?? widget.note.contactName ?? '',
    );
    _idController = TextEditingController(text: widget.note.receivedById ?? '');
    _phoneController = TextEditingController(
      text: widget.note.receivedByPhone ?? widget.note.contactPhone ?? '',
    );
    _relationshipController = TextEditingController(
      text: widget.note.receiverRelationship ?? 'Titular',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    _relationshipController.dispose();
    super.dispose();
  }

  Future<String?> _exportSignatureAsBase64() async {
    if (_points.isEmpty) return null;
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromPoints(const Offset(0, 0), const Offset(300, 150)),
      );

      final paint = Paint()
        ..color = Colors.black
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 3.0;

      for (int i = 0; i < _points.length - 1; i++) {
        if (_points[i] != null && _points[i + 1] != null) {
          canvas.drawLine(_points[i]!, _points[i + 1]!, paint);
        }
      }

      final picture = recorder.endRecording();
      final img = await picture.toImage(300, 150);
      final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final pngBytes = byteData.buffer.asUint8List();
      return 'data:image/png;base64,${base64Encode(pngBytes)}';
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleConfirm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_nameController.text.trim().isEmpty || _idController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debe ingresar el nombre y documento del receptor')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final signature = await _exportSignatureAsBase64();

      await ref.read(deliveryNotesRepositoryProvider).confirmReception(
            widget.note.id,
            receivedByName: _nameController.text.trim(),
            receivedById: _idController.text.trim(),
            receivedByPhone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            receiverRelationship: _relationshipController.text.trim().isEmpty
                ? null
                : _relationshipController.text.trim(),
            signatureData: signature,
            status: DeliveryNoteStatus.delivered,
          );

      ref.invalidate(deliveryNoteDetailProvider(widget.note.id));
      ref.read(paginatedDeliveryNotesProvider.notifier).refresh();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recepción y entrega confirmada exitosamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al confirmar recepción: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Confirmar Recepción',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              CustomTextField(
                controller: _nameController,
                label: 'Nombre de quien recibe *',
                hintText: 'Ej. Juan Pérez',
                validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _idController,
                      label: 'Cédula / Identificación *',
                      hintText: 'V-12345678',
                      validator: (val) => val == null || val.trim().isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomTextField(
                      controller: _phoneController,
                      label: 'Teléfono',
                      hintText: '0412-1234567',
                      keyboardType: TextInputType.phone,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              CustomTextField(
                controller: _relationshipController,
                label: 'Relación / Cargo con el cliente',
                hintText: 'Ej. Titular, Encargado, Vigilancia, etc.',
              ),
              const SizedBox(height: 16),
              const Text(
                'Firma digital del receptor:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Container(
                height: 140,
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.outlineVariant),
                ),
                child: GestureDetector(
                  onPanUpdate: (details) {
                    setState(() {
                      _points.add(details.localPosition);
                    });
                  },
                  onPanEnd: (_) => _points.add(null),
                  child: CustomPaint(
                    painter: _SignaturePainter(_points),
                    size: Size.infinite,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Dibuje la firma aquí',
                    style: TextStyle(fontSize: 11, color: colors.onSurfaceVariant),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _points.clear());
                    },
                    child: const Text('Limpiar firma', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CustomButton(
                text: _isSaving ? 'Guardando...' : 'Confirmar Entrega',
                icon: Icons.check_circle_outline,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _handleConfirm,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  _SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
