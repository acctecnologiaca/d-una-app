import 'package:flutter/foundation.dart';
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
    try {
      // 0. Validación de Seguridad
      if (report.id.isEmpty) {
        return _buildErrorDocument('Datos del reporte de servicio incompletos.');
      }

      final pdf = pw.Document(theme: PdfThemeConfig.buildTheme());

      // Resolver emisor
      final senderInfo = PdfHelpers.resolvePdfSenderInfo(userProfile, userEmail);

      // Cargar logo si existe (con timeout de seguridad)
      final logoImage = await PdfHelpers.loadNetworkImage(senderInfo.logoUrl);

      // Cargar imagen de marca para el footer
      final footerImage = await PdfHelpers.loadAssetImage(
        'assets/images/creado_con_d_una.png',
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: format,
          margin: const pw.EdgeInsets.symmetric(
            horizontal: PdfThemeConfig.horizontalMargin,
            vertical: PdfThemeConfig.verticalMargin,
          ),
          header: (context) => PdfCommonSections.buildLetterhead(
            title: 'REPORTE DE SERVICIO',
            documentNumber: report.reportNumber ?? '-',
            date: report.serviceDate,
            senderInfo: senderInfo,
            logoImage: logoImage,
          ),
          footer: (context) =>
              PdfCommonSections.buildFooter(context, footerLogoImage: footerImage),
          build: (context) => [
            // 1. Grilla de Información (Cliente + Detalles del Servicio)
            _buildInfoGrid(),
            pw.SizedBox(height: 14),

            // 2. Informe Técnico Estructurado
            if (_hasTechnicalReportContent()) ...[
              _buildTechnicalReportCard(),
              pw.SizedBox(height: 14),
            ],

            // 3. Tabla Unificada de Ítems (Productos primero, luego Servicios)
            if (products.isNotEmpty || services.isNotEmpty) ...[
              _buildItemsTable(),
              pw.SizedBox(height: 12),
            ],

            // 4. Totales Financieros
            _buildTotalsBlock(),

            // 5. Términos de Garantía
            if (conditions.isNotEmpty) ...[
              pw.SizedBox(height: 14),
              _buildConditionsBlock(),
            ],
          ],
        ),
      );

      return await pdf.save();
    } catch (e, stack) {
      debugPrint('Error generating ServiceReport PDF: $e\n$stack');
      return _buildErrorDocument('Error al generar PDF: $e');
    }
  }

  Future<Uint8List> _buildErrorDocument(String message) async {
    final errorPdf = pw.Document(theme: PdfThemeConfig.buildTheme());
    errorPdf.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'No se pudo generar el documento PDF',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfThemeConfig.slate900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  message,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfThemeConfig.slate500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return errorPdf.save();
  }

  bool _hasTechnicalReportContent() {
    return (report.requestDescription != null && report.requestDescription!.trim().isNotEmpty) ||
        (report.workDescription != null && report.workDescription!.trim().isNotEmpty) ||
        (report.recommendations != null && report.recommendations!.trim().isNotEmpty);
  }

  /// Grilla de 2 columnas: Datos del Cliente y Detalles del Servicio
  pw.Widget _buildInfoGrid() {
    final rawTaxId = (report.clientTaxId ?? '').trim();
    final isCompany = (rawTaxId.isNotEmpty && rawTaxId.toUpperCase().startsWith('J'));
    final clientNameLabel = isCompany ? 'Razón Social:' : 'Nombre:';
    final clientTaxLabel = isCompany ? 'RIF:' : 'Cédula:';

    final contactName = (report.contactName != null && report.contactName!.trim() != '-' && report.contactName!.trim().isNotEmpty)
        ? report.contactName!
        : null;
    final showAttention = isCompany && contactName != null;

    // Teléfono y Correo con fallback a datos de contacto
    final phone = (report.clientPhone != null && report.clientPhone!.trim().isNotEmpty && report.clientPhone!.trim() != '-')
        ? report.clientPhone!.trim()
        : ((report.contactPhone != null && report.contactPhone!.trim().isNotEmpty && report.contactPhone!.trim() != '-')
            ? report.contactPhone!.trim()
            : null);

    final email = (report.clientEmail != null && report.clientEmail!.trim().isNotEmpty && report.clientEmail!.trim() != '-')
        ? report.clientEmail!.trim()
        : ((report.contactEmail != null && report.contactEmail!.trim().isNotEmpty && report.contactEmail!.trim() != '-')
            ? report.contactEmail!.trim()
            : null);

    // Dirección completa incluyendo ciudad y estado
    final addressParts = <String>[
      if (report.clientAddress != null && report.clientAddress!.trim().isNotEmpty && report.clientAddress!.trim() != '-')
        report.clientAddress!.trim(),
      if (report.clientCity != null && report.clientCity!.trim().isNotEmpty && report.clientCity!.trim() != '-')
        report.clientCity!.trim(),
      if (report.clientState != null && report.clientState!.trim().isNotEmpty && report.clientState!.trim() != '-')
        report.clientState!.trim(),
    ];
    final fullClientAddress = addressParts.isNotEmpty ? addressParts.join(', ') : null;

    final typeEnum = InterventionType.fromDbValue(report.interventionType);
    final technicianName = report.advisorName ??
        '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}'.trim();

    // Horario / Duración
    String? timeStr;
    if (report.startTime != null && report.endTime != null) {
      timeStr = '${report.startTime} - ${report.endTime}';
    }
    if (report.durationMinutes != null && report.durationMinutes! > 0) {
      timeStr = (timeStr != null) ? '$timeStr (${report.durationMinutes} min)' : '${report.durationMinutes} min';
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Tarjeta 1: Datos del Cliente
        pw.Expanded(
          child: PdfCommonSections.buildInfoCard(
            title: 'DATOS DEL CLIENTE',
            children: [
              PdfCommonSections.buildInfoRow(
                clientNameLabel,
                report.clientName ?? 'Cliente Particular',
              ),
              if (rawTaxId.isNotEmpty && rawTaxId != '-')
                PdfCommonSections.buildInfoRow(clientTaxLabel, rawTaxId),
              if (showAttention)
                PdfCommonSections.buildInfoRow('Atención:', contactName),
              if (phone != null)
                PdfCommonSections.buildInfoRow('Teléfono:', phone),
              if (email != null)
                PdfCommonSections.buildInfoRow('Email:', email),
              if (fullClientAddress != null)
                PdfCommonSections.buildInfoRow('Dirección:', fullClientAddress),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        // Tarjeta 2: Detalles del Servicio
        pw.Expanded(
          child: PdfCommonSections.buildInfoCard(
            title: 'DETALLES DEL SERVICIO',
            children: [
              PdfCommonSections.buildInfoRow(
                'Tipo de servicio:',
                typeEnum.label,
              ),
              if (report.categoryName != null && report.categoryName!.isNotEmpty)
                PdfCommonSections.buildInfoRow('Categoría:', report.categoryName!),
              PdfCommonSections.buildInfoRow(
                'Técnico responsable:',
                technicianName.isNotEmpty ? technicianName : 'Especialista Técnico',
              ),
              if (timeStr != null)
                PdfCommonSections.buildInfoRow('Horario / Duración:', timeStr),
            ],
          ),
        ),
      ],
    );
  }

  /// Tarjeta estructurada de Informe Técnico
  pw.Widget _buildTechnicalReportCard() {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfThemeConfig.slate50,
        border: pw.Border.all(color: PdfThemeConfig.slate200, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.ClipRRect(
        horizontalRadius: 7,
        verticalRadius: 7,
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
          // Cabecera gris del informe
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: const pw.BoxDecoration(
              color: PdfThemeConfig.slate100,
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfThemeConfig.slate300, width: 1.5),
              ),
            ),
            child: pw.Text(
              'INFORME TÉCNICO',
              style: PdfThemeConfig.cardHeaderStyle,
            ),
          ),
          // Cajas blancas internas
          pw.Padding(
            padding: const pw.EdgeInsets.all(10),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (report.requestDescription != null && report.requestDescription!.trim().isNotEmpty) ...[
                  _buildWhiteTechnicalBox(
                    title: 'REQUERIMIENTO O FALLA REPORTADA',
                    content: report.requestDescription!.trim(),
                  ),
                ],
                if (report.workDescription != null && report.workDescription!.trim().isNotEmpty) ...[
                  if (report.requestDescription != null && report.requestDescription!.trim().isNotEmpty)
                    pw.SizedBox(height: 8),
                  _buildWhiteTechnicalBox(
                    title: 'DIAGNÓSTICO Y/O TRABAJO REALIZADO',
                    content: report.workDescription!.trim(),
                  ),
                ],
                if (report.recommendations != null && report.recommendations!.trim().isNotEmpty) ...[
                  if ((report.requestDescription != null && report.requestDescription!.trim().isNotEmpty) ||
                      (report.workDescription != null && report.workDescription!.trim().isNotEmpty))
                    pw.SizedBox(height: 8),
                  _buildWhiteTechnicalBox(
                    title: 'RECOMENDACIONES',
                    content: report.recommendations!.trim(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

  pw.Widget _buildWhiteTechnicalBox({
    required String title,
    required String content,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfThemeConfig.white,
        border: pw.Border.all(color: PdfThemeConfig.slate200, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.only(bottom: 3),
            margin: const pw.EdgeInsets.only(bottom: 4),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfThemeConfig.slate300, width: 1),
              ),
            ),
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 7,
                fontWeight: pw.FontWeight.bold,
                color: PdfThemeConfig.slate900,
                letterSpacing: 0.4,
              ),
            ),
          ),
          pw.Text(
            content,
            style: const pw.TextStyle(
              fontSize: 7.5,
              color: PdfThemeConfig.slate700,
              lineSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  /// Tabla Unificada de Ítems (Repuestos/Productos primero, Mano de obra después)
  pw.Widget _buildItemsTable() {
    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfThemeConfig.slate100,
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfThemeConfig.slate300, width: 1.5),
          ),
        ),
        children: [
          PdfCommonSections.buildTableHeaderCell(
            'PRODUCTO / SERVICIO',
            pw.Alignment.centerLeft,
          ),
          PdfCommonSections.buildTableHeaderCell(
            'GARANTÍA',
            pw.Alignment.center,
          ),
          PdfCommonSections.buildTableHeaderCell(
            'CANT.',
            pw.Alignment.centerRight,
          ),
          PdfCommonSections.buildTableHeaderCell(
            'P. UNIT',
            pw.Alignment.centerRight,
          ),
          PdfCommonSections.buildTableHeaderCell(
            'TOTAL',
            pw.Alignment.centerRight,
          ),
        ],
      ),
    ];

    int rowIndex = 0;

    // 1. Productos (Repuestos)
    for (var product in products) {
      final isEven = rowIndex % 2 == 1;
      rowIndex++;

      final subtitleParts = [
        if (product.brand != null && product.brand!.isNotEmpty) product.brand,
        if (product.model != null && product.model!.isNotEmpty) product.model,
      ];
      final subtitle = subtitleParts.isNotEmpty
          ? subtitleParts.join(' - ')
          : product.description;

      final warrantyStr = _formatWarranty(product.warrantyTime, product.warrantyUnit);
      final qtyStr = product.quantity % 1 == 0
          ? '${product.quantity.toInt()} ${product.uom}'
          : '${product.quantity.toStringAsFixed(2)} ${product.uom}';

      rows.add(
        _buildItemTableRow(
          name: product.name,
          subtitle: subtitle,
          warranty: warrantyStr,
          quantity: qtyStr,
          unitPrice: PdfHelpers.formatCurrency(product.unitPrice),
          totalPrice: PdfHelpers.formatCurrency(product.totalPrice),
          isEven: isEven,
        ),
      );
    }

    // 2. Servicios (Mano de Obra)
    for (var service in services) {
      final isEven = rowIndex % 2 == 1;
      rowIndex++;

      final warrantyStr = _formatWarranty(service.warrantyTime, service.warrantyUnit);
      final qtyStr = service.quantity % 1 == 0
          ? '${service.quantity.toInt()} ${service.rateSymbol}'
          : '${service.quantity.toStringAsFixed(2)} ${service.rateSymbol}';

      rows.add(
        _buildItemTableRow(
          name: service.name,
          subtitle: service.description,
          warranty: warrantyStr,
          quantity: qtyStr,
          unitPrice: PdfHelpers.formatCurrency(service.unitPrice),
          totalPrice: PdfHelpers.formatCurrency(service.totalPrice),
          isEven: isEven,
        ),
      );
    }

    return pw.Table(
      border: const pw.TableBorder(
        top: pw.BorderSide(color: PdfThemeConfig.slate200, width: 1),
        bottom: pw.BorderSide(color: PdfThemeConfig.slate200, width: 1),
        left: pw.BorderSide(color: PdfThemeConfig.slate200, width: 1),
        right: pw.BorderSide(color: PdfThemeConfig.slate200, width: 1),
        horizontalInside: pw.BorderSide(color: PdfThemeConfig.slate200, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FixedColumnWidth(60),
        2: pw.FixedColumnWidth(48),
        3: pw.FixedColumnWidth(65),
        4: pw.FixedColumnWidth(70),
      },
      children: rows,
    );
  }

  pw.TableRow _buildItemTableRow({
    required String name,
    String? subtitle,
    required String warranty,
    required String quantity,
    required String unitPrice,
    required String totalPrice,
    required bool isEven,
  }) {
    return pw.TableRow(
      decoration: pw.BoxDecoration(
        color: isEven ? PdfThemeConfig.slate50 : PdfThemeConfig.white,
        border: const pw.Border(
          bottom: pw.BorderSide(color: PdfThemeConfig.slate200, width: 0.5),
        ),
      ),
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                name,
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfThemeConfig.slate900,
                ),
              ),
              if (subtitle != null && subtitle.isNotEmpty) ...[
                pw.SizedBox(height: 1.5),
                pw.Text(
                  subtitle,
                  style: const pw.TextStyle(
                    fontSize: 6.5,
                    color: PdfThemeConfig.slate500,
                  ),
                ),
              ],
            ],
          ),
        ),
        pw.Container(
          alignment: pw.Alignment.center,
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: pw.Text(
            warranty,
            style: const pw.TextStyle(
              fontSize: 7,
              color: PdfThemeConfig.slate700,
            ),
          ),
        ),
        pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: pw.Text(
            quantity,
            style: const pw.TextStyle(
              fontSize: 7.5,
              color: PdfThemeConfig.slate700,
            ),
          ),
        ),
        pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: pw.Text(
            unitPrice,
            style: const pw.TextStyle(
              fontSize: 7.5,
              color: PdfThemeConfig.slate700,
            ),
          ),
        ),
        pw.Container(
          alignment: pw.Alignment.centerRight,
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(
            totalPrice,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfThemeConfig.slate900,
            ),
          ),
        ),
      ],
    );
  }

  /// Tarjeta de Totales
  pw.Widget _buildTotalsBlock() {
    final subtotal = report.subtotal;
    final tax = report.taxAmount;
    final total = report.total;
    final taxRatePct = subtotal > 0 ? ((tax / subtotal) * 100).round() : 16;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 190,
          decoration: pw.BoxDecoration(
            color: PdfThemeConfig.slate50,
            border: pw.Border.all(color: PdfThemeConfig.slate300, width: 1),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'SUB-TOTAL:',
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfThemeConfig.slate500,
                      ),
                    ),
                    pw.Text(
                      PdfHelpers.formatCurrency(subtotal),
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfThemeConfig.slate700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'IVA ($taxRatePct%):',
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfThemeConfig.slate500,
                      ),
                    ),
                    pw.Text(
                      PdfHelpers.formatCurrency(tax),
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfThemeConfig.slate700,
                      ),
                    ),
                  ],
                ),
              ),
              // Divisor oscuro del total
              pw.Container(
                width: double.infinity,
                height: 1.5,
                color: PdfThemeConfig.slate900,
              ),
              // Grand Total
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL USD:',
                      style: PdfThemeConfig.grandTotalStyle,
                    ),
                    pw.Text(
                      PdfHelpers.formatCurrency(total),
                      style: PdfThemeConfig.grandTotalStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Términos y Condiciones de Garantía
  pw.Widget _buildConditionsBlock() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfThemeConfig.slate50,
        border: pw.Border.all(color: PdfThemeConfig.slate200, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.only(bottom: 4),
            margin: const pw.EdgeInsets.only(bottom: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfThemeConfig.slate300, width: 1.5),
              ),
            ),
            child: pw.Text(
              'TÉRMINOS Y CONDICIONES DE GARANTÍA',
              style: PdfThemeConfig.cardHeaderStyle,
            ),
          ),
          ...conditions.map(
            (c) => PdfCommonSections.buildBulletPoint(
              c.description,
              PdfThemeConfig.slate700,
            ),
          ),
        ],
      ),
    );
  }

  String _formatWarranty(dynamic time, String? unit) {
    final numTime = num.tryParse(time.toString()) ?? 0;
    if (numTime <= 0) return '---';

    final normalizedUnit = (unit ?? '').toLowerCase().trim();
    String unitStr = 'Días';
    if (normalizedUnit.contains('day') || normalizedUnit.contains('dia')) {
      unitStr = numTime == 1 ? 'Día' : 'Días';
    } else if (normalizedUnit.contains('month') || normalizedUnit.contains('mes')) {
      unitStr = numTime == 1 ? 'Mes' : 'Meses';
    } else if (normalizedUnit.contains('year') || normalizedUnit.contains('a')) {
      unitStr = numTime == 1 ? 'Año' : 'Años';
    }

    return '$numTime $unitStr';
  }
}
