import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';
import 'package:d_una_app/shared/widgets/credit_banner_card.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import 'package:d_una_app/core/utils/phone_utils.dart';
import 'package:d_una_app/core/services/whatsapp_repository.dart';
import 'package:d_una_app/core/providers/credits_providers.dart';
import 'package:d_una_app/features/profile/presentation/providers/profile_provider.dart';
import '../../../domain/models/delivery_note_model.dart';
import '../../../domain/models/delivery_note_status.dart';
import '../../delivery_notes_list/providers/delivery_notes_providers.dart';

class SendDeliveryNoteWhatsAppSheet extends ConsumerStatefulWidget {
  final DeliveryNoteModel note;

  const SendDeliveryNoteWhatsAppSheet({super.key, required this.note});

  /// Static helper to show the bottom sheet.
  static Future<void> show(BuildContext context, DeliveryNoteModel note) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SendDeliveryNoteWhatsAppSheet(note: note),
    );
  }

  @override
  ConsumerState<SendDeliveryNoteWhatsAppSheet> createState() =>
      _SendDeliveryNoteWhatsAppSheetState();
}

class _SendDeliveryNoteWhatsAppSheetState
    extends ConsumerState<SendDeliveryNoteWhatsAppSheet> {
  late TextEditingController _phoneController;
  late TextEditingController _messageController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill phone number from contact or client
    final initialPhone =
        PhoneUtils.normalizeForWhatsApp(widget.note.contactPhone) ??
        PhoneUtils.normalizeForWhatsApp(widget.note.clientPhone) ??
        '';
    _phoneController = TextEditingController(text: initialPhone);

    // Initial default message for WhatsApp (Decoupled from Email templates)
    _messageController = TextEditingController(text: '');
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    final phone = _phoneController.text.trim();

    if (phone.isEmpty) {
      CustomDialog.show(
        context: context,
        dialog: CustomDialog.confirmation(
          title: 'Campo requerido',
          contentText:
              'Por favor, ingresa el número de teléfono del destinatario',
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final userProfile = ref.read(userProfileProvider).value;

      if (userProfile == null) {
        throw Exception('No se pudo cargar el perfil del usuario');
      }

      // 1. Generate Action Token for WebViewer
      final token = await ref
          .read(deliveryNotesRepositoryProvider)
          .generateActionToken(widget.note.id);

      final userName =
          '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}'.trim();
      final isCompany =
          userProfile.companyName != null &&
          userProfile.companyName!.trim().isNotEmpty;

      // Header: Nombre de empresa si aplica, o nombre de usuario
      final headerUser = isCompany
          ? userProfile.companyName!.trim()
          : (userName.isEmpty ? 'D-UNA' : userName);

      // Contacto / Cliente
      final recipientName =
          widget.note.contactName ?? widget.note.clientName;

      // Nota personalizada (nunca vacía para cumplir validación de Meta)
      final userNote = _messageController.text.trim();
      final defaultMessage =
          'Le adjuntamos el enlace para revisar y confirmar la Nota de Entrega ${widget.note.deliveryNoteNumber}.';
      final finalMessage = userNote.isEmpty ? defaultMessage : userNote;

      final cleanPhone = PhoneUtils.normalizeForWhatsApp(phone) ??
          phone.replaceAll(RegExp(r'[^\d]'), '');

      // 2. Send via Cloud API Repository
      await ref.read(whatsappRepositoryProvider).sendMessage(
        phone: cleanPhone,
        templateName: 'd_una_envio_nota_entrega',
        headerVariables: [
          {
            'name': 'usuario',
            'text': _sanitizeHeaderParam(headerUser),
          },
        ],
        bodyVariables: [
          {
            'name': 'cliente',
            'text': _sanitizeParam(recipientName),
          },
          {
            'name': 'numero_nota',
            'text': _sanitizeParam(widget.note.deliveryNoteNumber),
          },
          {
            'name': 'mensaje',
            'text': _sanitizeParam(finalMessage),
          },
        ],
        buttonUrlParam: 'delivery_note.html?token=$token',
      );

      // 3. Consumir 1 crédito tras el envío exitoso
      await ref.read(creditsRepositoryProvider).consumeCredit(
        documentType: 'delivery_note',
        channel: 'whatsapp',
        referenceId: widget.note.id,
        documentNumber: widget.note.deliveryNoteNumber,
      );

      // 4. Actualizar estado a 'sent' o 'resent'
      final currentStatus = widget.note.status;
      final newStatus = (currentStatus == DeliveryNoteStatus.sent ||
              currentStatus == DeliveryNoteStatus.resent ||
              currentStatus == DeliveryNoteStatus.opened)
          ? DeliveryNoteStatus.resent
          : DeliveryNoteStatus.sent;

      await ref
          .read(deliveryNotesRepositoryProvider)
          .updateDeliveryNoteStatus(widget.note.id, newStatus);

      // 5. Invalidar caché de detalle y lista
      ref.invalidate(deliveryNoteDetailProvider(widget.note.id));
      ref.read(paginatedDeliveryNotesProvider.notifier).refresh();

      // 6. Obtener saldo fresco de créditos y refrescar la caché en Riverpod
      final freshCreditStatus =
          await ref.read(creditsRepositoryProvider).getCreditStatus();
      ref.invalidate(userCreditsStatusProvider);
      ref.invalidate(creditTransactionsHistoryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Nota de entrega enviada exitosamente por WhatsApp (créditos restantes: ${freshCreditStatus.remainingCredits})',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        CustomDialog.show(
          context: context,
          dialog: CustomDialog.confirmation(
            title: 'Error al enviar',
            contentText: 'No se pudo enviar por WhatsApp: $e',
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final creditsAsync = ref.watch(userCreditsStatusProvider);
    final remainingCredits = creditsAsync.valueOrNull?.remainingCredits ?? 0;
    final isZeroCredits = remainingCredits <= 0;

    final phone = widget.note.contactPhone ??
        widget.note.clientPhone ??
        'Sin teléfono';
    final recipientName =
        widget.note.contactName ?? widget.note.clientName;

    return CustomActionSheet(
      title: 'Enviar por WhatsApp',
      isContentScrollable: true,
      showDivider: false,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          creditsAsync.when(
            data: (status) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: CreditBannerCard(
                remainingCredits: status.remainingCredits,
                cost: 1,
              ),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          InfoBlock.text(
            icon: Icons.person_outline,
            label: 'Destinatario',
            value: '$recipientName ($phone)',
          ),
          if (_phoneController.text.isEmpty) ...[
            const SizedBox(height: 16),
            CustomTextField(
              controller: _phoneController,
              label: 'Teléfono de WhatsApp',
              hintText: '+58 412 1234567',
              keyboardType: TextInputType.phone,
            ),
          ],
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Nota personalizada',
            controller: _messageController,
            maxLines: 8,
            minLines: 4,
            maxLength: 120,
            helperText:
                'Este texto se insertará como una "Nota" en el mensaje de WhatsApp que se le enviará a tu cliente.',
          ),
          const SizedBox(height: 8),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              CustomButton(
                text: isZeroCredits ? 'Sin créditos' : 'Enviar',
                isFullWidth: false,
                isLoading: _isSending,
                onPressed: (!isZeroCredits && !_isSending) ? _handleSend : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Sanitizes a string to comply with Meta WhatsApp Cloud API restrictions for template parameters.
  /// Removes newlines, tabs, and collapses multiple spaces into one.
  String _sanitizeParam(String text) {
    return text
        .replaceAll(RegExp(r'[\n\t\r]'), ' ') // Remove newlines and tabs
        .replaceAll(RegExp(r' {2,}'), ' ') // Collapse 2+ spaces into 1
        .trim();
  }

  /// Sanitizes and truncates a header parameter to ensure the overall header
  /// stays within Meta's 60-character limit.
  String _sanitizeHeaderParam(String text, {int maxLength = 30}) {
    final clean = _sanitizeParam(text);
    if (clean.length > maxLength) {
      return '${clean.substring(0, maxLength - 3)}...';
    }
    return clean;
  }
}
