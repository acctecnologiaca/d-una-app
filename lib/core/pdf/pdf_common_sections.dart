import 'package:pdf/widgets.dart' as pw;
import 'pdf_theme.dart';
import 'pdf_helpers.dart';

class PdfCommonSections {
  /// Construye el membrete con Logo a la izquierda y Título/Datos a la derecha
  static pw.Widget buildLetterhead({
    required String title,
    required String documentNumber,
    required DateTime date,
    required PdfSenderInfo senderInfo,
    pw.MemoryImage? logoImage,
    String? dateLabel,
    String? dateValue,
  }) {
    return pw.Column(
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            // Columna Izquierda: Logo + Datos Empresa
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                if (logoImage != null)
                  pw.Container(
                    width: 100,
                    height: 50,
                    child: pw.Image(logoImage, fit: pw.BoxFit.contain),
                  )
                else
                  pw.SizedBox(height: 50), // Placeholder espacio

                pw.SizedBox(height: 8),
                pw.Text(senderInfo.name, style: PdfThemeConfig.smallStyle),
                pw.Text(
                  'RIF: ${senderInfo.rif}',
                  style: PdfThemeConfig.smallStyle,
                ),
                pw.Container(
                  width: 250,
                  child: pw.Text(
                    'Dirección: ${senderInfo.address}',
                    style: PdfThemeConfig.smallStyle,
                  ),
                ),
                if (senderInfo.phone != null)
                  pw.Text(
                    'Teléfono: ${senderInfo.phone}',
                    style: PdfThemeConfig.smallStyle,
                  ),
                if (senderInfo.email != null)
                  pw.Text(
                    'Email: ${senderInfo.email}',
                    style: PdfThemeConfig.smallStyle,
                  ),
              ],
            ),

            // Columna Derecha: Título + Nro + Fecha
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(title, style: PdfThemeConfig.titleStyle),
                pw.Text(
                  '#$documentNumber',
                  style: PdfThemeConfig.subTitleStyle,
                ),
                pw.SizedBox(height: 20),
                pw.Text(dateLabel ?? 'Fecha', style: PdfThemeConfig.headerStyle),
                pw.Text(
                  dateValue ?? PdfHelpers.formatDate(date),
                  style: PdfThemeConfig.bodyStyle,
                ),
                /*  pw.SizedBox(height: 10),
                pw.Text(
                  'Nro. ${title.split(' ').first}',
                  style: PdfThemeConfig.headerStyle,
                ),
                pw.Text(documentNumber, style: PdfThemeConfig.bodyStyle),*/
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  /// Construye el pie de página con número de página e imagen de marca
  static pw.Widget buildFooter(
    pw.Context context, {
    pw.ImageProvider? footerImage,
  }) {
    return pw.Column(
      children: [
        pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: PdfThemeConfig.captionStyle,
          ),
        ),
        pw.SizedBox(height: 10),
        if (footerImage != null)
          pw.Container(
            width: 50,
            height: 25,
            child: pw.Image(footerImage, fit: pw.BoxFit.contain),
          ),
      ],
    );
  }
}
