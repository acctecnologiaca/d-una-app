import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfThemeConfig {
  static const PdfColor accentColor = PdfColor.fromInt(0xFF263547);
  static const PdfColor primaryBlue = PdfColor.fromInt(0xFF36618E);
  static const PdfColor black = PdfColor.fromInt(0xFF000000);
  static const PdfColor white = PdfColor.fromInt(0xFFFFFFFF);
  static const PdfColor grey = PdfColor.fromInt(0xFF757575);

  static pw.ThemeData buildTheme() {
    return pw.ThemeData.withFont(
      // Por ahora usamos las fuentes estándar de PDF (Helvetica)
      // para evitar problemas de carga de archivos de fuentes en esta fase.
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      italic: pw.Font.helveticaOblique(),
      boldItalic: pw.Font.helveticaBoldOblique(),
    );
  }

  // Estilos de Texto
  static pw.TextStyle titleStyle = pw.TextStyle(
    fontSize: 24,
    fontWeight: pw.FontWeight.bold,
    color: black,
  );

  static pw.TextStyle headerStyle = pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
    color: black,
  );

  static pw.TextStyle bodyStyle = const pw.TextStyle(fontSize: 9, color: black);

  static pw.TextStyle smallStyle = const pw.TextStyle(
    fontSize: 8,
    color: black,
  );

  static pw.TextStyle captionStyle = const pw.TextStyle(
    fontSize: 7,
    color: grey,
  );

  static pw.TextStyle tableHeaderStyle = pw.TextStyle(
    fontSize: 8,
    fontWeight: pw.FontWeight.bold,
    color: white,
  );

  static pw.TextStyle importantStyle = pw.TextStyle(
    fontSize: 8,
    fontWeight: pw.FontWeight.bold,
    fontStyle: pw.FontStyle.italic,
    color: accentColor,
  );

  // Configuración de página
  static const double horizontalMargin = 40.0;
  static const double verticalMargin = 40.0;
}
