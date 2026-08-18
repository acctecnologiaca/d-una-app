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
import '../../../../../core/providers/credits_providers.dart';
import 'package:d_una_app/features/quotes/presentation/quotes_list/providers/quotes_provider.dart';
import '../../../../../shared/widgets/credit_banner_card.dart';
import '../../../../../shared/widgets/info_block.dart';
import '../../../data/models/quote.dart';
import 'package:d_una_app/features/quotes/domain/models/quote_model.dart'
    show QuoteStatus;
import '../providers/view_quote_provider.dart';
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

      final fileName = '${widget.quote.quoteNumber ?? widget.quote.id}.pdf';

      // 2. Upload PDF & Generate Action Token for WebViewer
      final quotesRepo = ref.read(quotesRepositoryProvider);
      await quotesRepo.uploadQuotePdf(
        quoteId: widget.quote.id,
        pdfBytes: pdfBytes,
        fileName: fileName,
      );

      final actionToken = await quotesRepo.generateActionToken(widget.quote.id);

      final userName =
          '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}'.trim();
      final isCompany =
          userProfile.companyName != null &&
          userProfile.companyName!.trim().isNotEmpty;

      // Header: Nombre de empresa si aplica, o nombre de usuario
      final headerUser = isCompany
          ? userProfile.companyName!.trim()
          : (userName.isEmpty ? 'D-UNA' : userName);

      // Contacto (cliente o contacto asignado)
      final contactName =
          widget.quote.contactName ?? widget.quote.clientName ?? 'Cliente';

      // Categoría
      final categoryName = widget.quote.categoryName ?? 'General';

      // Body usuario: Asesor comercial si es empresa, o nombre de usuario
      final bodyUser =
          (isCompany &&
              widget.quote.advisorName != null &&
              widget.quote.advisorName!.trim().isNotEmpty)
          ? widget.quote.advisorName!.trim()
          : (userName.isEmpty ? headerUser : userName);

      // Teléfono del usuario
      final userPhone = userProfile.phone ?? '';

      // Nota personalizada (nunca vacía para cumplir validación de Meta)
      final userNote = _messageController.text.trim();
      final defaultValidity =
          'Cotización válida por ${widget.quote.validityDays} días desde su emisión.';
      final finalNote = userNote.isEmpty
          ? defaultValidity
          : '$userNote (Válida por ${widget.quote.validityDays} días)';

      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

      // 3. Send via Cloud API Repository (sin adjuntar archivo PDF)
      await ref
          .read(whatsappRepositoryProvider)
          .sendMessage(
            phone: cleanPhone,
            templateName: 'd_una_envio_cotizacion_formal',
            headerVariables: [
              {
                'name': 'usuario',
                'text': _sanitizeHeaderParam(headerUser),
              },
            ],
            bodyVariables: [
              {
                'name': 'contacto',
                'text': _sanitizeParam(contactName),
              },
              {
                'name': 'categoria',
                'text': _sanitizeParam(categoryName),
              },
              {
                'name': 'usuario',
                'text': _sanitizeParam(bodyUser),
              },
              {
                'name': 'telefono',
                'text': _sanitizeParam(userPhone),
              },
              {
                'name': 'nota_personalizada',
                'text': _sanitizeParam(finalNote),
              },
            ],
            buttonUrlParam: 'quote.html?token=$actionToken',
          );

      // 4. Consumir crédito tras el envío exitoso
      await ref
          .read(creditsRepositoryProvider)
          .consumeCredit(
            documentType: 'quote',
            channel: 'whatsapp',
            referenceId: widget.quote.id,
            documentNumber: widget.quote.quoteNumber,
          );

      // 5. Actualizar el estado de la cotización en BD ('sent' / 'resent')
      final currentStatus = widget.quote.status;
      final newStatus =
          (currentStatus == QuoteStatus.sent.dbValue ||
              currentStatus == QuoteStatus.resent.dbValue)
          ? QuoteStatus.resent.dbValue
          : QuoteStatus.sent.dbValue;

      await ref
          .read(quotesListProvider.notifier)
          .updateQuoteStatus(widget.quote.id, newStatus);

      // Invalidate quote view provider so UI updates quote status badge
      ref.invalidate(viewQuoteProvider(widget.quote.id));

      // 6. Obtener saldo fresco de créditos y refrescar la caché en Riverpod
      final freshCreditStatus = await ref
          .read(creditsRepositoryProvider)
          .getCreditStatus();
      ref.invalidate(userCreditsStatusProvider);
      ref.invalidate(creditTransactionsHistoryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Cotización enviada exitosamente (créditos restantes: ${freshCreditStatus.remainingCredits})',
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
                onPressed: (!isZeroCredits && !_isSending)
                    ? _sendViaWhatsApp
                    : null,
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
  /// ("Ha recibido una cotización de {{usuario}}") stays within Meta's 60-character limit.
  String _sanitizeHeaderParam(String text, {int maxLength = 30}) {
    final clean = _sanitizeParam(text);
    if (clean.length > maxLength) {
      return '${clean.substring(0, maxLength - 3)}...';
    }
    return clean;
  }
}
