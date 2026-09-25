import 'dart:convert';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'package:d_una_app/shared/widgets/info_disclaimer_card.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/products_provider.dart';
import '../../../domain/models/delivery_note_model.dart';
import '../../../domain/models/delivery_note_status.dart';
import '../../delivery_notes_list/providers/delivery_notes_providers.dart';
import 'package:d_una_app/shared/widgets/bottom_sheet_action_item.dart';
import 'package:d_una_app/features/supplier_orders/domain/models/supplier_order_status.dart';
import 'package:d_una_app/features/supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import 'send_delivery_note_whatsapp_sheet.dart';
import 'send_delivery_note_email_sheet.dart';
import 'package:d_una_app/features/quotes/presentation/view_quote/providers/view_quote_provider.dart';

class ConfirmDeliveryNoteReceptionDialog extends ConsumerStatefulWidget {
  final DeliveryNoteModel note;

  const ConfirmDeliveryNoteReceptionDialog({super.key, required this.note});

  static Future<void> show(
    BuildContext context,
    WidgetRef ref,
    DeliveryNoteModel note,
  ) async {
    if (note.hasMissingSerialsEffective) {
      await CustomDialog.show(
        context: context,
        dialog: CustomDialog.confirmation(
          icon: Symbols.warning,
          iconColor: Colors.amber.shade800,
          title: 'Seriales pendientes',
          contentText:
              'No se puede confirmar la recepción porque faltan seriales por asignar a uno o más productos.',
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    final updatedNote = await showModalBottomSheet<DeliveryNoteModel>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (sheetContext) => ConfirmDeliveryNoteReceptionDialog(note: note),
    );

    if (updatedNote != null && context.mounted) {
      AppToast.success(
        context,
        message: 'Recepción y entrega confirmada exitosamente',
      );

      CustomActionSheet.show(
        context: context,
        title: 'Recepción confirmada (${updatedNote.deliveryNoteNumber})',
        actions: [
          BottomSheetActionItem(
            icon: Icons.send_outlined,
            label: 'Enviar copia ahora',
            subtitle:
                'Enviar constancia de entrega digital por WhatsApp o Correo',
            onTap: () {
              Navigator.of(context).pop();
              final recipientEmail = (updatedNote.contactEmail != null &&
                      updatedNote.contactEmail!.trim().isNotEmpty)
                  ? updatedNote.contactEmail!.trim()
                  : updatedNote.clientEmail?.trim();
              final hasEmail =
                  recipientEmail != null && recipientEmail.isNotEmpty;

              CustomActionSheet.show(
                context: context,
                title: 'Enviar copia de Nota de Entrega',
                actions: [
                  BottomSheetActionItem(
                    icon: Icons.email_outlined,
                    label: 'Enviar por correo electrónico',
                    enabled: hasEmail,
                    subtitle: hasEmail
                        ? null
                        : 'El destinatario no tiene correo electrónico registrado',
                    onTap: hasEmail
                        ? () {
                            Navigator.of(context).pop();
                            SendDeliveryNoteEmailSheet.show(
                              context,
                              updatedNote,
                            );
                          }
                        : null,
                  ),
                  BottomSheetActionItem(
                    icon: 'assets/icons/whatsapp_icon.png',
                    label: 'Enviar por WhatsApp',
                    onTap: () {
                      Navigator.of(context).pop();
                      SendDeliveryNoteWhatsAppSheet.show(
                        context,
                        updatedNote,
                      );
                    },
                  ),
                ],
              );
            },
          ),
          BottomSheetActionItem(
            icon: Icons.history_outlined,
            label: 'Más tarde',
            onTap: () => Navigator.of(context).pop(),
          ),
        ],
      );
    }
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

  static const _phoneCodes = [
    '0412',
    '0422',
    '0414',
    '0424',
    '0416',
    '0426',
  ];

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _idController;
  late TextEditingController _phoneController;
  late TextEditingController _relationshipController;

  String? _selectedPhoneCode;
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

    final rawPhone = widget.note.receivedByPhone ??
        widget.note.contactPhone ??
        widget.note.clientPhone ??
        '';
    final digits = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 4) {
      final code = digits.substring(0, 4);
      if (_phoneCodes.contains(code)) {
        _selectedPhoneCode = code;
        _phoneController = TextEditingController(text: digits.substring(4));
      } else {
        _selectedPhoneCode = '0412';
        _phoneController = TextEditingController(text: digits);
      }
    } else {
      _selectedPhoneCode = '0412';
      _phoneController = TextEditingController(text: digits);
    }

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
    final validPoints = _points.whereType<Offset>().toList();
    if (validPoints.isEmpty) return null;

    try {
      // 1. Determinar el bounding box de los trazos reales
      double minX = double.infinity;
      double maxX = double.negativeInfinity;
      double minY = double.infinity;
      double maxY = double.negativeInfinity;

      for (final p in validPoints) {
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }

      final signatureWidth = maxX - minX;
      final signatureHeight = maxY - minY;

      // 2. Margen perimetral uniforme
      const padding = 20.0;
      final targetWidth = (signatureWidth + padding * 2).clamp(160.0, 1200.0);
      final targetHeight = (signatureHeight + padding * 2).clamp(80.0, 600.0);

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(
        recorder,
        Rect.fromLTWH(0, 0, targetWidth, targetHeight),
      );

      // 3. Centrar matemáticamente la firma en el canvas resultante
      final signatureCenterX = (minX + maxX) / 2;
      final signatureCenterY = (minY + maxY) / 2;
      final canvasCenterX = targetWidth / 2;
      final canvasCenterY = targetHeight / 2;

      canvas.translate(
        canvasCenterX - signatureCenterX,
        canvasCenterY - signatureCenterY,
      );

      final paint = Paint()
        ..color = Colors.black
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..strokeWidth = 3.5;

      for (int i = 0; i < _points.length; i++) {
        final current = _points[i];
        if (current != null) {
          final next = (i < _points.length - 1) ? _points[i + 1] : null;
          if (next != null) {
            canvas.drawLine(current, next, paint);
          } else {
            final prev = (i > 0) ? _points[i - 1] : null;
            if (prev == null) {
              canvas.drawCircle(current, paint.strokeWidth / 2, paint);
            }
          }
        }
      }

      final picture = recorder.endRecording();
      final img =
          await picture.toImage(targetWidth.round(), targetHeight.round());
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

      final finalPhone = _phoneController.text.trim().isEmpty
          ? null
          : '$_selectedPhoneCode${_phoneController.text.trim()}';

      await ref
          .read(deliveryNotesRepositoryProvider)
          .confirmReception(
            widget.note.id,
            receivedByName: _nameController.text.trim(),
            receivedById: _idController.text.trim(),
            receivedByPhone: finalPhone,
            receiverRelationship: finalRelationship.isEmpty
                ? null
                : finalRelationship,
            signatureData: signature,
            status: DeliveryNoteStatus.delivered,
          );

      ref.invalidate(deliveryNoteDetailProvider(widget.note.id));
      ref.read(paginatedDeliveryNotesProvider.notifier).refresh();
      ref.invalidate(productsProvider);
      ref.read(paginatedProductsProvider.notifier).refresh();
      ref.invalidate(paginatedProductSearchProvider);

      if (widget.note.quoteId != null && widget.note.quoteId!.isNotEmpty) {
        ref.invalidate(viewQuoteProvider(widget.note.quoteId!));
        ref.invalidate(linkedSupplierOrdersProvider(widget.note.quoteId!));
        try {
          await ref
              .read(supplierOrdersRepositoryProvider)
              .finalizeDropshippingOrdersByQuoteId(widget.note.quoteId!);
          ref.invalidate(paginatedSupplierOrdersProvider);
        } catch (e) {
          debugPrint(
            'Error auto-finalizando órdenes dropshipping vinculadas a la cotización: $e',
          );
        }
      }

      if (widget.note.supplierOrderId != null &&
          widget.note.supplierOrderId!.isNotEmpty) {
        try {
          await ref
              .read(supplierOrdersRepositoryProvider)
              .updateSupplierOrderStatus(
                widget.note.supplierOrderId!,
                SupplierOrderStatus.finalized.dbValue,
              );
          ref.invalidate(paginatedSupplierOrdersProvider);
        } catch (e) {
          debugPrint('Error auto-finalizando orden de compra vinculada: $e');
        }
      }

      if (mounted) {
        final updatedNote = widget.note.copyWith(
          status: DeliveryNoteStatus.finalized,
          receivedByName: _nameController.text.trim(),
          receivedById: _idController.text.trim(),
          receivedByPhone: finalPhone,
          receiverRelationship:
              finalRelationship.isEmpty ? null : finalRelationship,
          signatureData: signature,
          receivedAt: DateTime.now(),
        );

        Navigator.of(context).pop(updatedNote);
      }
    } catch (e) {
      if (mounted) {
        AppToast.error(context, message: 'Error al confirmar recepción: $e');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }


  Widget _buildSignatureArea(
    BuildContext context,
    ColorScheme colors,
    TextTheme textTheme,
  ) {
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
                icon: Icon(Symbols.ink_eraser, size: 20, color: colors.error),
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
            const boxHeight = 150.0;

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
                              color: colors.onSurfaceVariant.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Dibuje la firma aquí con su dedo',
                              style: textTheme.bodySmall?.copyWith(
                                color: colors.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
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
            CustomTextField(
              controller: _nameController,
              label: 'Nombre de quien recibe *',
              helperText: 'Ej: Juan Pérez',
              prefixIcon: const Icon(Symbols.person),
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Este campo es requerido'
                  : null,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _idController,
              label: 'Cédula / Documento de identidad *',
              helperText: 'Ej: V12345678',
              prefixIcon: const Icon(Symbols.badge),
              validator: (val) => val == null || val.trim().isEmpty
                  ? 'Este campo es requerido'
                  : null,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 110,
                  child: CustomDropdown<String>(
                    value: _selectedPhoneCode,
                    label: 'Código',
                    isRequired: false,
                    items: _phoneCodes,
                    itemLabelBuilder: (item) => item,
                    onChanged: (val) {
                      setState(() => _selectedPhoneCode = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomTextField(
                    controller: _phoneController,
                    label: 'Teléfono',
                    helperText: 'Ej: 1234567',
                    prefixIcon: const Icon(Symbols.call),
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomDropdown<String>(
              value: _selectedRelationship,
              items: _defaultRelationships,
              label: 'Cargo o relación con el cliente',
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
                label: 'Especificar cargo o relación*',
                helperText: 'Ej: Administrador, Almacenista, etc.',
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
            const InfoDisclaimerCard(
              text:
                  'Al confirmar la recepción, la nota de entrega pasará a estatus "Finalizada", se registrarán los datos del receptor y se descontará el inventario correspondiente.',
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomButton(
                text: _isSaving ? 'Confirmando...' : 'Confirmar entrega',
                isFullWidth: false,
                isLoading: _isSaving,
                onPressed: _isSaving ? null : _handleConfirm,
              ),
            ],
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
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 2.5;

    for (int i = 0; i < points.length; i++) {
      final current = points[i];
      if (current != null) {
        final next = (i < points.length - 1) ? points[i + 1] : null;
        if (next != null) {
          canvas.drawLine(current, next, paint);
        } else {
          final prev = (i > 0) ? points[i - 1] : null;
          if (prev == null) {
            canvas.drawCircle(current, paint.strokeWidth / 2, paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) =>
      oldDelegate.points.length != points.length ||
      oldDelegate.strokeColor != strokeColor;
}

