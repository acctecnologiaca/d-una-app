import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../pdf_theme.dart';
import '../pdf_helpers.dart';
import '../pdf_common_sections.dart';
import '../../../features/supplier_orders/domain/models/supplier_order.dart';
import '../../../features/supplier_orders/domain/models/supplier_order_item.dart';
import '../../../features/profile/domain/models/user_profile.dart';

class SupplierOrderPdfTemplate {
  final SupplierOrder order;
  final List<SupplierOrderItem> items;
  final UserProfile userProfile;
  final String? userEmail;

  SupplierOrderPdfTemplate({
    required this.order,
    required this.items,
    required this.userProfile,
    this.userEmail,
  });

  Future<Uint8List> generate(PdfPageFormat format) async {
    final pdf = pw.Document(theme: PdfThemeConfig.buildTheme());
    final senderInfo = PdfHelpers.resolvePdfSenderInfo(userProfile, userEmail);
    final logoImage = await PdfHelpers.loadNetworkImage(senderInfo.logoUrl);
    final footerImage = await PdfHelpers.loadAssetImage('assets/images/creado_con_d_una.png');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(PdfThemeConfig.horizontalMargin),
        header: (context) => PdfCommonSections.buildLetterhead(
          title: 'ORDEN DE COMPRA',
          documentNumber: order.orderNumber,
          date: order.date,
          senderInfo: senderInfo,
          logoImage: logoImage,
        ),
        footer: (context) => PdfCommonSections.buildFooter(context, footerImage: footerImage),
        build: (context) => [
          _buildInfoGrid(senderInfo),
          pw.SizedBox(height: 20),
          _buildItemsTable(),
          pw.SizedBox(height: 10),
          _buildTotalsBlock(),
        ],
      ),
    );
    return pdf.save();
  }

  pw.Widget _buildInfoGrid(PdfSenderInfo senderInfo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Columna Izquierda: Datos del Proveedor
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Datos del Proveedor',
                style: PdfThemeConfig.headerStyle.copyWith(
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              pw.SizedBox(height: 4),
              _infoRow('Proveedor:', order.supplierName),
              _infoRow('Sucursal:', order.branchName ?? '-'),
              _infoRow('Método de Envío:', order.shippingMethodLabel ?? '-'),
              _infoRow('Condición de Pago:', order.paymentMethod ?? '-'),
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        // Columna Derecha: Emitido Por
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Emitido Por',
                style: PdfThemeConfig.headerStyle.copyWith(
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              pw.SizedBox(height: 4),
              _infoRow('Compañía:', senderInfo.name),
              _infoRow('Teléfono:', senderInfo.phone ?? '-'),
              _infoRow('Email:', userEmail ?? '-'),
              _infoRow('Dirección:', senderInfo.address),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _infoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.RichText(
        text: pw.TextSpan(
          children: [
            pw.TextSpan(
              text: '$label ',
              style: PdfThemeConfig.bodyStyle.copyWith(
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.TextSpan(text: value, style: PdfThemeConfig.bodyStyle),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildItemsTable() {
    final headers = ['CANT.', 'PRODUCTO / DETALLES', 'PRECIO UNIT.', 'SUB-TOTAL'];
    final columnWidths = {
      0: const pw.FixedColumnWidth(40),
      1: const pw.FlexColumnWidth(1),
      2: const pw.FixedColumnWidth(80),
      3: const pw.FixedColumnWidth(80),
    };

    final normalStyle = PdfThemeConfig.bodyStyle.copyWith(fontSize: 8);
    final boldStyle = PdfThemeConfig.bodyStyle.copyWith(fontSize: 8, fontWeight: pw.FontWeight.bold);
    final italicStyle = PdfThemeConfig.bodyStyle.copyWith(fontSize: 7, color: PdfColors.grey700, fontItalic: pw.Font.helveticaOblique());

    final rows = items.map((item) => [
      pw.Text(item.quantity.toStringAsFixed(0), style: boldStyle, textAlign: pw.TextAlign.center),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(item.name, style: boldStyle),
          if (item.model != null || item.brand != null)
            pw.Text('Modelo: ${item.model ?? "-"} (${item.brand ?? "-"})', style: italicStyle),
        ],
      ),
      PdfHelpers.formatCurrency(item.unitPrice),
      PdfHelpers.formatCurrency(item.total),
    ]).toList();

    return pw.Table(
      columnWidths: columnWidths,
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfThemeConfig.accentColor),
          children: headers.map((h) => pw.Container(
            padding: const pw.EdgeInsets.all(6),
            alignment: headers.indexOf(h) == 0 ? pw.Alignment.center : (headers.indexOf(h) >= 2 ? pw.Alignment.centerRight : pw.Alignment.centerLeft),
            child: pw.Text(h, style: boldStyle),
          )).toList(),
        ),
        ...rows.map((row) => pw.TableRow(
          children: row.map((cell) => pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            alignment: row.indexOf(cell) == 0 ? pw.Alignment.center : (row.indexOf(cell) >= 2 ? pw.Alignment.centerRight : pw.Alignment.centerLeft),
            child: cell is pw.Widget ? cell : pw.Text(cell.toString(), style: normalStyle),
          )).toList(),
        )),
      ],
    );
  }

  pw.Widget _buildTotalsBlock() {
    final boldStyle = PdfThemeConfig.bodyStyle.copyWith(fontSize: 9, fontWeight: pw.FontWeight.bold);
    final normalStyle = PdfThemeConfig.bodyStyle.copyWith(fontSize: 9);

    final taxRate = order.subtotal > 0 ? (order.tax / order.subtotal) * 100 : 0.0;

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          children: [
            _totalRow('Sub-Total:', PdfHelpers.formatCurrency(order.subtotal), normalStyle),
            _totalRow('IVA (${taxRate.toStringAsFixed(0)}%):', PdfHelpers.formatCurrency(order.tax), normalStyle),
            pw.Divider(),
            _totalRow('Total:', PdfHelpers.formatCurrency(order.total), boldStyle),
          ],
        ),
      ),
    );
  }

  pw.Widget _totalRow(String label, String value, pw.TextStyle style) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}
