import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Configuración de Tema y Paleta Slate para documentos PDF homologados con WebViews
class PdfThemeConfig {
  // Paleta Ejecutiva Slate
  static const PdfColor slate900 = PdfColor.fromInt(0xFF0F172A);
  static const PdfColor slate700 = PdfColor.fromInt(0xFF334155);
  static const PdfColor slate500 = PdfColor.fromInt(0xFF64748B);
  static const PdfColor slate300 = PdfColor.fromInt(0xFFCBD5E1);
  static const PdfColor slate200 = PdfColor.fromInt(0xFFE2E8F0);
  static const PdfColor slate100 = PdfColor.fromInt(0xFFF1F5F9);
  static const PdfColor slate50 = PdfColor.fromInt(0xFFF8FAFC);
  static const PdfColor white = PdfColor.fromInt(0xFFFFFFFF);

  // Retrocompatibilidad con nombres anteriores
  static const PdfColor accentColor = slate900;
  static const PdfColor primaryBlue = slate900;
  static const PdfColor black = slate900;
  static const PdfColor grey = slate500;

  static pw.ThemeData buildTheme() {
    return pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      italic: pw.Font.helveticaOblique(),
      boldItalic: pw.Font.helveticaBoldOblique(),
    );
  }

  // Estilos de Texto Estandarizados
  static pw.TextStyle titleStyle = pw.TextStyle(
    fontSize: 18,
    fontWeight: pw.FontWeight.bold,
    color: slate900,
    letterSpacing: 0.5,
  );

  static pw.TextStyle docMetaStyle = pw.TextStyle(
    fontSize: 9,
    fontWeight: pw.FontWeight.bold,
    color: slate500,
  );

  static pw.TextStyle letterheadTitleStyle = pw.TextStyle(
    fontSize: 10,
    fontWeight: pw.FontWeight.bold,
    color: slate900,
  );

  static pw.TextStyle letterheadDetailStyle = const pw.TextStyle(
    fontSize: 7.5,
    color: slate500,
  );

  static pw.TextStyle cardHeaderStyle = pw.TextStyle(
    fontSize: 8,
    fontWeight: pw.FontWeight.bold,
    color: slate900,
    letterSpacing: 0.5,
  );

  static pw.TextStyle bodyStyle = const pw.TextStyle(
    fontSize: 7.5,
    color: slate700,
  );

  static pw.TextStyle bodyBoldStyle = pw.TextStyle(
    fontSize: 7.5,
    color: slate900,
    fontWeight: pw.FontWeight.bold,
  );

  static pw.TextStyle labelStyle = const pw.TextStyle(
    fontSize: 7.5,
    color: slate500,
  );

  static pw.TextStyle smallStyle = const pw.TextStyle(
    fontSize: 7.5,
    color: slate700,
  );

  static pw.TextStyle captionStyle = const pw.TextStyle(
    fontSize: 6.5,
    color: slate500,
  );

  static pw.TextStyle tableHeaderStyle = pw.TextStyle(
    fontSize: 7,
    fontWeight: pw.FontWeight.bold,
    color: slate900,
    letterSpacing: 0.5,
  );

  static pw.TextStyle grandTotalStyle = pw.TextStyle(
    fontSize: 9.5,
    fontWeight: pw.FontWeight.bold,
    color: slate900,
  );

  // Configuración de márgenes estándar
  static const double horizontalMargin = 28.0;
  static const double verticalMargin = 24.0;
}
