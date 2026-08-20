import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../pdf_theme.dart';
import '../pdf_helpers.dart';
import '../pdf_common_sections.dart';
import '../../../features/reports/data/models/models.dart';
import '../../../features/profile/domain/models/user_profile.dart';

class ServiceReportPdfTemplate {
  final ServiceReport report;
  final List<ServiceReportItemProduct> products;
  final List<ServiceReportItemService> services;
  final List<ServiceReportCondition> conditions;
  final UserProfile userProfile;
  final String? userEmail;

  ServiceReportPdfTemplate({
    required this.report,
    required this.products,
    required this.services,
    required this.conditions,
    required this.userProfile,
    this.userEmail,
  });

  Future<Uint8List> generate(PdfPageFormat format) async {
    final pdf = pw.Document(theme: PdfThemeConfig.buildTheme());
    final senderInfo = PdfHelpers.resolvePdfSenderInfo(userProfile, userEmail);
    final logoImage = await PdfHelpers.loadNetworkImage(senderInfo.logoUrl);
    final footerImage = await PdfHelpers.loadAssetImage(
      'assets/images/creado_con_d_una.png',
    );

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(PdfThemeConfig.horizontalMargin),
        header: (context) => PdfCommonSections.buildLetterhead(
          title: 'REPORTE DE SERVICIO',
          documentNumber: report.reportNumber ?? 'RS-PENDIENTE',
          date: report.serviceDate,
          dateLabel: 'Fecha del Servicio',
          senderInfo: senderInfo,
          logoImage: logoImage,
        ),
        footer: (context) =>
            PdfCommonSections.buildFooter(context, footerImage: footerImage),
        build: (context) => [
          // Client Info Grid
          _buildClientInfoGrid(),
          pw.SizedBox(height: 16),

          // Technical Details Box
          _buildTechnicalInterventionBox(),
          pw.SizedBox(height: 16),

          // Services Table
          if (services.isNotEmpty) ...[
            _buildServicesTable(),
            pw.SizedBox(height: 16),
          ],

          // Products Table
          if (products.isNotEmpty) ...[
            _buildProductsTable(),
            pw.SizedBox(height: 16),
          ],

          // Financial Summary
          _buildFinancialTotals(),
          pw.SizedBox(height: 16),

          // Recommendations
          if (report.recommendations != null &&
              report.recommendations!.isNotEmpty) ...[
            _buildRecommendationsBox(),
            pw.SizedBox(height: 16),
          ],

          // Conditions
          if (conditions.isNotEmpty) ...[
            _buildConditionsSection(),
            pw.SizedBox(height: 24),
          ],

          // Signatures Box
          _buildSignaturesBox(),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildClientInfoGrid() {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Datos del Cliente',
                style: PdfThemeConfig.headerStyle.copyWith(
                  fontStyle: pw.FontStyle.italic,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              pw.SizedBox(height: 4),
              _infoRow('Cliente:', report.clientName ?? '-'),
              _infoRow('RIF / Cédula:', report.clientTaxId ?? '-'),
              if (report.contactName != null)
                _infoRow('Contacto:', report.contactName!),
              _infoRow(
                'Teléfono:',
                report.contactPhone ?? report.clientPhone ?? '-',
              ),
              _infoRow(
                'Email:',
                report.contactEmail ?? report.clientEmail ?? '-',
              ),
              _infoRow('Dirección:', report.clientAddress ?? '-'),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 80,
            child: pw.Text(
              label,
              style: PdfThemeConfig.bodyStyle.copyWith(
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value, style: PdfThemeConfig.bodyStyle),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTechnicalInterventionBox() {
    final typeEnum = InterventionType.fromDbValue(report.interventionType);

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      padding: const pw.EdgeInsets.all(10),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'TIPO: ${typeEnum.label.toUpperCase()}',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 10,
                  color: PdfColors.blue800,
                ),
              ),
              if (report.categoryName != null)
                pw.Text(
                  'CATEGORÍA: ${report.categoryName!.toUpperCase()}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              if (report.advisorName != null)
                pw.Text(
                  'TÉCNICO: ${report.advisorName!.toUpperCase()}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
            ],
          ),
          pw.Divider(color: PdfColors.grey300, height: 12),
          if (report.requestDescription != null &&
              report.requestDescription!.isNotEmpty) ...[
            pw.Text(
              'Solicitud del Cliente:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
            pw.Text(
              report.requestDescription!,
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 6),
          ],
          if (report.workDescription != null &&
              report.workDescription!.isNotEmpty) ...[
            pw.Text(
              'Diagnóstico y Trabajo Realizado:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            ),
            pw.Text(
              report.workDescription!,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildServicesTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'MANO DE OBRA Y SERVICIOS REALIZADOS',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          headers: ['Descripción', 'Cant.', 'Precio Unit.', 'Total'],
          data: services.map((s) {
            return [
              s.name,
              '${s.quantity} ${s.rateSymbol}',
              '\$${s.unitPrice.toStringAsFixed(2)}',
              '\$${s.totalPrice.toStringAsFixed(2)}',
            ];
          }).toList(),
          headerStyle:
              pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
        ),
      ],
    );
  }

  pw.Widget _buildProductsTable() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'REPUESTOS Y MATERIALES UTILIZADOS',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
        ),
        pw.SizedBox(height: 4),
        pw.TableHelper.fromTextArray(
          headers: ['Producto/Repuesto', 'Cant.', 'Precio Unit.', 'Total'],
          data: products.map((p) {
            return [
              '${p.name} ${p.brand != null ? "(${p.brand})" : ""}',
              '${p.quantity} ${p.uom}',
              '\$${p.unitPrice.toStringAsFixed(2)}',
              '\$${p.totalPrice.toStringAsFixed(2)}',
            ];
          }).toList(),
          headerStyle:
              pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          cellStyle: const pw.TextStyle(fontSize: 8),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignments: {
            0: pw.Alignment.centerLeft,
            1: pw.Alignment.center,
            2: pw.Alignment.centerRight,
            3: pw.Alignment.centerRight,
          },
        ),
      ],
    );
  }

  pw.Widget _buildFinancialTotals() {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 220,
        child: pw.Column(
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('\$${report.subtotal.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
            pw.SizedBox(height: 3),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('IVA:', style: const pw.TextStyle(fontSize: 9)),
                pw.Text('\$${report.taxAmount.toStringAsFixed(2)}',
                    style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
            pw.Divider(color: PdfColors.grey400, height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL:',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.Text('\$${report.total.toStringAsFixed(2)}',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 11,
                        color: PdfColors.blue900)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildRecommendationsBox() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'RECOMENDACIONES TÉCNICAS AL CLIENTE',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            report.recommendations!,
            style: const pw.TextStyle(fontSize: 8.5),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildConditionsSection() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'TÉRMINOS Y CONDICIONES DE GARANTÍA',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
        ),
        pw.SizedBox(height: 4),
        ...conditions.map(
          (c) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('• ', style: const pw.TextStyle(fontSize: 8)),
                pw.Expanded(
                  child: pw.Text(
                    c.description,
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildSignaturesBox() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          children: [
            pw.Container(
              width: 180,
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey600)),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Firma del Técnico Especialista',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
        pw.Column(
          children: [
            pw.Container(
              width: 180,
              decoration: const pw.BoxDecoration(
                border: pw.Border(top: pw.BorderSide(color: PdfColors.grey600)),
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Firma Conforme del Cliente',
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      ],
    );
  }
}
