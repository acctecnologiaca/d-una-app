import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import 'package:pdf/pdf.dart';

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
    _subjectController = TextEditingController();
    _bodyController = TextEditingController();

    // Cargar plantilla y generar contenido inicial
    _loadInitialContent();
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
    _recipientsController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (_recipientsController.text.isEmpty) {
      CustomDialog.show(
        context: context,
        dialog: CustomDialog.confirmation(
          title: 'Campo requerido',
          contentText: 'Por favor, ingresa al menos un destinatario',
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

    // Validate max 3 recipients
    final recipients = _recipientsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (recipients.length > 3) {
      CustomDialog.show(
        context: context,
        dialog: CustomDialog.confirmation(
          title: 'Límite excedido',
          contentText: 'Máximo 3 destinatarios por envío',
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

      final fileName =
          '${widget.quote.quoteNumber ?? widget.quote.id}.pdf';

      // 2. Subir PDF a Supabase Storage & Generar Action Token
      final quotesRepo = ref.read(quotesRepositoryProvider);
      await quotesRepo.uploadQuotePdf(
        quoteId: widget.quote.id,
        pdfBytes: pdfBytes,
        fileName: fileName,
      );

      final actionToken = await quotesRepo.generateActionToken(widget.quote.id);
      final webViewerUrl = 'https://d-una.app/quote.html?token=$actionToken';

      // Append WebViewer interactive button to email body HTML
      final rawBodyHtml = _bodyController.text.trim();
      final webViewerButtonHtml = '''
<br><br>
<div style="text-align: center; margin: 24px 0;">
  <a href="$webViewerUrl" style="background-color: #2563EB; color: #ffffff; padding: 14px 28px; text-decoration: none; border-radius: 8px; font-weight: bold; display: inline-block; font-size: 15px;">Ver y Aprobar Cotización Interactivamente</a>
  <p style="font-size: 12px; color: #64748B; margin-top: 10px;">Esta cotización es válida durante ${widget.quote.validityDays} días desde su emisión.</p>
</div>
''';
      final finalBodyHtml = '$rawBodyHtml$webViewerButtonHtml';

      // 3. Llamar a Edge Function send_document_email (sin adjuntar PDF en el correo)
      final response = await Supabase.instance.client.functions.invoke(
        'send_document_email',
        body: {
          'fileName': fileName,
          'documentType': 'quote',
          'documentId': widget.quote.id,
          'actionToken': actionToken,
          'recipientEmails': _recipientsController.text
              .split(',')
              .map((e) => e.trim())
              .toList(),
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
            'bodyHtml': finalBodyHtml,
          },
        },
      );

      if (response.status != 200) {
        throw Exception('Error del servidor: ${response.data}');
      }

      // Read updated credits from response
      final responseData = response.data as Map<String, dynamic>?;
      final updatedRemaining = responseData?['remainingCredits'] as int?;

      if (mounted) {
        final creditInfo = updatedRemaining != null
            ? ' (créditos restantes: $updatedRemaining)'
            : '';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Correo enviado exitosamente$creditInfo')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error al enviar';

        final errorStr = e.toString();
        if (errorStr.contains('MAX_RECIPIENTS_EXCEEDED')) {
          errorMessage = 'Máximo 3 destinatarios por envío';
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

  Widget _buildCreditsIndicatorWidget(int remaining) {
    final Color indicatorColor;
    final IconData indicatorIcon;
    final colors = Theme.of(context).colorScheme;

    if (remaining > 5) {
      indicatorColor = colors.secondary;
      indicatorIcon = Icons.check_circle_outline;
    } else if (remaining > 0) {
      indicatorColor = Colors.orange;
      indicatorIcon = Icons.warning_amber_rounded;
    } else {
      indicatorColor = colors.error;
      indicatorIcon = Icons.error_outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Icon(Icons.star_border_outlined, size: 20, color: colors.secondary),
          const SizedBox(width: 4),
          Text(
            remaining > 0
                ? 'Créditos disponibles: $remaining'
                : 'Créditos agotados (0 disponibles)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: indicatorColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Icon(indicatorIcon, size: 16, color: indicatorColor),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final creditsAsync = ref.watch(userCreditsStatusProvider);
    final remainingCredits = creditsAsync.valueOrNull?.remainingCredits ?? 0;
    final isZeroCredits = remainingCredits <= 0;

    return CustomActionSheet(
      title: 'Enviar cotización por correo',
      isContentScrollable: true,
      showDivider: false,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          creditsAsync.when(
            data: (status) =>
                _buildCreditsIndicatorWidget(status.remainingCredits),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 24),
          CustomTextField(
            label: 'Destinatarios (separados por coma)',
            controller: _recipientsController,
            hintText: 'ejemplo@correo.com, otro@correo.com',
            keyboardType: TextInputType.emailAddress,
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
                onPressed: (!isZeroCredits && !_isSending) ? _sendEmail : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
