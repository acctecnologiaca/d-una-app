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
    final footerImage = await PdfHelpers.loadAssetImage(
      'assets/images/creado_con_d_una.png',
    );

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
        footer: (context) =>
            PdfCommonSections.buildFooter(context, footerImage: footerImage),
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
                  fontStyle: pw.FontStyle.italic,
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
                  fontStyle: pw.FontStyle.italic,
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
    final headers = [
      'CANT.',
      'PRODUCTO / DETALLES',
      'PRECIO UNIT.',
      'SUB-TOTAL',
    ];
    final columnWidths = {
      0: const pw.FixedColumnWidth(40),
      1: const pw.FlexColumnWidth(1),
      2: const pw.FixedColumnWidth(80),
      3: const pw.FixedColumnWidth(80),
    };

    final normalStyle = PdfThemeConfig.bodyStyle.copyWith(fontSize: 8);
    final boldStyle = PdfThemeConfig.bodyStyle.copyWith(
      fontSize: 8,
      fontWeight: pw.FontWeight.bold,
    );
    final italicStyle = PdfThemeConfig.bodyStyle.copyWith(
      fontSize: 7,
      color: PdfColors.grey700,
      fontItalic: pw.Font.helveticaOblique(),
    );

    // Group items by product
    final Map<String, List<SupplierOrderItem>> groupedItems = {};
    for (final item in items) {
      final key = '${item.name}|${item.model ?? ''}|${item.brand ?? ''}';
      groupedItems.putIfAbsent(key, () => []).add(item);
    }

    final rows = groupedItems.values.map((group) {
      final firstItem = group.first;
      final totalQuantity = group.fold(0.0, (sum, item) => sum + item.quantity);
      final totalPrice = group.fold(0.0, (sum, item) => sum + item.total);
      final unitPrice = firstItem.unitPrice;

      // Model code placed to the left of product name
      final hasModel =
          firstItem.model != null && firstItem.model!.trim().isNotEmpty;
      final productTitle = hasModel
          ? '[${firstItem.model!.trim()}] ${firstItem.name}'
          : firstItem.name;

      // Per-branch quantity breakdown lines
      final branchLines = group.map((item) {
        final bName = (item.branchName != null && item.branchName!.isNotEmpty)
            ? item.branchName!
            : (order.branchName ?? 'Sucursal principal');
        final qtyStr = item.quantity.toStringAsFixed(
          item.quantity.truncateToDouble() == item.quantity ? 0 : 2,
        );
        return '- $bName: $qtyStr ${item.uom}';
      }).toList();

      final qtyDisplay = totalQuantity.toStringAsFixed(
        totalQuantity.truncateToDouble() == totalQuantity ? 0 : 2,
      );

      return [
        pw.Text(qtyDisplay, style: boldStyle, textAlign: pw.TextAlign.center),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(productTitle, style: boldStyle),
            if (firstItem.brand != null && firstItem.brand!.trim().isNotEmpty)
              pw.Text('Marca: ${firstItem.brand}', style: italicStyle),
            pw.SizedBox(height: 2),
            ...branchLines.map((line) => pw.Text(line, style: italicStyle)),
          ],
        ),
        PdfHelpers.formatCurrency(unitPrice),
        PdfHelpers.formatCurrency(totalPrice),
      ];
    }).toList();

    if (rows.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        child: pw.Text(
          'Esta orden no contiene productos registrados.',
          style: normalStyle,
        ),
      );
    }

    return pw.Column(
      children: [
        // 1. Tabla de Cabecera
        pw.Table(
          columnWidths: columnWidths,
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfThemeConfig.accentColor,
              ),
              children: headers.map((h) {
                final index = headers.indexOf(h);
                pw.Alignment alignment = pw.Alignment.centerLeft;
                if (index == 0) alignment = pw.Alignment.center;
                if (index >= 2) alignment = pw.Alignment.centerRight;

                return pw.Container(
                  alignment: alignment,
                  padding: const pw.EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 3,
                  ),
                  child: pw.Text(h, style: PdfThemeConfig.tableHeaderStyle),
                );
              }).toList(),
            ),
          ],
        ),
        pw.SizedBox(height: 10),
        // 2. Tabla de Contenido
        pw.Table(
          columnWidths: columnWidths,
          border: const pw.TableBorder(
            left: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            right: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
          ),
          children: rows.map((row) {
            return pw.TableRow(
              children: row.map((cell) {
                final index = row.indexOf(cell);
                pw.Alignment alignment = pw.Alignment.topLeft;
                if (index == 0) alignment = pw.Alignment.topCenter;
                if (index >= 2) alignment = pw.Alignment.topRight;

                return pw.Container(
                  alignment: alignment,
                  padding: const pw.EdgeInsets.all(5),
                  child: cell is pw.Widget
                      ? cell
                      : pw.Text(
                          cell.toString(),
                          style: PdfThemeConfig.bodyStyle,
                        ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ],
    );
  }

  pw.Widget _buildTotalsBlock() {
    final taxRate = order.subtotal > 0
        ? (order.tax / order.subtotal) * 100
        : 0.0;

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 150,
          padding: const pw.EdgeInsets.all(5),
          decoration: const pw.BoxDecoration(
            border: pw.TableBorder(
              bottom: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              top: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              left: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
              right: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
            ),
          ),
          child: pw.Column(
            children: [
              _totalRow(
                'Sub-Total (USD):',
                PdfHelpers.formatCurrency(order.subtotal),
              ),
              pw.SizedBox(height: 5),
              _totalRow(
                'IVA (${taxRate.toStringAsFixed(0)}%):',
                PdfHelpers.formatCurrency(order.tax),
              ),
              pw.Divider(color: PdfColors.grey300),
              _totalRow(
                'Total (USD):',
                PdfHelpers.formatCurrency(order.total),
                isBold: true,
                fontSize: 11,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _totalRow(
    String label,
    String value, {
    bool isBold = false,
    double fontSize = 9,
  }) {
    final style = PdfThemeConfig.bodyStyle.copyWith(
      fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontSize: fontSize,
    );
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(value, style: style),
      ],
    );
  }
}
