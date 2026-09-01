import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'pdf_theme.dart';
import 'pdf_helpers.dart';

class PdfCommonSections {
  /// Construye la cabecera ejecutiva horizontal homologada con los WebViews
  static pw.Widget buildLetterhead({
    required String title,
    required String documentNumber,
    required DateTime date,
    required PdfSenderInfo senderInfo,
    pw.MemoryImage? logoImage,
    String? badgeText,
    PdfColor? badgeColor,
    PdfColor? badgeBgColor,
    PdfColor? badgeBorderColor,
  }) {
    final formattedDate = PdfHelpers.formatDate(date);

    return pw.Column(
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 12),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfThemeConfig.slate900, width: 2),
            ),
          ),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              // Columna Izquierda: Logo + Título + Membrete Emisor
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Fila de Marca (Logo + Título + Meta)
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        if (logoImage != null)
                          pw.Container(
                            width: 80,
                            height: 40,
                            margin: const pw.EdgeInsets.only(right: 12),
                            child: pw.Image(logoImage, fit: pw.BoxFit.contain, alignment: pw.Alignment.centerLeft),
                          ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              title,
                              style: PdfThemeConfig.titleStyle,
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              '$documentNumber   |   $formattedDate',
                              style: PdfThemeConfig.docMetaStyle,
                            ),
                          ],
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),

                    // Datos del Membrete
                    pw.Text(
                      senderInfo.name,
                      style: PdfThemeConfig.letterheadTitleStyle,
                    ),
                    if (senderInfo.rif.isNotEmpty) ...[
                      pw.SizedBox(height: 2),
                      pw.Text(
                        'RIF / ID Fiscal: ${senderInfo.rif}',
                        style: PdfThemeConfig.letterheadDetailStyle,
                      ),
                    ],
                    if (senderInfo.address.isNotEmpty) ...[
                      pw.Text(
                        'Dirección: ${senderInfo.address}',
                        style: PdfThemeConfig.letterheadDetailStyle,
                      ),
                    ],
                    if (senderInfo.phone != null || senderInfo.email != null) ...[
                      pw.Text(
                        [
                          if (senderInfo.phone != null && senderInfo.phone!.isNotEmpty)
                            'Teléfono: ${senderInfo.phone}',
                          if (senderInfo.email != null && senderInfo.email!.isNotEmpty)
                            'Email: ${senderInfo.email}',
                        ].join('   |   '),
                        style: PdfThemeConfig.letterheadDetailStyle,
                      ),
                    ],
                  ],
                ),
              ),

              // Columna Derecha: Badge de Validez / Estado (si aplica)
              if (badgeText != null && badgeText.isNotEmpty) ...[
                pw.SizedBox(width: 16),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: pw.BoxDecoration(
                    color: badgeBgColor ?? PdfThemeConfig.slate50,
                    border: pw.Border.all(
                      color: badgeBorderColor ?? PdfThemeConfig.slate300,
                      width: 1,
                    ),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(
                        badgeText,
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: badgeColor ?? PdfThemeConfig.slate900,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        pw.SizedBox(height: 14),
      ],
    );
  }

  /// Construye el pie de página homologado: Logo D-UNA centrado a 50% opacidad sobre © 2026 y paginación a la derecha
  static pw.Widget buildFooter(
    pw.Context context, {
    pw.MemoryImage? footerLogoImage,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Stack(
        alignment: pw.Alignment.bottomCenter,
        children: [
          pw.Column(
            mainAxisSize: pw.MainAxisSize.min,
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              if (footerLogoImage != null) ...[
                pw.Opacity(
                  opacity: 0.5,
                  child: pw.Container(
                    height: 14,
                    child: pw.Image(footerLogoImage, fit: pw.BoxFit.contain),
                  ),
                ),
                pw.SizedBox(height: 2),
              ],
              pw.Text(
                '© 2026',
                style: PdfThemeConfig.captionStyle,
              ),
            ],
          ),
          pw.Align(
            alignment: pw.Alignment.bottomRight,
            child: pw.Text(
              'Página ${context.pageNumber} de ${context.pagesCount}',
              style: PdfThemeConfig.captionStyle,
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta de Información estandarizada (info-box) con fondo slate50 y borde slate200
  static pw.Widget buildInfoCard({
    required String title,
    required List<pw.Widget> children,
  }) {
    return pw.Container(
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
              title,
              style: PdfThemeConfig.cardHeaderStyle,
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  /// Fila de dato clave-valor para las tarjetas de información
  static pw.Widget buildInfoRow(
    String label,
    String value, {
    double labelWidth = 80,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: labelWidth,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfThemeConfig.slate500,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(
                fontSize: 7.5,
                color: PdfThemeConfig.slate900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Celda de cabecera de tabla
  static pw.Widget buildTableHeaderCell(
    String text,
    pw.Alignment alignment,
  ) {
    return pw.Container(
      alignment: alignment,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        style: PdfThemeConfig.tableHeaderStyle,
      ),
    );
  }

  /// Viñeta circular vectorial para compatibilidad estándar
  static pw.Widget buildBulletPoint(String text, PdfColor color) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 2.5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            margin: const pw.EdgeInsets.only(top: 3.5, right: 5),
            width: 2.5,
            height: 2.5,
            decoration: pw.BoxDecoration(
              color: color,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              text,
              style: pw.TextStyle(fontSize: 7.5, color: color, lineSpacing: 1.1),
            ),
          ),
        ],
      ),
    );
  }
}
