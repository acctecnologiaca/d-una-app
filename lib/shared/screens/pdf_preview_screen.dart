import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
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
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: StandardAppBar(title: title, subtitle: subtitle),
      body: PdfPreview(
        build: buildPdf,
        pdfFileName: fileName,
        allowPrinting: false,
        allowSharing: false,
        canChangeOrientation: false,
        canChangePageFormat: false,
        initialPageFormat: PdfPageFormat.letter,
        enableScrollToPage: true,
        canDebug: false,
        scrollViewDecoration: BoxDecoration(color: Colors.white),
        actionBarTheme: PdfActionBarTheme(
          backgroundColor: colors.surface,
          iconColor: colors.onSurfaceVariant,
        ),
        loadingWidget: const Center(child: CircularProgressIndicator()),
        onError: (context, error) =>
            const Center(child: Text('Error al generar el PDF')),
        actions: [
          PdfPreviewAction(
            icon: const Icon(Symbols.download, size: 36),
            onPressed: (context, buildPdf, pageFormat) async {
              // Feedback visual inmediato
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Generando documento...'),
                  duration: Duration(seconds: 1),
                ),
              );

              // Generar los bytes del PDF
              final bytes = await buildPdf(pageFormat);

              if (Platform.isAndroid) {
                try {
                  // Camino B: Usar SAF (Storage Access Framework) para guardar
                  final params = SaveFileDialogParams(
                    data: bytes,
                    fileName: fileName,
                  );

                  final filePath = await FlutterFileDialog.saveFile(
                    params: params,
                  );

                  if (context.mounted && filePath != null) {
                    // Para que el botón "ABRIR" funcione siempre (incluso sin permisos de lectura en carpetas públicas),
                    // guardamos una copia temporal en la carpeta privada de la app.
                    final tempDir = await getTemporaryDirectory();
                    final tempPath = '${tempDir.path}/$fileName';
                    final tempFile = File(tempPath);
                    await tempFile.writeAsBytes(bytes);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 8),
                          behavior: SnackBarBehavior.fixed,
                          content: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Archivo guardado exitosamente',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    /*Text(
                                      filePath,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.white70,
                                      ),
                                    ),*/
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  // Abrimos el archivo temporal que tiene garantizado el acceso
                                  await OpenFilex.open(
                                    tempPath,
                                    type: "application/pdf",
                                  );
                                },
                                child: Text(
                                  'Abrir',
                                  style: TextStyle(
                                    color: colors.inversePrimary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.white54,
                                  size: 20,
                                ),
                                onPressed: () {
                                  ScaffoldMessenger.of(
                                    context,
                                  ).hideCurrentSnackBar();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error al guardar el archivo: $e'),
                      ),
                    );
                  }
                }
              } else {
                // Lógica para iOS y otras plataformas: Menú nativo de compartir
                await Printing.sharePdf(bytes: bytes, filename: fileName);
              }
            },
          ),
        ],
      ),
    );
  }
}
