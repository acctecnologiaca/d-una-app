import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import '../../../domain/models/delivery_note_status.dart';
import '../providers/create_delivery_note_provider.dart';

class DeliveryNoteReceptionTab extends ConsumerStatefulWidget {
  const DeliveryNoteReceptionTab({super.key});

  @override
  ConsumerState<DeliveryNoteReceptionTab> createState() =>
      _DeliveryNoteReceptionTabState();
}

class _DeliveryNoteReceptionTabState
    extends ConsumerState<DeliveryNoteReceptionTab> {
  late final TextEditingController _nameController;
  late final TextEditingController _idController;
  late final TextEditingController _phoneController;

  bool _recordReceptionNow = false;
  String _relationship = 'Titular';
  final List<Offset?> _signaturePoints = [];

  @override
  void initState() {
    super.initState();
    final state = ref.read(createDeliveryNoteProvider);
    _nameController = TextEditingController(text: state.receivedByName ?? '');
    _idController = TextEditingController(text: state.receivedById ?? '');
    _phoneController = TextEditingController(text: state.receivedByPhone ?? '');
    _relationship = state.receiverRelationship ?? 'Titular';
    _recordReceptionNow = state.receivedByName != null && state.receivedByName!.isNotEmpty;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _idController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _captureSignature() async {
    if (_signaturePoints.isEmpty) return;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(
      recorder,
      Rect.fromPoints(const Offset(0, 0), const Offset(300, 150)),
    );

    final paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    for (int i = 0; i < _signaturePoints.length - 1; i++) {
      if (_signaturePoints[i] != null && _signaturePoints[i + 1] != null) {
        canvas.drawLine(_signaturePoints[i]!, _signaturePoints[i + 1]!, paint);
      }
    }

    final picture = recorder.endRecording();
    final img = await picture.toImage(300, 150);
    final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

    if (pngBytes != null) {
      final base64String =
          'data:image/png;base64,${base64Encode(pngBytes.buffer.asUint8List())}';
      ref
          .read(createDeliveryNoteProvider.notifier)
          .setReceptionData(signatureData: base64String);
    }
  }

  void _syncReceptionData() {
    final notifier = ref.read(createDeliveryNoteProvider.notifier);

    if (!_recordReceptionNow) {
      notifier.setReceptionData(
        receivedByName: null,
        receivedById: null,
        receivedByPhone: null,
        receiverRelationship: null,
        signatureData: null,
        status: DeliveryNoteStatus.draft,
      );
      return;
    }

    final name = _nameController.text.trim();
    final id = _idController.text.trim();
    final phone = _phoneController.text.trim();

    notifier.setReceptionData(
      receivedByName: name.isNotEmpty ? name : null,
      receivedById: id.isNotEmpty ? id : null,
      receivedByPhone: phone.isNotEmpty ? phone : null,
      receiverRelationship: _relationship,
      status: (name.isNotEmpty && id.isNotEmpty)
          ? DeliveryNoteStatus.finalized
          : DeliveryNoteStatus.draft,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(createDeliveryNoteProvider);
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Resumen ejecutivo de la nota de entrega
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Resumen de Despacho',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      currencyFormat.format(state.total),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Cliente: ${state.clientName ?? "No seleccionado"}',
                  style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                ),
                Text(
                  'Productos: ${state.items.length} (${state.items.fold<int>(0, (sum, i) => sum + i.quantity.round())} unidades)',
                  style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
                ),
                if (state.hasMissingSerials) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 16, color: Colors.amber.shade900),
                      const SizedBox(width: 6),
                      Text(
                        'Advertencia: Faltan ${state.missingSerialsCount} seriales por asignar',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.amber.shade900,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Tarjeta interactiva para registrar firma física en persona
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: _recordReceptionNow
                    ? colors.primary
                    : colors.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    value: _recordReceptionNow,
                    contentPadding: EdgeInsets.zero,
                    activeThumbColor: colors.primary,
                    title: const Text(
                      'Registrar recepción y firma ahora',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'Si la entrega es presencial, capture los datos y la firma del receptor directamente en pantalla.',
                      style: TextStyle(fontSize: 12),
                    ),
                    onChanged: (val) {
                      setState(() {
                        _recordReceptionNow = val;
                      });
                      _syncReceptionData();
                    },
                  ),

                  if (_recordReceptionNow) ...[
                    const Divider(height: 24),
                    CustomTextField(
                      controller: _nameController,
                      label: 'Nombre y apellido de quien recibe *',
                      hintText: 'Ej. Carlos Méndez',
                      onChanged: (_) => _syncReceptionData(),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _idController,
                            label: 'Cédula / Documento *',
                            hintText: 'Ej. V-14.821.902',
                            onChanged: (_) => _syncReceptionData(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CustomTextField(
                            controller: _phoneController,
                            label: 'Teléfono de contacto',
                            hintText: 'Ej. 0412-1234567',
                            onChanged: (_) => _syncReceptionData(),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    CustomDropdown<String>(
                      value: _relationship,
                      items: const [
                        'Titular',
                        'Representante',
                        'Empleado',
                        'Familiar',
                        'Vigilancia',
                        'Otro',
                      ],
                      label: 'Relación con el cliente',
                      itemLabelBuilder: (r) => r,
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _relationship = val);
                          _syncReceptionData();
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    Text(
                      'Firma digital de conformidad',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Canvas de firma táctil
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.5),
                        ),
                      ),
                      child: GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            final point = details.localPosition;
                            _signaturePoints.add(point);
                          });
                        },
                        onPanEnd: (details) {
                          _signaturePoints.add(null);
                          _captureSignature();
                        },
                        child: CustomPaint(
                          painter: _SignaturePainter(_signaturePoints),
                          size: Size.infinite,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Dibuje con el dedo sobre el recuadro',
                          style: TextStyle(
                            fontSize: 11,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _signaturePoints.clear();
                            });
                            ref.read(createDeliveryNoteProvider.notifier).clearSignature();
                          },
                          child: const Text('Limpiar firma', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ] else ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.public, size: 18, color: colors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'El receptor podrá firmar digitalmente desde su teléfono al abrir el enlace web que le envíe por WhatsApp o correo.',
                              style: TextStyle(
                                fontSize: 12,
                                color: colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
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
      ..color = Colors.black
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
