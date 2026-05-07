import 'dart:typed_data';
import 'package:pdf/pdf.dart';

class PdfPreviewData {
  final String title;
  final String? subtitle;
  final String fileName;
  final Future<Uint8List> Function(PdfPageFormat) buildPdf;

  PdfPreviewData({
    required this.title,
    this.subtitle,
    required this.fileName,
    required this.buildPdf,
  });

  /// Almacenamiento global para persistir los datos del PDF durante la navegación
  /// y evitar la pérdida de datos cuando el router se reconstruye (ej. en Android).
  static PdfPreviewData? lastData;
}
