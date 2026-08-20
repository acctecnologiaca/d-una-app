import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../profile/presentation/providers/profile_provider.dart';
import '../../../../../core/utils/phone_utils.dart';
import '../../../../../core/services/whatsapp_repository.dart';
import '../../../../../core/providers/credits_providers.dart';
import '../../reports_list/providers/reports_provider.dart';
import '../../../../../shared/widgets/credit_banner_card.dart';
import '../../../../../shared/widgets/info_block.dart';
import '../../../data/models/service_report.dart';
import '../../../domain/models/service_report_model.dart'
    show ServiceReportStatus;
import '../providers/view_report_provider.dart';
import '../../../../../core/pdf/templates/service_report_pdf_template.dart';

class SendReportWhatsAppSheet extends ConsumerStatefulWidget {
  final ServiceReport report;

  const SendReportWhatsAppSheet({super.key, required this.report});

  static Future<void> show(BuildContext context, ServiceReport report) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SendReportWhatsAppSheet(report: report),
    );
  }

  @override
  ConsumerState<SendReportWhatsAppSheet> createState() =>
      _SendReportWhatsAppSheetState();
}

class _SendReportWhatsAppSheetState
    extends ConsumerState<SendReportWhatsAppSheet> {
  late TextEditingController _phoneController;
  late TextEditingController _messageController;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    final initialPhone =
        PhoneUtils.normalizeForWhatsApp(widget.report.contactPhone) ??
            PhoneUtils.normalizeForWhatsApp(widget.report.clientPhone) ??
            '';
    _phoneController = TextEditingController(text: initialPhone);
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

      // 2. Subir PDF & Generar Action Token
      final reportsRepo = ref.read(serviceReportsRepositoryProvider);
      await reportsRepo.uploadReportPdf(
        reportId: widget.report.id,
        pdfBytes: pdfBytes,
        fileName: fileName,
      );

      final actionToken =
          await reportsRepo.generateActionToken(widget.report.id);

      final userName =
          '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}'.trim();
      final isCompany = userProfile.companyName != null &&
          userProfile.companyName!.trim().isNotEmpty;

      final headerUser = isCompany
          ? userProfile.companyName!.trim()
          : (userName.isEmpty ? 'D-UNA' : userName);

      final contactName = widget.report.contactName ??
          widget.report.clientName ??
          'Cliente';

      final categoryName = widget.report.categoryName ?? 'Servicio Técnico';

      final bodyUser = (isCompany &&
              widget.report.advisorName != null &&
              widget.report.advisorName!.trim().isNotEmpty)
          ? widget.report.advisorName!.trim()
          : (userName.isEmpty ? headerUser : userName);

      final userPhone = userProfile.phone ?? '';

      final userNote = _messageController.text.trim();
      final defaultNote =
          'Adjunto el reporte de servicio ${widget.report.reportNumber ?? ""}.';
      final finalNote = userNote.isEmpty ? defaultNote : userNote;

      final cleanPhone = phone.replaceAll(RegExp(r'[^\d]'), '');

      // 3. Enviar mensaje via WhatsApp Cloud API
      await ref.read(whatsappRepositoryProvider).sendMessage(
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
                'name': 'numero_documento',
                'text': _sanitizeParam(widget.report.reportNumber ?? 'RS-PENDIENTE'),
              },
              {
                'name': 'asesor',
                'text': _sanitizeParam(bodyUser),
              },
              {
                'name': 'telefono_contacto',
                'text': _sanitizeParam(userPhone.isNotEmpty ? userPhone : 'nuestro equipo'),
              },
              {
                'name': 'nota_validez',
                'text': _sanitizeParam(finalNote),
              },
            ],
            buttonUrlParam: 'report.html?token=$actionToken',
          );

      // 4. Consumir crédito
      await ref.read(creditsRepositoryProvider).consumeCredit(
            documentType: 'report',
            channel: 'whatsapp',
            referenceId: widget.report.id,
            documentNumber: widget.report.reportNumber,
          );

      // 5. Actualizar estado del reporte
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
              'Reporte enviado por WhatsApp exitosamente (créditos restantes: ${freshCreditStatus.remainingCredits})',
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

  String _sanitizeParam(String text) {
    return text
        .replaceAll(RegExp(r'[\n\t\r]'), ' ')
        .replaceAll(RegExp(r' {2,}'), ' ')
        .trim();
  }

  String _sanitizeHeaderParam(String text, {int maxLength = 30}) {
    final clean = _sanitizeParam(text);
    if (clean.length > maxLength) {
      return '${clean.substring(0, maxLength - 3)}...';
    }
    return clean;
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
                '${widget.report.contactName ?? widget.report.clientName ?? 'Cliente'} (${widget.report.contactPhone ?? widget.report.clientPhone ?? 'Sin teléfono'})',
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
}
