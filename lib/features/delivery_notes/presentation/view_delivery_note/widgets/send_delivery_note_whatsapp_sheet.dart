import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/shared/widgets/credit_banner_card.dart';
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
    final initialPhone =
        PhoneUtils.normalizeForWhatsApp(widget.note.contactPhone) ??
        PhoneUtils.normalizeForWhatsApp(widget.note.clientPhone) ??
        '';
    _phoneController = TextEditingController(text: initialPhone);
    _messageController = TextEditingController(
      text:
          'Estimado cliente, le adjuntamos el enlace para revisar y confirmar la Nota de Entrega ${widget.note.deliveryNoteNumber}.',
    );
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingrese un número telefónico')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final userProfile = ref.read(userProfileProvider).value;
      if (userProfile == null) throw Exception('No se pudo cargar el perfil de usuario');

      // 1. Obtener o generar token de acción online
      final token = await ref
          .read(deliveryNotesRepositoryProvider)
          .generateActionToken(widget.note.id);

      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

      // 2. Enviar WhatsApp mediante WhatsApp Repository
      final userName = '${userProfile.firstName ?? ""} ${userProfile.lastName ?? ""}'.trim();
      await ref.read(whatsappRepositoryProvider).sendMessage(
        phone: cleanPhone,
        templateName: 'd_una_envio_nota_entrega',
        headerVariables: [
          {'name': 'usuario', 'text': userName},
        ],
        bodyVariables: [
          {'name': 'cliente', 'text': widget.note.clientName},
          {'name': 'numero_nota', 'text': widget.note.deliveryNoteNumber},
          {'name': 'mensaje', 'text': _messageController.text.trim()},
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

      // 4. Actualizar estado a 'sent' si estaba en borrador
      if (widget.note.status == DeliveryNoteStatus.draft) {
        await ref
            .read(deliveryNotesRepositoryProvider)
            .updateDeliveryNoteStatus(widget.note.id, DeliveryNoteStatus.sent);
      }

      // Invalidate providers
      ref.invalidate(deliveryNoteDetailProvider(widget.note.id));
      ref.read(paginatedDeliveryNotesProvider.notifier).refresh();
      ref.invalidate(userCreditsStatusProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Nota de entrega enviada por WhatsApp exitosamente')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar WhatsApp: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    final creditsAsync = ref.watch(userCreditsStatusProvider);
    final remainingCredits = creditsAsync.valueOrNull?.remainingCredits ?? 0;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: bottomInset + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Enviar por WhatsApp',
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
          CreditBannerCard(
            remainingCredits: remainingCredits,
            cost: 1,
          ),
          const SizedBox(height: 16),
          CustomTextField(
            controller: _phoneController,
            label: 'Número de WhatsApp (con código de país)',
            hintText: '+58 412 1234567',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _messageController,
            label: 'Mensaje personalizado',
            maxLines: 3,
          ),
          const SizedBox(height: 20),
          CustomButton(
            text: _isSending ? 'Enviando...' : 'Enviar mensaje',
            icon: Icons.send,
            isLoading: _isSending,
            onPressed: _isSending ? null : _handleSend,
          ),
        ],
      ),
    );
  }
}
