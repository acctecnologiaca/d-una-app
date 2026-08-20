import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import '../../../../../shared/widgets/credit_banner_card.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../../../settings/presentation/providers/email_templates_provider.dart';
import '../../../../../core/utils/email_content_generator.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../../reports_list/providers/reports_provider.dart';
import '../../../data/models/service_report.dart';
import '../../../../../core/pdf/templates/service_report_pdf_template.dart';
import '../../../../../core/providers/credits_providers.dart';
import '../../../domain/models/service_report_model.dart'
    show ServiceReportStatus;
import '../providers/view_report_provider.dart';

class ReportEmailValidationResult {
  final List<String> recipients;
  final String? errorMessage;
  final bool isValid;

  const ReportEmailValidationResult({
    required this.recipients,
    this.errorMessage,
    required this.isValid,
  });
}

class SendReportEmailSheet extends ConsumerStatefulWidget {
  final ServiceReport report;

  const SendReportEmailSheet({super.key, required this.report});

  static Future<void> show(BuildContext context, ServiceReport report) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SendReportEmailSheet(report: report),
    );
  }

  @override
  ConsumerState<SendReportEmailSheet> createState() =>
      _SendReportEmailSheetState();
}

class _SendReportEmailSheetState extends ConsumerState<SendReportEmailSheet> {
  late TextEditingController _recipientsController;
  late TextEditingController _subjectController;
  late TextEditingController _bodyController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final initialRecipient =
        widget.report.contactEmail ?? widget.report.clientEmail ?? '';
    _recipientsController = TextEditingController(text: initialRecipient);
    _recipientsController.addListener(_onRecipientsChanged);
    _subjectController = TextEditingController();
    _bodyController = TextEditingController();

    _loadInitialContent();
  }

  void _onRecipientsChanged() {
    setState(() {});
  }

  ReportEmailValidationResult get _validation {
    final text = _recipientsController.text.trim();
    if (text.isEmpty) {
      return const ReportEmailValidationResult(
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
      return const ReportEmailValidationResult(
        recipients: [],
        errorMessage: null,
        isValid: false,
      );
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    for (final token in rawTokens) {
      if (!emailRegex.hasMatch(token)) {
        return ReportEmailValidationResult(
          recipients: [],
          errorMessage: 'Correo inválido: $token',
          isValid: false,
        );
      }
    }

    final lowerTokens = rawTokens.map((e) => e.toLowerCase()).toList();
    final duplicates = lowerTokens
        .where((e) => lowerTokens.indexOf(e) != lowerTokens.lastIndexOf(e))
        .toSet();
    if (duplicates.isNotEmpty) {
      return ReportEmailValidationResult(
        recipients: [],
        errorMessage: 'Correo repetido: ${duplicates.join(", ")}',
        isValid: false,
      );
    }

    if (lowerTokens.length > 3) {
      return ReportEmailValidationResult(
        recipients: [],
        errorMessage:
            'Máximo 3 destinatarios permitidos (ingresados: ${lowerTokens.length})',
        isValid: false,
      );
    }

    return ReportEmailValidationResult(
      recipients: lowerTokens,
      errorMessage: null,
      isValid: true,
    );
  }

  Future<void> _loadInitialContent() async {
    final templates = await ref.read(emailTemplatesListProvider.future);
    final template = templates
        .where((t) =>
            t.documentType == 'report' || t.documentType == 'service_report')
        .firstOrNull;

    final userProfile = ref.read(userProfileProvider).value;
    final userName =
        '${userProfile?.firstName ?? ''} ${userProfile?.lastName ?? ''}'.trim();
    final companyName = userProfile?.companyName;

    final subject = EmailContentGenerator.generateSubject(
      template:
          template?.subjectTemplate ??
          EmailContentGenerator.getDefaultSubject('report'),
      documentNumber: widget.report.reportNumber ?? 'S/N',
      category: widget.report.categoryName,
      tag: widget.report.reportTag,
      documentType: 'Reporte de Servicio',
    );

    final clientDisplayName =
        widget.report.contactName ?? widget.report.clientName ?? 'Cliente';

    final body = EmailContentGenerator.generateBody(
      template:
          template?.bodyTemplate ??
          EmailContentGenerator.getDefaultBody('report'),
      clientName: clientDisplayName,
      userName: userName.isEmpty ? 'Usuario' : userName,
      companyName: companyName,
      collaboratorName: widget.report.advisorName,
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
      final pdfBytes = await ServiceReportPdfTemplate(
        report: widget.report,
        products: widget.report.products ?? [],
        services: widget.report.services ?? [],
        conditions: widget.report.conditions ?? [],
        userProfile: userProfile,
        userEmail: userEmail,
      ).generate(PdfPageFormat.a4);

      final fileName = '${widget.report.reportNumber ?? widget.report.id}.pdf';

      // 2. Subir PDF a Supabase Storage & Generar Action Token
      final reportsRepo = ref.read(serviceReportsRepositoryProvider);
      await reportsRepo.uploadReportPdf(
        reportId: widget.report.id,
        pdfBytes: pdfBytes,
        fileName: fileName,
      );

      final actionToken =
          await reportsRepo.generateActionToken(widget.report.id);

      // 3. Llamar a Edge Function send_document_email
      final response = await Supabase.instance.client.functions.invoke(
        'send_document_email',
        body: {
          'fileName': fileName,
          'documentType': 'report',
          'documentId': widget.report.id,
          'documentNumber': widget.report.reportNumber,
          'actionToken': actionToken,
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

      // 4. Actualizar el estado del reporte en BD ('sent' / 'resent')
      final currentStatus = widget.report.status;
      final newStatus = (currentStatus == ServiceReportStatus.sent.dbValue ||
              currentStatus == ServiceReportStatus.resent.dbValue)
          ? ServiceReportStatus.resent.dbValue
          : ServiceReportStatus.sent.dbValue;

      await ref
          .read(reportsListProvider.notifier)
          .updateReportStatus(widget.report.id, newStatus);

      ref.invalidate(viewReportProvider(widget.report.id));
      refreshAllReportProviders(ref);

      final freshCreditStatus =
          await ref.read(creditsRepositoryProvider).getCreditStatus();
      ref.invalidate(userCreditsStatusProvider);
      ref.invalidate(creditTransactionsHistoryProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reporte enviado exitosamente (créditos restantes: ${freshCreditStatus.remainingCredits})',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al enviar el reporte: $e'),
            backgroundColor: Colors.red,
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
    final isSendEnabled = validation.isValid &&
        !isZeroCredits &&
        (remainingCredits >= validation.recipients.length) &&
        !_isSending;

    return CustomActionSheet(
      title: 'Enviar reporte por correo',
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
