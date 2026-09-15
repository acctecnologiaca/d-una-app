import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/products_provider.dart';
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
    if (note.hasMissingSerialsEffective) {
      return CustomDialog.show(
        context: context,
        dialog: CustomDialog.confirmation(
          icon: Symbols.warning,
          iconColor: Colors.amber.shade800,
          title: 'Seriales pendientes',
          contentText:
              'No se puede confirmar la recepción porque faltan seriales por asignar a uno o más productos.',
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => ConfirmDeliveryNoteReceptionDialog(note: note),
    );
  }

  @override
  ConsumerState<ConfirmDeliveryNoteReceptionDialog> createState() =>
      _ConfirmDeliveryNoteReceptionDialogState();
}

class _ConfirmDeliveryNoteReceptionDialogState
    extends ConsumerState<ConfirmDeliveryNoteReceptionDialog> {
  static const _defaultRelationships = [
    'Titular',
    'Encargado',
    'Vigilancia',
    'Recepción',
    'Otro',
  ];

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _phoneController;
  late TextEditingController _relationshipController;

  String? _selectedRelationship;
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

    final initialRel = widget.note.receiverRelationship ?? 'Titular';
    if (_defaultRelationships.contains(initialRel)) {
      _selectedRelationship = initialRel;
      _relationshipController = TextEditingController(text: initialRel);
    } else if (initialRel.isNotEmpty) {
      _selectedRelationship = 'Otro';
      _relationshipController = TextEditingController(text: initialRel);
    } else {
      _selectedRelationship = 'Titular';
      _relationshipController = TextEditingController(text: 'Titular');
    }
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
    final validPoints = _points.where((p) => p != null).toList();
    if (validPoints.isEmpty) return null;

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
    if (widget.note.hasMissingSerialsEffective) {
      AppToast.error(
        context,
        message:
            'No se puede confirmar la recepción porque faltan seriales por asignar.',
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_nameController.text.trim().isEmpty ||
        _idController.text.trim().isEmpty) {
      AppToast.error(
        context,
        message: 'Debe ingresar el nombre y documento de quien recibe',
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final signature = await _exportSignatureAsBase64();
      final finalRelationship = _selectedRelationship == 'Otro'
          ? _relationshipController.text.trim()
          : (_selectedRelationship ?? _relationshipController.text.trim());

      await ref.read(deliveryNotesRepositoryProvider).confirmReception(
            widget.note.id,
            receivedByName: _nameController.text.trim(),
            receivedById: _idController.text.trim(),
            receivedByPhone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            receiverRelationship: finalRelationship.isEmpty ? null : finalRelationship,
            signatureData: signature,
            status: DeliveryNoteStatus.delivered,
          );

      ref.invalidate(deliveryNoteDetailProvider(widget.note.id));
      ref.read(paginatedDeliveryNotesProvider.notifier).refresh();
      ref.invalidate(productsProvider);
      ref.invalidate(paginatedProductsProvider);

      if (mounted) {
        context.pop();
        AppToast.success(
          context,
          message: 'Recepción y entrega confirmada exitosamente',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(
          context,
          message: 'Error al confirmar recepción: $e',
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildSummaryCard(BuildContext context, ColorScheme colors, TextTheme textTheme) {
    final serialsCount =
        widget.note.items.fold(0, (sum, i) => sum + i.serials.length);
    final itemsCount = widget.note.items.length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Symbols.local_shipping,
              size: 20,
              color: colors.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.note.deliveryNoteNumber,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.note.clientName.isEmpty
                      ? 'Sin cliente asignado'
                      : widget.note.clientName,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '$itemsCount ${itemsCount == 1 ? "producto" : "productos"} · $serialsCount ${serialsCount == 1 ? "serial" : "seriales"}',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureArea(BuildContext context, ColorScheme colors, TextTheme textTheme) {
    final hasPoints = _points.any((p) => p != null);
    final strokeColor = colors.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(Symbols.draw, size: 18, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Firma digital del receptor (Opcional)',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            if (hasPoints)
              IconButton(
                icon: Icon(
                  Symbols.ink_eraser,
                  size: 20,
                  color: colors.error,
                ),
                tooltip: 'Borrar firma',
                visualDensity: VisualDensity.compact,
                onPressed: () => setState(() => _points.clear()),
              ),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final boxWidth = constraints.maxWidth;
            const boxHeight = 140.0;

            return Container(
              height: boxHeight,
              width: boxWidth,
              decoration: BoxDecoration(
                color: colors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.8),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    if (!hasPoints)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Symbols.gesture,
                              size: 32,
                              color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Dibuje la firma aquí con su dedo',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onPanDown: (details) {
                        final pos = details.localPosition;
                        if (pos.dx >= 0 &&
                            pos.dx <= boxWidth &&
                            pos.dy >= 0 &&
                            pos.dy <= boxHeight) {
                          setState(() {
                            _points.add(pos);
                          });
                        }
                      },
                      onPanUpdate: (details) {
                        final pos = details.localPosition;
                        if (pos.dx >= 0 &&
                            pos.dx <= boxWidth &&
                            pos.dy >= 0 &&
                            pos.dy <= boxHeight) {
                          setState(() {
                            _points.add(pos);
                          });
                        } else {
                          // Si el trazo sale del recuadro, levantar la pluma para no rayar fuera
                          if (_points.isNotEmpty && _points.last != null) {
                            setState(() {
                              _points.add(null);
                            });
                          }
                        }
                      },
                      onPanEnd: (_) {
                        setState(() {
                          _points.add(null);
                        });
                      },
                      child: CustomPaint(
                        painter: _SignaturePainter(_points, strokeColor),
                        size: Size(boxWidth, boxHeight),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildNoticeCard(ColorScheme colors, TextTheme textTheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Symbols.info, size: 18, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Al confirmar la recepción, la nota de entrega pasará a estatus "Entregada", se registrarán los datos del receptor y se actualizará el inventario correspondiente.',
              style: textTheme.bodySmall?.copyWith(
                color: colors.onSurfaceVariant,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return CustomActionSheet(
      title: 'Confirmar recepción de entrega',
      isContentScrollable: true,
      showDivider: false,
      content: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryCard(context, colors, textTheme),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _nameController,
              label: 'Nombre de quien recibe *',
              hintText: 'Ej. Juan Pérez',
              prefixIcon: const Icon(Symbols.person),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Este campo es requerido' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _idController,
              label: 'Cédula / Documento de identidad *',
              hintText: 'Ej. V-12345678',
              prefixIcon: const Icon(Symbols.badge),
              validator: (val) =>
                  val == null || val.trim().isEmpty ? 'Este campo es requerido' : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _phoneController,
              label: 'Teléfono de contacto',
              hintText: 'Ej. 0412-1234567',
              prefixIcon: const Icon(Symbols.call),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 16),
            CustomDropdown<String>(
              value: _selectedRelationship,
              items: _defaultRelationships,
              label: 'Relación o cargo con el cliente',
              isRequired: false,
              itemLabelBuilder: (item) => item,
              onChanged: (val) {
                setState(() {
                  _selectedRelationship = val;
                  if (val != 'Otro') {
                    _relationshipController.text = val ?? '';
                  } else {
                    _relationshipController.text = '';
                  }
                });
              },
            ),
            if (_selectedRelationship == 'Otro') ...[
              const SizedBox(height: 16),
              CustomTextField(
                controller: _relationshipController,
                label: 'Especificar relación o cargo *',
                hintText: 'Ej. Administrador, Almacenista, etc.',
                prefixIcon: const Icon(Symbols.work),
                validator: (val) {
                  if (_selectedRelationship == 'Otro' &&
                      (val == null || val.trim().isEmpty)) {
                    return 'Indique el cargo o relación';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 20),
            _buildSignatureArea(context, colors, textTheme),
            const SizedBox(height: 20),
            _buildNoticeCard(colors, textTheme),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomButton(
            text: _isSaving ? 'Confirmando...' : 'Confirmar entrega',
            icon: Symbols.check_circle,
            isFullWidth: true,
            isLoading: _isSaving,
            onPressed: _isSaving ? null : _handleConfirm,
          ),
        ),
      ],
    );
  }
}

class _SignaturePainter extends CustomPainter {
  final List<Offset?> points;
  final Color strokeColor;

  _SignaturePainter(this.points, this.strokeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 2.5;

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) =>
      oldDelegate.points.length != points.length ||
      oldDelegate.strokeColor != strokeColor;
}

