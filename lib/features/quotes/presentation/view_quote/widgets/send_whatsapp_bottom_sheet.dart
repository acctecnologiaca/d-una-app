import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../../../../../core/utils/phone_utils.dart';
import '../../../../../core/services/whatsapp_repository.dart';
import '../../../../../shared/widgets/info_block.dart';
import '../../../data/models/quote.dart';
import 'package:d_una_app/core/pdf/templates/quote_pdf_template.dart';

class SendWhatsAppBottomSheet extends ConsumerStatefulWidget {
  final Quote quote;

  const SendWhatsAppBottomSheet({super.key, required this.quote});

  /// Static helper to show the bottom sheet.
  static Future<void> show(BuildContext context, Quote quote) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SendWhatsAppBottomSheet(quote: quote),
    );
  }

  @override
  ConsumerState<SendWhatsAppBottomSheet> createState() =>
      _SendWhatsAppBottomSheetState();
}

class _SendWhatsAppBottomSheetState
    extends ConsumerState<SendWhatsAppBottomSheet> {
  late TextEditingController _phoneController;
  late TextEditingController _messageController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();

    // Pre-fill phone number from contact or client
    final initialPhone =
        PhoneUtils.normalizeForWhatsApp(widget.quote.contactPhone) ??
        PhoneUtils.normalizeForWhatsApp(widget.quote.clientPhone) ??
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

  Future<void> _sendViaWhatsApp() async {
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
      final userEmail = Supabase.instance.client.auth.currentUser?.email;

      if (userProfile == null) {
        throw Exception('No se pudo cargar el perfil del usuario');
      }

      // 1. Generate PDF Bytes
      final pdfBytes = await QuotePdfTemplate(
        quote: widget.quote,
        products: widget.quote.products ?? [],
        services: widget.quote.services ?? [],
        conditions: widget.quote.conditions ?? [],
        userProfile: userProfile,
        userEmail: userEmail,
      ).generate(PdfPageFormat.a4);

      final fileName =
          'Cotizacion_${widget.quote.quoteNumber ?? widget.quote.id}.pdf';

      final userName =
          '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}'.trim();
      final userDisplayName =
          (userProfile.companyName != null &&
              userProfile.companyName!.isNotEmpty)
          ? userProfile.companyName!
          : (userName.isEmpty ? 'Usuario' : userName);

      // Construct the final note with a fixed disclaimer
      final userNote = _messageController.text.trim();
      const disclaimer =
          'El documento adjunto estará disponible para su descarga durante un periodo limitado de *12 horas*';
      final finalNote = userNote.isEmpty
          ? disclaimer
          : '$userNote. $disclaimer';

      // 2. Send via Cloud API Repository
      // Template: enviar_documento_pdf
      // Variables:
      // 1. Client/Contact name
      // 2. Document type (Cotización)
      // 3. User/Company name
      // 4. User phone
      // 5. Custom note
      await ref
          .read(whatsappRepositoryProvider)
          .sendDocument(
            phone: phone,
            pdfBytes: pdfBytes,
            fileName: fileName,
            templateName: 'enviar_documento_pdf',
            bodyVariables: [
              _sanitizeParam(
                widget.quote.contactName ??
                    widget.quote.clientName ??
                    'Cliente',
              ),
              'cotización',
              _sanitizeParam(userDisplayName),
              _sanitizeParam(userProfile.phone ?? ''),
              _sanitizeParam(finalNote),
            ],
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cotización enviada exitosamente')),
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
    return CustomActionSheet(
      title: 'Enviar por WhatsApp',
      isContentScrollable: true,
      showDivider: false,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          InfoBlock.text(
            icon: Icons.person_outline,
            label: 'Destinatario',
            value:
                '${widget.quote.contactName ?? widget.quote.clientName ?? 'Cliente'} (${widget.quote.contactPhone ?? widget.quote.clientPhone ?? 'Sin teléfono'})',
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Nota personalizada',
            controller: _messageController,
            maxLines: 8,
            minLines: 4,
            maxLength: 120,
            helperText:
                'Este texto se insertará en el mensaje de WhatsApp que se le enviará a tu cliente.',
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
                text: 'Enviar',
                isFullWidth: false,
                isLoading: _isSending,
                onPressed: _sendViaWhatsApp,
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
}
