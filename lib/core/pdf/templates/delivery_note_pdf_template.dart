import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../pdf_theme.dart';
import '../pdf_helpers.dart';
import '../pdf_common_sections.dart';
import '../../../features/delivery_notes/domain/models/delivery_note_model.dart';
import '../../../features/profile/domain/models/user_profile.dart';

class DeliveryNotePdfTemplate {
  final DeliveryNoteModel note;
  final UserProfile userProfile;
  final String? userEmail;

  DeliveryNotePdfTemplate({
    required this.note,
    required this.userProfile,
    this.userEmail,
  });

  Future<Uint8List> generate(PdfPageFormat format) async {
    try {
      if (note.id.isEmpty) {
        return _buildErrorDocument('Datos de la nota de entrega incompletos.');
      }

      final pdf = pw.Document(theme: PdfThemeConfig.buildTheme());

      // Resolver info del emisor
      final senderInfo =
          PdfHelpers.resolvePdfSenderInfo(userProfile, userEmail);

      // Cargar logo si existe (con timeout de seguridad)
      final logoImage = await PdfHelpers.loadNetworkImage(senderInfo.logoUrl);

      // Cargar imagen de marca para el footer
      final footerImage = await PdfHelpers.loadAssetImage(
        'assets/images/creado_con_d_una.png',
      );

      // Cargar firma digital si existe en base64
      pw.MemoryImage? signatureImage;
      if (note.signatureData != null && note.signatureData!.isNotEmpty) {
        try {
          final cleanBase64 = note.signatureData!.contains(',')
              ? note.signatureData!.split(',').last
              : note.signatureData!;
          final bytes = base64Decode(cleanBase64);
          signatureImage = pw.MemoryImage(bytes);
        } catch (_) {}
      }

      pdf.addPage(
        pw.MultiPage(
          pageFormat: format,
          margin: const pw.EdgeInsets.symmetric(
            horizontal: PdfThemeConfig.horizontalMargin,
            vertical: PdfThemeConfig.verticalMargin,
          ),
          header: (context) => PdfCommonSections.buildLetterhead(
            title: 'NOTA DE ENTREGA',
            documentNumber: note.deliveryNoteNumber,
            date: note.date,
            senderInfo: senderInfo,
            logoImage: logoImage,
            badgeText: note.isDropshipping ? 'DROPSHIPPING' : null,
          ),
          footer: (context) => PdfCommonSections.buildFooter(
            context,
            footerLogoImage: footerImage,
          ),
          build: (context) => [
            _buildInfoGrid(),
            pw.SizedBox(height: 14),
            _buildItemsTable(),
            if (note.observations.isNotEmpty ||
                (note.notes != null && note.notes!.trim().isNotEmpty)) ...[
              pw.SizedBox(height: 14),
              _buildObservationsBlock(),
            ],
            pw.SizedBox(height: 16),
            _buildSignaturesBlock(signatureImage),
          ],
        ),
      );

      return await pdf.save();
    } catch (e, stack) {
      debugPrint('Error generating Delivery Note PDF: $e\n$stack');
      return _buildErrorDocument('Error al generar PDF de Nota de Entrega: $e');
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

  /// Grilla de 2 columnas: Datos del Cliente y Detalles del Despacho
  pw.Widget _buildInfoGrid() {
    final rawTaxId = (note.clientTaxId ?? '').trim();
    final isCompany = note.clientType == 'company' ||
        (rawTaxId.isNotEmpty && rawTaxId.toUpperCase().startsWith('J'));
    final clientNameLabel = isCompany ? 'Razón Social:' : 'Nombre:';
    final clientTaxLabel = isCompany ? 'RIF:' : 'Cédula:';

    final contactName = (note.contactName != null &&
            note.contactName!.trim() != '-' &&
            note.contactName!.trim().isNotEmpty)
        ? note.contactName!.trim()
        : null;
    final showAttention = isCompany && contactName != null;

    final phone = (note.clientPhone != null &&
            note.clientPhone!.trim().isNotEmpty &&
            note.clientPhone!.trim() != '-')
        ? note.clientPhone!.trim()
        : ((note.contactPhone != null &&
                note.contactPhone!.trim().isNotEmpty &&
                note.contactPhone!.trim() != '-')
            ? note.contactPhone!.trim()
            : null);

    final email = (note.clientEmail != null &&
            note.clientEmail!.trim().isNotEmpty &&
            note.clientEmail!.trim() != '-')
        ? note.clientEmail!.trim()
        : ((note.contactEmail != null &&
                note.contactEmail!.trim().isNotEmpty &&
                note.contactEmail!.trim() != '-')
            ? note.contactEmail!.trim()
            : null);

    // Dirección fiscal del cliente
    final clientAddressParts = <String>[
      if (note.clientAddress != null &&
          note.clientAddress!.trim().isNotEmpty &&
          note.clientAddress!.trim() != '-')
        note.clientAddress!.trim(),
      if (note.clientCity != null &&
          note.clientCity!.trim().isNotEmpty &&
          note.clientCity!.trim() != '-')
        note.clientCity!.trim(),
      if (note.clientState != null &&
          note.clientState!.trim().isNotEmpty &&
          note.clientState!.trim() != '-')
        note.clientState!.trim(),
    ];
    final fullClientAddress =
        clientAddressParts.isNotEmpty ? clientAddressParts.join(', ') : null;

    // Dirección de destino / despacho
    final deliveryAddressParts = <String>[
      if (note.recipientAddress != null &&
          note.recipientAddress!.trim().isNotEmpty &&
          note.recipientAddress!.trim() != '-')
        note.recipientAddress!.trim(),
      if (note.recipientCity != null &&
          note.recipientCity!.trim().isNotEmpty &&
          note.recipientCity!.trim() != '-')
        note.recipientCity!.trim(),
      if (note.recipientState != null &&
          note.recipientState!.trim().isNotEmpty &&
          note.recipientState!.trim() != '-')
        note.recipientState!.trim(),
    ];
    final fullDeliveryAddress = deliveryAddressParts.isNotEmpty
        ? deliveryAddressParts.join(', ')
        : null;

    final deliveryTypeLabel = note.deliveryType == 'store_pickup' ||
            note.deliveryType == 'pickup'
        ? 'Retiro en tienda / almacén'
        : (note.deliveryType == 'carrier' || note.deliveryType == 'courier'
            ? 'Envío por encomienda / transportista'
            : 'Despacho propio');

    final dispatchDate = note.deliveryDate ?? note.date;

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
                note.clientName.isNotEmpty
                    ? note.clientName
                    : 'Cliente Particular',
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
                PdfCommonSections.buildInfoRow(
                  'Dirección:',
                  fullClientAddress,
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        // Tarjeta 2: Detalles del Despacho
        pw.Expanded(
          child: PdfCommonSections.buildInfoCard(
            title: 'DETALLES DEL DESPACHO',
            children: [
              PdfCommonSections.buildInfoRow(
                'Modalidad:',
                deliveryTypeLabel,
              ),
              if (note.shippingCompanyName != null &&
                  note.shippingCompanyName!.trim().isNotEmpty &&
                  note.shippingCompanyName!.trim() != '-')
                PdfCommonSections.buildInfoRow(
                  'Transporte:',
                  note.shippingCompanyName!.trim(),
                ),
              if (note.trackingNumber != null &&
                  note.trackingNumber!.trim().isNotEmpty &&
                  note.trackingNumber!.trim() != '-')
                PdfCommonSections.buildInfoRow(
                  'Guía / Tracking:',
                  note.trackingNumber!.trim(),
                ),
              PdfCommonSections.buildInfoRow(
                'Fecha de Despacho:',
                PdfHelpers.formatDate(dispatchDate),
              ),
              if (note.clientPoNumber != null &&
                  note.clientPoNumber!.trim().isNotEmpty &&
                  note.clientPoNumber!.trim() != '-')
                PdfCommonSections.buildInfoRow(
                  'O/C Cliente:',
                  note.clientPoNumber!.trim(),
                ),
              if (fullDeliveryAddress != null)
                PdfCommonSections.buildInfoRow(
                  'Dirección de despacho:',
                  fullDeliveryAddress,
                ),
              if (note.deliveryInstructions != null &&
                  note.deliveryInstructions!.trim().isNotEmpty &&
                  note.deliveryInstructions!.trim() != '-')
                PdfCommonSections.buildInfoRow(
                  'Instrucciones:',
                  note.deliveryInstructions!.trim(),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Tabla homologada de productos (sin montos, solo cantidades y garantías)
  pw.Widget _buildItemsTable() {
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
            'PRODUCTO',
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
        ],
      ),
    ];

    int rowIndex = 0;
    for (var item in note.items) {
      final isEven = rowIndex % 2 == 1;
      rowIndex++;

      // Subtítulo con marca/modelo o descripción (homologado a Cotizaciones)
      String? subtitle;
      final modelParts = [
        if (item.brand != null &&
            item.brand != 'Sin marca' &&
            item.brand!.trim().isNotEmpty)
          item.brand!.trim(),
        if (item.model != null &&
            item.model != 'NO APLICA' &&
            item.model!.trim().isNotEmpty)
          item.model!.trim(),
      ];
      if (modelParts.isNotEmpty) {
        subtitle = modelParts.join(' - ');
      } else if (item.description != null &&
          item.description!.trim().isNotEmpty) {
        subtitle = item.description!.trim();
      }

      final hasSerials = item.serials.isNotEmpty;
      final warrantyStr = _formatWarranty(item.warrantyTime, item.warrantyUnit);
      final qtyStr = item.quantity % 1 == 0
          ? '${item.quantity.toInt()} ${item.uom}'
          : '${item.quantity.toStringAsFixed(2)} ${item.uom}';

      rows.add(
        _buildItemTableRow(
          name: item.name,
          subtitle: subtitle,
          serials: hasSerials
              ? item.serials.map((s) => s.serialNumber).toList()
              : null,
          warranty: warrantyStr,
          quantity: qtyStr,
          isEven: isEven,
        ),
      );
    }

    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FixedColumnWidth(90),
        2: pw.FixedColumnWidth(70),
      },
      children: rows,
    );
  }

  pw.TableRow _buildItemTableRow({
    required String name,
    String? subtitle,
    List<String>? serials,
    required String warranty,
    required String quantity,
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
        // Producto + Marca/Modelo + Seriales
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
              if (serials != null && serials.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  'Seriales: ${serials.join(", ")}',
                  style: pw.TextStyle(
                    fontSize: 6.8,
                    color: PdfThemeConfig.slate500,
                    fontStyle: pw.FontStyle.italic,
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
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: pw.Text(
            quantity,
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

  /// Tarjeta de Observaciones
  pw.Widget _buildObservationsBlock() {
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
                bottom:
                    pw.BorderSide(color: PdfThemeConfig.slate300, width: 1.5),
              ),
            ),
            child: pw.Text(
              'OBSERVACIONES',
              style: PdfThemeConfig.cardHeaderStyle,
            ),
          ),
          ...note.observations.map(
            (obs) => PdfCommonSections.buildBulletPoint(
              obs.description,
              PdfThemeConfig.slate700,
            ),
          ),
          if (note.notes != null && note.notes!.trim().isNotEmpty) ...[
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
                    text: note.notes!.trim(),
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

  /// Tarjeta de Firma de Recepción del Cliente
  pw.Widget _buildSignaturesBlock(pw.MemoryImage? signatureImage) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfThemeConfig.slate50,
        border: pw.Border.all(color: PdfThemeConfig.slate200, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Container(
            width: 220,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                if (signatureImage != null)
                  pw.Container(
                    height: 40,
                    alignment: pw.Alignment.center,
                    child: pw.Image(signatureImage, height: 38),
                  )
                else
                  pw.Container(height: 40),
                pw.Container(
                  width: 180,
                  height: 1,
                  color: PdfThemeConfig.slate300,
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Recibido Conforme / Cliente',
                  style: const pw.TextStyle(
                    fontSize: 7.5,
                    color: PdfThemeConfig.slate500,
                  ),
                ),
                if (note.receivedByName != null &&
                    note.receivedByName!.trim().isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    note.receivedByName!.trim(),
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfThemeConfig.slate900,
                    ),
                  ),
                  if (note.receivedById != null &&
                      note.receivedById!.trim().isNotEmpty)
                    pw.Text(
                      'C.I. / DNI: ${note.receivedById!.trim()}',
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfThemeConfig.slate500,
                      ),
                    ),
                  if (note.receivedAt != null)
                    pw.Text(
                      'Fecha: ${PdfHelpers.formatDate(note.receivedAt!)}',
                      style: const pw.TextStyle(
                        fontSize: 7,
                        color: PdfThemeConfig.slate500,
                      ),
                    ),
                ] else ...[
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Firma y Cédula',
                    style: const pw.TextStyle(
                      fontSize: 7.5,
                      color: PdfThemeConfig.slate500,
                    ),
                  ),
                ],
              ],
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
    if (normalizedUnit.contains('year') || normalizedUnit.contains('año')) {
      unitStr = numTime == 1 ? 'Año' : 'Años';
    } else if (normalizedUnit.contains('month') ||
        normalizedUnit.contains('mes')) {
      unitStr = numTime == 1 ? 'Mes' : 'Meses';
    } else if (normalizedUnit.contains('day') ||
        normalizedUnit.contains('dia')) {
      unitStr = numTime == 1 ? 'Día' : 'Días';
    }
    return '$numTime $unitStr';
  }
}
