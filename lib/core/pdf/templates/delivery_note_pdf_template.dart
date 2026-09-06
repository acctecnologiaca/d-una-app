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
      final pdf = pw.Document(theme: PdfThemeConfig.buildTheme());

      // Resolver info del emisor
      final senderInfo = PdfHelpers.resolvePdfSenderInfo(userProfile, userEmail);

      // Cargar logo si existe
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
          footer: (context) =>
              PdfCommonSections.buildFooter(context, footerLogoImage: footerImage),
          build: (context) => [
            _buildInfoGrid(),
            pw.SizedBox(height: 14),
            _buildItemsTable(),
            pw.SizedBox(height: 12),
            _buildTotalsBlock(),
            if (note.observations.isNotEmpty ||
                (note.notes != null && note.notes!.trim().isNotEmpty)) ...[
              pw.SizedBox(height: 14),
              _buildObservationsBlock(),
            ],
            pw.SizedBox(height: 20),
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

  pw.Widget _buildInfoGrid() {
    final deliveryTypeLabel = note.deliveryType == 'store_pickup'
        ? 'Retiro en tienda / almacén'
        : (note.deliveryType == 'carrier'
            ? 'Envío por encomienda / transportista'
            : 'Despacho propio');

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Columna Izquierda: Datos del Cliente y Destino
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DESTINATARIO / CLIENTE',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfThemeConfig.slate900,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                note.clientName,
                style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
              ),
              if (note.clientTaxId != null && note.clientTaxId!.isNotEmpty)
                pw.Text('RIF/ID: ${note.clientTaxId}', style: const pw.TextStyle(fontSize: 8)),
              if (note.contactName != null && note.contactName!.isNotEmpty)
                pw.Text('Contacto: ${note.contactName}', style: const pw.TextStyle(fontSize: 8)),
              if (note.recipientAddress != null && note.recipientAddress!.isNotEmpty)
                pw.Text(
                  'Dirección: ${note.recipientAddress}${note.recipientCity != null ? ", ${note.recipientCity}" : ""}',
                  style: const pw.TextStyle(fontSize: 8),
                ),
            ],
          ),
        ),
        pw.SizedBox(width: 20),

        // Columna Derecha: Datos de Envío y Despacho
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'DETALLES DEL DESPACHO',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfThemeConfig.slate900,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text('Modalidad: $deliveryTypeLabel', style: const pw.TextStyle(fontSize: 8)),
              if (note.shippingCompanyName != null && note.shippingCompanyName!.isNotEmpty)
                pw.Text('Transporte: ${note.shippingCompanyName}', style: const pw.TextStyle(fontSize: 8)),
              if (note.trackingNumber != null && note.trackingNumber!.isNotEmpty)
                pw.Text('Guía / Tracking: ${note.trackingNumber}', style: const pw.TextStyle(fontSize: 8)),
              if (note.deliveryDate != null)
                pw.Text('Fecha de Entrega: ${PdfHelpers.formatDate(note.deliveryDate!)}', style: const pw.TextStyle(fontSize: 8)),
              if (note.clientPoNumber != null && note.clientPoNumber!.isNotEmpty)
                pw.Text('O/C Cliente: ${note.clientPoNumber}', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildItemsTable() {
    return pw.TableHelper.fromTextArray(
      border: null,
      headerStyle: pw.TextStyle(
        fontSize: 8,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfThemeConfig.slate900),
      headerHeight: 22,
      cellHeight: 22,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      headers: ['Ítem / Descripción', 'Garantía', 'Cant.', 'P. Unit.', 'Total'],
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1.5),
        2: const pw.FlexColumnWidth(1),
        3: const pw.FlexColumnWidth(1.5),
        4: const pw.FlexColumnWidth(1.5),
      },
      data: note.items.map((item) {
        final serialsText = item.serials.isNotEmpty
            ? '\nSeriales: ${item.serials.map((s) => s.serialNumber).join(", ")}'
            : '';
        final desc = '${item.name}${item.brand != null ? " - ${item.brand}" : ""}$serialsText';

        final warranty = item.warrantyTime != null
            ? '${item.warrantyTime} ${item.warrantyUnit == "years" ? "años" : (item.warrantyUnit == "months" ? "meses" : "días")}'
            : '-';

        return [
          desc,
          warranty,
          '${item.quantity % 1 == 0 ? item.quantity.toInt() : item.quantity} ${item.uom}',
          PdfHelpers.formatCurrency(item.unitPrice),
          PdfHelpers.formatCurrency(item.totalPrice),
        ];
      }).toList(),
    );
  }

  pw.Widget _buildTotalsBlock() {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 200,
          child: pw.Column(
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Subtotal:', style: const pw.TextStyle(fontSize: 8)),
                  pw.Text(PdfHelpers.formatCurrency(note.subtotalAmount), style: const pw.TextStyle(fontSize: 8)),
                ],
              ),
              if (note.taxAmount > 0) ...[
                pw.SizedBox(height: 2),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('IVA (${(note.taxRate * 100).toStringAsFixed(0)}%):', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(PdfHelpers.formatCurrency(note.taxAmount), style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
              ],
              pw.Divider(height: 8),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Total:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(PdfHelpers.formatCurrency(note.totalAmount), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildObservationsBlock() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'CONDICIONES Y OBSERVACIONES',
          style: pw.TextStyle(
            fontSize: 8,
            fontWeight: pw.FontWeight.bold,
            color: PdfThemeConfig.slate900,
          ),
        ),
        pw.SizedBox(height: 4),
        ...note.observations.map(
          (obs) => pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 2),
            child: pw.Text(
              '• ${obs.title}: ${obs.description}',
              style: const pw.TextStyle(fontSize: 7),
            ),
          ),
        ),
        if (note.notes != null && note.notes!.trim().isNotEmpty) ...[
          pw.SizedBox(height: 4),
          pw.Text('Notas adicionales: ${note.notes}', style: pw.TextStyle(fontSize: 7, fontStyle: pw.FontStyle.italic)),
        ],
      ],
    );
  }

  pw.Widget _buildSignaturesBlock(pw.MemoryImage? signatureImage) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        // Emisor / Despachador
        pw.Expanded(
          child: pw.Column(
            children: [
              pw.Container(height: 40),
              pw.Container(width: 150, height: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),
              pw.Text('Entregado conforme / Despacho', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              pw.Text(
                ('${userProfile.firstName ?? ""} ${userProfile.lastName ?? ""}'.trim().isNotEmpty
                    ? '${userProfile.firstName ?? ""} ${userProfile.lastName ?? ""}'.trim()
                    : 'Emisor'),
                style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 40),

        // Receptor
        pw.Expanded(
          child: pw.Column(
            children: [
              if (signatureImage != null)
                pw.Container(
                  height: 40,
                  alignment: pw.Alignment.center,
                  child: pw.Image(signatureImage, height: 38),
                )
              else
                pw.Container(height: 40),
              pw.Container(width: 150, height: 1, color: PdfColors.black),
              pw.SizedBox(height: 4),
              pw.Text('Recibido conforme / Cliente', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
              if (note.receivedByName != null) ...[
                pw.Text(note.receivedByName!, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                if (note.receivedById != null)
                  pw.Text('C.I. / DNI: ${note.receivedById}', style: const pw.TextStyle(fontSize: 7)),
                if (note.receivedAt != null)
                  pw.Text('Fecha: ${PdfHelpers.formatDate(note.receivedAt!)}', style: const pw.TextStyle(fontSize: 7)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Future<Uint8List> _buildErrorDocument(String message) async {
    final errorPdf = pw.Document(theme: PdfThemeConfig.buildTheme());
    errorPdf.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Text(
              message,
              style: const pw.TextStyle(fontSize: 12, color: PdfColors.red),
            ),
          ),
        ),
      ),
    );
    return await errorPdf.save();
  }
}
