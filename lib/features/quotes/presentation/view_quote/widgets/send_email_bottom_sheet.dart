import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../settings/presentation/providers/email_templates_provider.dart';
import '../../../../../core/utils/email_content_generator.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../../../data/models/quote.dart';
import 'package:d_una_app/core/pdf/templates/quote_pdf_template.dart';
import 'package:pdf/pdf.dart';

class SendEmailBottomSheet extends ConsumerStatefulWidget {
  final Quote quote;

  const SendEmailBottomSheet({
    super.key,
    required this.quote,
  });

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
  ConsumerState<SendEmailBottomSheet> createState() => _SendEmailBottomSheetState();
}

class _SendEmailBottomSheetState extends ConsumerState<SendEmailBottomSheet> {
  late TextEditingController _recipientsController;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _recipientsController = TextEditingController(text: widget.quote.clientEmail ?? '');
    _subjectController = TextEditingController();
    _bodyController = TextEditingController();

    // Cargar plantilla y generar contenido inicial
    _loadInitialContent();
  }

  Future<void> _loadInitialContent() async {
    final templates = await ref.read(emailTemplatesListProvider.future);
    final template = templates.where((t) => t.documentType == 'quote').firstOrNull;
    
    final userProfile = ref.read(userProfileProvider).value;
    final userName = '${userProfile?.firstName ?? ''} ${userProfile?.lastName ?? ''}'.trim();
    final companyName = userProfile?.companyName;

    final subject = EmailContentGenerator.generateSubject(
      template: template?.subjectTemplate ?? EmailContentGenerator.getDefaultSubject('quote'),
      documentNumber: widget.quote.quoteNumber ?? 'S/N',
      category: widget.quote.categoryName,
      tag: widget.quote.quoteTag,
    );

    final body = EmailContentGenerator.generateBody(
      template: template?.bodyTemplate ?? EmailContentGenerator.getDefaultBody('quote'),
      clientName: widget.quote.clientName ?? 'Cliente',
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

  @override
  void dispose() {
    _recipientsController.dispose();
    _subjectController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendEmail() async {
    if (_recipientsController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingresa al menos un destinatario')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final userProfile = ref.read(userProfileProvider).value;
      final userEmail = Supabase.instance.client.auth.currentUser?.email;

      if (userProfile == null) throw Exception('No se pudo cargar el perfil del usuario');

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
      final fileName = 'Cotizacion_${widget.quote.quoteNumber ?? widget.quote.id}.pdf';

      // 2. Llamar a Edge Function
      final response = await Supabase.instance.client.functions.invoke(
        'send_document_email',
        body: {
          'documentBase64': base64Pdf,
          'fileName': fileName,
          'recipientEmails': _recipientsController.text.split(',').map((e) => e.trim()).toList(),
          'userContext': {
            'name': '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}'.trim(),
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Correo enviado exitosamente')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Enviar Cotización', style: textTheme.titleLarge),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Destinatarios (separados por coma)',
              controller: _recipientsController,
              hintText: 'ejemplo@correo.com, otro@correo.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Asunto',
              controller: _subjectController,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Mensaje',
              controller: _bodyController,
              maxLines: 5,
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Enviar Correo',
              isLoading: _isSending,
              onPressed: _sendEmail,
              icon: Icons.send,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
