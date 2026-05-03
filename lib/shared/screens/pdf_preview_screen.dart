import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../widgets/standard_app_bar.dart';

class PdfPreviewScreen extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String fileName;
  final Future<Uint8List> Function(PdfPageFormat format) buildPdf;

  const PdfPreviewScreen({
    super.key,
    required this.title,
    this.subtitle,
    this.fileName = 'documento.pdf',
    required this.buildPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: StandardAppBar(
        title: title,
        subtitle: subtitle,
      ),
      body: PdfPreview(
        build: buildPdf,
        pdfFileName: fileName,
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: true,
        initialPageFormat: PdfPageFormat.letter,
        // Personalización de colores para que combine con el tema
        loadingWidget: const Center(child: CircularProgressIndicator()),
        onError: (context, error) => const Center(child: Text('Error al generar el PDF')),
      ),
    );
  }
}
