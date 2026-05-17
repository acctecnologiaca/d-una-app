import 'dart:convert';
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
import '../../../data/models/quote.dart';
import 'package:d_una_app/core/pdf/templates/quote_pdf_template.dart';
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
  int? _remainingCredits;
  int? _totalCredits;
  bool _isLoadingCredits = true;

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

    // Cargar créditos disponibles
    _loadCredits();
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
    );

    if (mounted) {
      setState(() {
        _subjectController.text = subject;
        _bodyController.text = body;
      });
    }
  }

  Future<void> _loadCredits() async {
    try {
      final response = await Supabase.instance.client.functions.invoke(
        'get_email_credits',
      );

      if (response.status == 200 && response.data != null) {
        if (mounted) {
          setState(() {
            _remainingCredits = response.data['remainingCredits'] as int?;
            _totalCredits = response.data['totalCredits'] as int?;
            _isLoadingCredits = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoadingCredits = false);
      }
    } catch (e) {
      // Degradación elegante: si falla, no bloquear el envío
      debugPrint('Error loading credits: $e');
      if (mounted) setState(() => _isLoadingCredits = false);
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

      final base64Pdf = base64Encode(pdfBytes);
      final fileName =
          'Cotizacion_${widget.quote.quoteNumber ?? widget.quote.id}.pdf';

      // 2. Llamar a Edge Function
      final response = await Supabase.instance.client.functions.invoke(
        'send_document_email',
        body: {
          'documentBase64': base64Pdf,
          'fileName': fileName,
          'documentType': 'quote',
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
            'bodyHtml': _bodyController.text.trim(),
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
        } else if (errorStr.contains('DAILY_LIMIT_EXCEEDED')) {
          errorMessage = 'Has alcanzado el límite de envíos diarios';
        } else if (errorStr.contains('COOLDOWN_ACTIVE')) {
          errorMessage = 'Debes esperar antes de enviar otro correo';
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

  Widget _buildCreditsIndicator() {
    if (_isLoadingCredits) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Consultando créditos...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
      );
    }

    if (_remainingCredits == null || _totalCredits == null) {
      return const SizedBox.shrink();
    }

    final remaining = _remainingCredits!;
    final total = _totalCredits!;

    // Color logic: green if > 50%, orange if 20-50%, red if < 20%
    final Color indicatorColor;
    final IconData indicatorIcon;
    if (remaining > total * 0.5) {
      indicatorColor = Colors.green;
      indicatorIcon = Icons.check_circle_outline;
    } else if (remaining > total * 0.2) {
      indicatorColor = Colors.orange;
      indicatorIcon = Icons.warning_amber_rounded;
    } else {
      indicatorColor = Theme.of(context).colorScheme.error;
      indicatorIcon = Icons.error_outline;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Text(
            'Disponibles para hoy: $remaining de $total créditos',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: indicatorColor,
              fontWeight: FontWeight.w900,
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
    return CustomActionSheet(
      title: 'Enviar cotización por correo',
      isContentScrollable: true,
      showDivider: false,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          //const SizedBox(height: 12),
          // Email credits indicator
          _buildCreditsIndicator(),
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
                text: 'Enviar',
                isFullWidth: false,
                isLoading: _isSending,
                onPressed: _sendEmail,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
