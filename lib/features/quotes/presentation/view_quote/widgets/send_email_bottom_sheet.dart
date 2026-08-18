import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../shared/widgets/credit_banner_card.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../../../settings/presentation/providers/email_templates_provider.dart';
import '../../../../../core/utils/email_content_generator.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import 'package:d_una_app/features/quotes/presentation/quotes_list/providers/quotes_provider.dart';
import '../../../data/models/quote.dart';
import 'package:d_una_app/core/pdf/templates/quote_pdf_template.dart';
import 'package:d_una_app/core/providers/credits_providers.dart';
import 'package:d_una_app/features/quotes/domain/models/quote_model.dart'
    show QuoteStatus;
import '../providers/view_quote_provider.dart';
import 'package:pdf/pdf.dart';

class EmailValidationResult {
  final List<String> recipients;
  final String? errorMessage;
  final bool isValid;

  const EmailValidationResult({
    required this.recipients,
    this.errorMessage,
    required this.isValid,
  });
}

class SendEmailBottomSheet extends ConsumerStatefulWidget {
  final Quote quote;

  const SendEmailBottomSheet({super.key, required this.quote});

  static Future<void> show(BuildContext context, Quote quote) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SendEmailBottomSheet(quote: quote),
    );
  }

  @override
  ConsumerState<SendEmailBottomSheet> createState() =>
      _SendEmailBottomSheetState();
}

class _SendEmailBottomSheetState extends ConsumerState<SendEmailBottomSheet> {
  late TextEditingController _recipientsController;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final initialRecipient =
        widget.quote.contactEmail ?? widget.quote.clientEmail ?? '';
    _recipientsController = TextEditingController(text: initialRecipient);
    _recipientsController.addListener(_onRecipientsChanged);
    _subjectController = TextEditingController();
    _bodyController = TextEditingController();

