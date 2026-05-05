import 'dart:typed_data';
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
    final pdf = pw.Document(theme: PdfThemeConfig.buildTheme());

    // Resolver info del emisor (con fallback)
    final senderInfo = PdfHelpers.resolvePdfSenderInfo(userProfile, userEmail);

    // Cargar logo si existe
    final logoImage = await PdfHelpers.loadNetworkImage(senderInfo.logoUrl);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: format,
        margin: const pw.EdgeInsets.all(PdfThemeConfig.horizontalMargin),
        header: (context) => PdfCommonSections.buildLetterhead(
          title: 'COTIZACIÓN',
          documentNumber: quote.quoteNumber ?? '-',
          date: quote.dateIssued,
          senderInfo: senderInfo,
          logoImage: logoImage,
        ),
        footer: (context) => PdfCommonSections.buildFooter(context),
        build: (context) => [
          _buildInfoGrid(senderInfo),
          pw.SizedBox(height: 20),
          _buildItemsTable(),
          pw.SizedBox(height: 20),
          _buildTotalsBlock(),
          pw.SizedBox(height: 20),
          _buildConditionsBlock(),
        ],
      ),
    );

    return pdf.save();
  }

  /// Grid de 2 columnas: Datos del Cliente y Asesor Comercial
  pw.Widget _buildInfoGrid(PdfSenderInfo senderInfo) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Columna Izquierda: Datos del Cliente
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
              _infoRow(
                quote.clientType == 'person' ? 'Nombre:' : 'Razón Social:',
                quote.clientName ?? '-',
              ),
              _infoRow(
                quote.clientType == 'person' ? 'Cédula:' : 'RIF:',
                quote.clientTaxId ?? '-',
              ),
              if (quote.clientType != 'person')
                _infoRow('Atención:', quote.contactName ?? '-'),
              _infoRow('Teléfono:', quote.clientPhone ?? '-'),
              _infoRow('Email:', quote.clientEmail ?? '-'),
            ],
          ),
        ),

        pw.SizedBox(width: 40),

        // Columna Derecha: Asesor Comercial
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Asesor Comercial',
                style: PdfThemeConfig.headerStyle.copyWith(
                  fontStyle: pw.FontStyle.italic,
                  decoration: pw.TextDecoration.underline,
                ),
              ),
              pw.SizedBox(height: 4),
              _infoRow(
                'Nombre y Apellido:',
                quote.advisorName ??
                    '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}',
              ),
              _infoRow('Teléfono:', userProfile.phone ?? '-'),
              _infoRow('Email:', userEmail ?? '-'),
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

  /// Tabla única para productos y servicios
  pw.Widget _buildItemsTable() {
    // 1. Agrupar productos por groupIndex
    final groupedProducts = <int, List<QuoteItemProduct>>{};
    for (var product in products) {
      if (!groupedProducts.containsKey(product.groupIndex)) {
        groupedProducts[product.groupIndex] = [];
      }
      groupedProducts[product.groupIndex]!.add(product);
    }

    // 2. Ordenar las llaves (índices) para mantener el orden correcto
    final sortedGroupIndices = groupedProducts.keys.toList()..sort();

    final headers = [
      'Cant.',
      'Producto / Servicio',
      'Código',
      'Marca',
      'Garantía',
      'Precio Unit.',
      'SubTotal',
    ];

    final columnWidths = {
      0: const pw.FixedColumnWidth(35), // Cantidad
      1: const pw.FlexColumnWidth(90), // Producto/Servicio
      2: const pw.FixedColumnWidth(80), // Código
      3: const pw.FixedColumnWidth(60), // Marca
      4: const pw.FixedColumnWidth(55), // Garantía
      5: const pw.FixedColumnWidth(70), // P. Unitario
      6: const pw.FixedColumnWidth(60), // Sub-total
    };

    final reducedStyle = PdfThemeConfig.bodyStyle.copyWith(fontSize: 6.3);

    final dataRows = [
      // Filas de Productos
      ...sortedGroupIndices.map((index) {
        final items = groupedProducts[index]!;
        final firstItem = items.first;

        // Calcular totales del grupo
        double totalQuantity = 0;
        double subtotal = 0;
        for (var item in items) {
          totalQuantity += item.quantity;
          subtotal += item.totalPrice;
        }

        return [
          totalQuantity.toStringAsFixed(0),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                firstItem.name,
                style: PdfThemeConfig.bodyStyle.copyWith(
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (firstItem.description != null &&
                  firstItem.description!.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2, left: 4),
                  child: pw.Text(
                    '- ${firstItem.description}',
                    style: PdfThemeConfig.captionStyle.copyWith(fontSize: 7),
                  ),
                ),
            ],
          ),
          pw.Text(firstItem.model ?? '-', style: reducedStyle),
          pw.Text(firstItem.brand ?? '-', style: reducedStyle),
          pw.Text(firstItem.warrantyDisplay ?? '-', style: reducedStyle),
          PdfHelpers.formatCurrency(firstItem.unitPrice),
          PdfHelpers.formatCurrency(subtotal),
        ];
      }),
      // Filas de Servicios
      ...services.map(
        (s) => [
          s.quantity.toStringAsFixed(0),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                s.name,
                style: PdfThemeConfig.bodyStyle.copyWith(
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (s.description != null && s.description!.isNotEmpty)
                pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 2, left: 4),
                  child: pw.Text(
                    '- ${s.description}',
                    style: PdfThemeConfig.captionStyle.copyWith(fontSize: 7),
                  ),
                ),
            ],
          ),
          pw.Text('-', style: reducedStyle),
          pw.Text('-', style: reducedStyle),
          pw.Text('-', style: reducedStyle),
          PdfHelpers.formatCurrency(s.unitPrice),
          PdfHelpers.formatCurrency(s.totalPrice),
        ],
      ),
    ];

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
                if (index >= 5) alignment = pw.Alignment.centerRight;

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
        pw.SizedBox(height: 10), // Espacio solicitado
        // 2. Tabla de Contenido
        pw.Table(
          columnWidths: columnWidths,
          border: const pw.TableBorder(
            left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
          ),
          children: dataRows.map((row) {
            return pw.TableRow(
              children: row.map((cell) {
                final index = row.indexOf(cell);
                pw.Alignment alignment = pw.Alignment.topLeft;
                if (index == 0) alignment = pw.Alignment.topCenter;
                if (index >= 5) alignment = pw.Alignment.topRight;

                return pw.Container(
                  alignment: alignment,
                  padding: const pw.EdgeInsets.all(3),
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

  /// Bloque de Totales alineado a la derecha
  pw.Widget _buildTotalsBlock() {
    final taxRate = quote.subtotal > 0
        ? (quote.taxAmount / quote.subtotal * 100).toStringAsFixed(0)
        : '16';

    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Container(
          width: 150,
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.TableBorder(
              bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              left: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
              right: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
            ),
          ),
          child: pw.Column(
            children: [
              _totalRow(
                'Sub-Total (USD):',
                PdfHelpers.formatCurrency(quote.subtotal),
              ),
              pw.SizedBox(height: 5),
              _totalRow(
                'IVA ($taxRate%):',
                PdfHelpers.formatCurrency(quote.taxAmount),
              ),
              pw.Divider(color: PdfColors.grey300),
              _totalRow(
                'Total (USD):',
                PdfHelpers.formatCurrency(quote.total),
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

  /// Condiciones comerciales y notas
  pw.Widget _buildConditionsBlock() {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        ...conditions.map((c) {
          final isImportant =
              c.description.toLowerCase().contains('importante') ||
              c.description.toLowerCase().contains('retención');

          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 4),
            child: pw.Text(
              c.description,
              style: isImportant
                  ? PdfThemeConfig.importantStyle
                  : PdfThemeConfig.smallStyle,
            ),
          );
        }),
        if (quote.notes != null && quote.notes!.isNotEmpty) ...[
          pw.SizedBox(height: 10),
          pw.Text('Observaciones:', style: PdfThemeConfig.headerStyle),
          pw.Text(quote.notes!, style: PdfThemeConfig.smallStyle),
        ],
      ],
    );
  }
}
