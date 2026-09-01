import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../pdf_theme.dart';
import '../pdf_helpers.dart';
import '../pdf_common_sections.dart';
import '../../../features/quotes/data/models/quote.dart';
import '../../../features/quotes/data/models/quote_item_product.dart';
import '../../../features/quotes/data/models/quote_item_service.dart';
import '../../../features/quotes/data/models/quote_condition.dart';
import '../../../features/profile/domain/models/user_profile.dart';

class QuotePdfTemplate {
  final Quote quote;
  final List<QuoteItemProduct> products;
  final List<QuoteItemService> services;
  final List<QuoteCondition> conditions;
  final UserProfile userProfile;
  final String? userEmail;

  QuotePdfTemplate({
    required this.quote,
    required this.products,
    required this.services,
    required this.conditions,
    required this.userProfile,
    this.userEmail,
  });

  Future<Uint8List> generate(PdfPageFormat format) async {
    try {
      // 0. Validación de Seguridad
      if (quote.id.isEmpty) {
        return _buildErrorDocument('Datos de cotización incompletos.');
      }

      final pdf = pw.Document(theme: PdfThemeConfig.buildTheme());

      // Resolver info del emisor
      final senderInfo = PdfHelpers.resolvePdfSenderInfo(userProfile, userEmail);

      // Cargar logo si existe (con timeout de seguridad)
      final logoImage = await PdfHelpers.loadNetworkImage(senderInfo.logoUrl);

      // Cargar imagen de marca para el footer
      final footerImage = await PdfHelpers.loadAssetImage(
        'assets/images/creado_con_d_una.png',
      );

      // Calcular fecha de vigencia para el badge
      String? validityBadgeText;
      if (quote.validityDays > 0) {
        final expiryDate = quote.dateIssued.add(Duration(days: quote.validityDays));
        validityBadgeText = 'Vigente hasta: ${PdfHelpers.formatDate(expiryDate)}';
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: format,
          margin: const pw.EdgeInsets.symmetric(
            horizontal: PdfThemeConfig.horizontalMargin,
            vertical: PdfThemeConfig.verticalMargin,
          ),
          header: (context) => PdfCommonSections.buildLetterhead(
            title: 'COTIZACIÓN',
            documentNumber: quote.quoteNumber ?? '-',
            date: quote.dateIssued,
            senderInfo: senderInfo,
            logoImage: logoImage,
            badgeText: validityBadgeText,
          ),
          footer: (context) =>
              PdfCommonSections.buildFooter(context, footerLogoImage: footerImage),
          build: (context) => [
            _buildInfoGrid(),
            pw.SizedBox(height: 14),
            _buildItemsTable(),
            pw.SizedBox(height: 12),
            _buildTotalsBlock(),
            if (conditions.isNotEmpty || (quote.notes != null && quote.notes!.trim().isNotEmpty)) ...[
              pw.SizedBox(height: 14),
              _buildConditionsBlock(),
            ],
          ],
        ),
      );

      return await pdf.save();
    } catch (e, stack) {
      debugPrint('Error generating Quote PDF: $e\n$stack');
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

  /// Grilla de 2 columnas: Datos del Cliente y Asesor Comercial
  pw.Widget _buildInfoGrid() {
    final rawTaxId = (quote.clientTaxId ?? '').trim();
    final isCompany = quote.clientType == 'company' ||
        (rawTaxId.isNotEmpty && rawTaxId.toUpperCase().startsWith('J'));
    final clientNameLabel = isCompany ? 'Razón Social:' : 'Nombre:';
    final clientTaxLabel = isCompany ? 'RIF:' : 'Cédula:';

    final contactName = (quote.contactName != null && quote.contactName!.trim() != '-' && quote.contactName!.trim().isNotEmpty)
        ? quote.contactName!
        : null;
    final showAttention = isCompany && contactName != null;

    final phone = (quote.clientPhone != null && quote.clientPhone!.trim().isNotEmpty && quote.clientPhone!.trim() != '-')
        ? quote.clientPhone!.trim()
        : ((quote.contactPhone != null && quote.contactPhone!.trim().isNotEmpty && quote.contactPhone!.trim() != '-')
            ? quote.contactPhone!.trim()
            : null);

    final email = (quote.clientEmail != null && quote.clientEmail!.trim().isNotEmpty && quote.clientEmail!.trim() != '-')
        ? quote.clientEmail!.trim()
        : ((quote.contactEmail != null && quote.contactEmail!.trim().isNotEmpty && quote.contactEmail!.trim() != '-')
            ? quote.contactEmail!.trim()
            : null);

    final addressParts = <String>[
      if (quote.clientAddress != null && quote.clientAddress!.trim().isNotEmpty && quote.clientAddress!.trim() != '-')
        quote.clientAddress!.trim(),
      if (quote.clientCity != null && quote.clientCity!.trim().isNotEmpty && quote.clientCity!.trim() != '-')
        quote.clientCity!.trim(),
      if (quote.clientState != null && quote.clientState!.trim().isNotEmpty && quote.clientState!.trim() != '-')
        quote.clientState!.trim(),
    ];
    final fullClientAddress = addressParts.isNotEmpty ? addressParts.join(', ') : null;

    final advisorName = quote.advisorName ??
        '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}'.trim();

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
                quote.clientName ?? 'Cliente Particular',
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
        // Tarjeta 2: Asesor Comercial
        pw.Expanded(
          child: PdfCommonSections.buildInfoCard(
            title: 'ASESOR COMERCIAL',
            children: [
              PdfCommonSections.buildInfoRow(
                'Nombre:',
                advisorName.isNotEmpty ? advisorName : 'Asesor Comercial',
              ),
              if (userProfile.phone != null && userProfile.phone != '-')
                PdfCommonSections.buildInfoRow('Teléfono:', userProfile.phone!),
              if (userEmail != null && userEmail != '-')
                PdfCommonSections.buildInfoRow('Email:', userEmail!),
            ],
          ),
        ),
      ],
    );
  }

  /// Tabla única unificada para productos y servicios
  pw.Widget _buildItemsTable() {
    // 1. Agrupar productos por groupIndex
    final groupedProducts = <int, List<QuoteItemProduct>>{};
    for (var product in products) {
      groupedProducts.putIfAbsent(product.groupIndex, () => []).add(product);
    }
    final sortedGroupIndices = groupedProducts.keys.toList()..sort();

    // 2. Preparar lista de filas
    final rows = <pw.TableRow>[
      // Cabecera de la tabla
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

    // Filas de Productos
    for (var index in sortedGroupIndices) {
      final items = groupedProducts[index]!;
      final firstItem = items.first;

      double totalQuantity = 0;
      double subtotal = 0;
      for (var item in items) {
        totalQuantity += item.quantity;
        subtotal += item.totalPrice;
      }

      final isEven = rowIndex % 2 == 1;
      rowIndex++;

      // Subtítulo con marca/modelo o descripción
      String? subtitle;
      final modelParts = [
        if (firstItem.brand != null && firstItem.brand != 'Sin marca' && firstItem.brand!.isNotEmpty)
          firstItem.brand,
        if (firstItem.model != null && firstItem.model != 'NO APLICA' && firstItem.model!.isNotEmpty)
          firstItem.model,
      ];
      if (modelParts.isNotEmpty) {
        subtitle = modelParts.join(' - ');
      } else if (firstItem.description != null && firstItem.description!.isNotEmpty) {
        subtitle = firstItem.description;
      }

      final warrantyStr = _formatWarranty(firstItem.warrantyTime, firstItem.warrantyUnit);
      final qtyStr = totalQuantity % 1 == 0
          ? '${totalQuantity.toInt()} Ud'
          : '${totalQuantity.toStringAsFixed(2)} Ud';

      rows.add(
        _buildItemTableRow(
          name: firstItem.name,
          subtitle: subtitle,
          warranty: warrantyStr,
          quantity: qtyStr,
          unitPrice: PdfHelpers.formatCurrency(firstItem.unitPrice),
          totalPrice: PdfHelpers.formatCurrency(subtotal),
          isEven: isEven,
        ),
      );
    }

    // Filas de Servicios
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
        // Producto / Servicio + Subtítulo
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
        // Garantía
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
        // Cantidad
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
        // Precio Unitario
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
        // Total
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

  /// Tarjeta de Totales alineada a la derecha
  pw.Widget _buildTotalsBlock() {
    final subtotal = quote.subtotal;
    final tax = quote.taxAmount;
    final total = quote.total;
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

  /// Tarjeta de Condiciones Comerciales
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
              'TÉRMINOS Y CONDICIONES COMERCIALES',
              style: PdfThemeConfig.cardHeaderStyle,
            ),
          ),
          ...conditions.map(
            (c) => PdfCommonSections.buildBulletPoint(
              c.description,
              PdfThemeConfig.slate700,
            ),
          ),
          if (quote.notes != null && quote.notes!.trim().isNotEmpty) ...[
            pw.SizedBox(height: 6),
            pw.RichText(
              text: pw.TextSpan(
                children: [
                  pw.TextSpan(
                    text: 'Notas adicionales: ',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfThemeConfig.slate900,
                    ),
                  ),
                  pw.TextSpan(
                    text: quote.notes!.trim(),
                    style: const pw.TextStyle(
                      fontSize: 7.5,
                      color: PdfThemeConfig.slate700,
                    ),
                  ),
                ],
              ),
            ),
          ],
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