    // Cargar plantilla y generar contenido inicial
    _loadInitialContent();
  }

  void _onRecipientsChanged() {
    setState(() {});
  }

  EmailValidationResult get _validation {
    final text = _recipientsController.text.trim();
    if (text.isEmpty) {
      return const EmailValidationResult(
        recipients: [],
        errorMessage: null,
        isValid: false,
      );
    }

    final rawTokens = text
        .split(RegExp(r'[,;]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (rawTokens.isEmpty) {
      return const EmailValidationResult(
        recipients: [],
        errorMessage: null,
        isValid: false,
      );
    }

    // 1. Check syntax / format of every email
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    for (final token in rawTokens) {
      if (!emailRegex.hasMatch(token)) {
        return EmailValidationResult(
          recipients: [],
          errorMessage: 'El correo "$token" no es válido',
          isValid: false,
        );
      }
    }

    // 2. Check duplicate emails
    final lowerTokens = rawTokens.map((e) => e.toLowerCase()).toList();
    final duplicates = lowerTokens
        .where((e) => lowerTokens.indexOf(e) != lowerTokens.lastIndexOf(e))
        .toSet();
    if (duplicates.isNotEmpty) {
      return EmailValidationResult(
        recipients: [],
        errorMessage: 'Correo repetido: ${duplicates.join(", ")}',
        isValid: false,
      );
    }

    // 3. Check maximum 3 recipients
    if (lowerTokens.length > 3) {
      return EmailValidationResult(
        recipients: [],
        errorMessage:
            'Máximo 3 destinatarios permitidos (ingresados: ${lowerTokens.length})',
        isValid: false,
      );
    }

    return EmailValidationResult(
      recipients: lowerTokens,
      errorMessage: null,
      isValid: true,
    );
  }

  Future<void> _loadInitialContent() async {
    final templates = await ref.read(emailTemplatesListProvider.future);
    final template = templates
        .where((t) => t.documentType == 'quote')
        .firstOrNull;

    final userProfile = ref.read(userProfileProvider).value;
    final userName =
        '${userProfile?.firstName ?? ''} ${userProfile?.lastName ?? ''}'.trim();
    final companyName = userProfile?.companyName;

    final subject = EmailContentGenerator.generateSubject(
      template:
          template?.subjectTemplate ??
          EmailContentGenerator.getDefaultSubject('quote'),
      documentNumber: widget.quote.quoteNumber ?? 'S/N',
      category: widget.quote.categoryName,
      tag: widget.quote.quoteTag,
    );

    final clientDisplayName =
        widget.quote.contactName ?? widget.quote.clientName ?? 'Cliente';

    final body = EmailContentGenerator.generateBody(
      template:
          template?.bodyTemplate ??
          EmailContentGenerator.getDefaultBody('quote'),
      clientName: clientDisplayName,
      userName: userName.isEmpty ? 'Usuario' : userName,
      companyName: companyName,
      collaboratorName: widget.quote.advisorName,
    );

    if (mounted) {
      setState(() {
        _subjectController.text = subject;
        _bodyController.text = body;
      });
    }
  }

  @override
  void dispose() {
    _recipientsController.removeListener(_onRecipientsChanged);
    _recipientsController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    final validation = _validation;
    if (!validation.isValid) return;

    final recipients = validation.recipients;

    // Check available credits vs required credits
    final creditsAsync = ref.read(userCreditsStatusProvider);
    final remainingCredits = creditsAsync.valueOrNull?.remainingCredits ?? 0;
    final requiredCredits = recipients.length;

    if (remainingCredits < requiredCredits) {
      CustomDialog.show(
        context: context,
        dialog: CustomDialog.confirmation(
          title: 'Créditos insuficientes',
          contentText:
              'No dispones de suficientes créditos ($remainingCredits disponibles) para enviar a $requiredCredits destinatario${requiredCredits > 1 ? 's' : ''}.',
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

      // 1. Generar PDF
      final pdfBytes = await QuotePdfTemplate(
        quote: widget.quote,
        products: widget.quote.products ?? [],
        services: widget.quote.services ?? [],
        conditions: widget.quote.conditions ?? [],
        userProfile: userProfile,
        userEmail: userEmail,
      ).generate(PdfPageFormat.a4);

      final fileName = '${widget.quote.quoteNumber ?? widget.quote.id}.pdf';

      // 2. Subir PDF a Supabase Storage & Generar Action Token
      final quotesRepo = ref.read(quotesRepositoryProvider);
      await quotesRepo.uploadQuotePdf(
        quoteId: widget.quote.id,
        pdfBytes: pdfBytes,
        fileName: fileName,
      );

      final actionToken = await quotesRepo.generateActionToken(widget.quote.id);

      // 3. Llamar a Edge Function send_document_email
      final response = await Supabase.instance.client.functions.invoke(
        'send_document_email',
        body: {
          'fileName': fileName,
          'documentType': 'quote',
          'documentId': widget.quote.id,
          'documentNumber': widget.quote.quoteNumber,
          'actionToken': actionToken,
          'validityDays': widget.quote.validityDays,
          'recipientEmails': recipients,
          'userContext': {
            'name':
                '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}'
                    .trim(),
            'companyName': userProfile.companyName,
            'phone': userProfile.phone,
            'replyToEmail': userEmail,
            'companyLogo': userProfile.companyLogoUrl,
          },
          'emailContent': {
            'subject': _subjectController.text.trim(),
            'bodyHtml': _bodyController.text.trim(),
          },
        },
      );

      if (response.status != 200) {
        throw Exception('Error del servidor: ${response.data}');
      }

      // 4. Actualizar el estado de la cotización en BD ('sent' / 'resent')
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
              'Correo enviado exitosamente (créditos restantes: ${freshCreditStatus.remainingCredits})',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error al enviar';

        final errorStr = e.toString();
        if (errorStr.contains('MAX_RECIPIENTS_EXCEEDED')) {
          errorMessage = 'Máximo 3 destinatarios permitidos por envío';
        } else if (errorStr.contains('INSUFFICIENT_CREDITS') ||
            errorStr.contains('DAILY_LIMIT_EXCEEDED')) {
          errorMessage = 'Has alcanzado el límite de créditos de tu ciclo';
        } else if (errorStr.contains('COOLDOWN_ACTIVE')) {
          errorMessage =
              'Debes esperar unos segundos antes de volver a enviar este documento';
        } else {
          errorMessage = 'Error al enviar: $e';
        }

        CustomDialog.show(
          context: context,
          dialog: CustomDialog.confirmation(
            title: 'Error al enviar',
            contentText: errorMessage,
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
    final validation = _validation;
    final cost = validation.isValid ? validation.recipients.length : 1;
    final isSendEnabled =
        validation.isValid &&
        !isZeroCredits &&
        (remainingCredits >= validation.recipients.length) &&
        !_isSending;

    return CustomActionSheet(
      title: 'Enviar cotización por correo',
      isContentScrollable: true,
      showDivider: false,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          creditsAsync.when(
            data: (status) => CreditBannerCard(
              remainingCredits: status.remainingCredits,
              cost: cost,
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Destinatarios (máximo 3, separados por coma)',
            controller: _recipientsController,
            hintText: 'ejemplo@correo.com, otro@correo.com',
            keyboardType: TextInputType.emailAddress,
            errorText: validation.errorMessage,
          ),
          const SizedBox(height: 24),
          CustomTextField(label: 'Asunto', controller: _subjectController),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Mensaje',
            controller: _bodyController,
            maxLines: 8,
            minLines: 4,
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
                onPressed: isSendEnabled ? _sendEmail : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
