import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() async {
  final pdf = pw.Document();

  // Color Tokens Neutros Ejecutivos
  const neutralDark = PdfColor.fromInt(0xFF0F172A);
  const neutralMedium = PdfColor.fromInt(0xFF334155);
  const neutralMuted = PdfColor.fromInt(0xFF64748B);
  const neutralBorder = PdfColor.fromInt(0xFFE2E8F0);
  const neutralBorderDark = PdfColor.fromInt(0xFFCBD5E1);
  const neutralBgSubtle = PdfColor.fromInt(0xFFF8FAFC);
  const neutralBgHeader = PdfColor.fromInt(0xFFF1F5F9);

  final baseFont = pw.Font.helvetica();
  final boldFont = pw.Font.helveticaBold();

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (pw.Context context) {
        return [
          // 1. ENCABEZADO MONOCROMÁTICO NEUTRO
          pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: neutralDark, width: 2),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'COTIZACIÓN',
                      style: pw.TextStyle(
                        font: boldFont,
                        fontSize: 22,
                        color: neutralDark,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'CT-VE0001-26001 • Fecha: 30/07/2026',
                      style: pw.TextStyle(
                        font: baseFont,
                        fontSize: 10,
                        color: neutralMuted,
                      ),
                    ),
                  ],
                ),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: pw.BoxDecoration(
                    color: neutralBgSubtle,
                    borderRadius: pw.BorderRadius.circular(16),
                    border: pw.Border.all(color: neutralBorderDark),
                  ),
                  child: pw.Text(
                    'Válida hasta: 14/08/2026',
                    style: pw.TextStyle(
                      font: boldFont,
                      fontSize: 9,
                      color: neutralDark,
                    ),
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // 2. GRID DE INFORMACIÓN (2 COLUMNAS)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: neutralBgSubtle,
                    border: pw.Border.all(color: neutralBorder),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'DATOS DEL CLIENTE',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 9,
                          color: neutralDark,
                        ),
                      ),
                      pw.Divider(color: neutralBorderDark, thickness: 1),
                      pw.SizedBox(height: 4),
                      pw.Text('Razón Social: Corporación Tecnológica C.A.', style: pw.TextStyle(font: baseFont, fontSize: 9, color: neutralDark)),
                      pw.Text('RIF: J-40192837-5', style: pw.TextStyle(font: baseFont, fontSize: 9, color: neutralDark)),
                      pw.Text('Atención: Ing. Alejandro Pérez', style: pw.TextStyle(font: baseFont, fontSize: 9, color: neutralDark)),
                      pw.Text('Teléfono: +58 414 1234567', style: pw.TextStyle(font: baseFont, fontSize: 9, color: neutralDark)),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: neutralBgSubtle,
                    border: pw.Border.all(color: neutralBorder),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'ASESOR COMERCIAL',
                        style: pw.TextStyle(
                          font: boldFont,
                          fontSize: 9,
                          color: neutralDark,
                        ),
                      ),
                      pw.Divider(color: neutralBorderDark, thickness: 1),
                      pw.SizedBox(height: 4),
                      pw.Text('Empresa: Servicios Integrales D-UNA', style: pw.TextStyle(font: baseFont, fontSize: 9, color: neutralDark)),
                      pw.Text('Vendedor: Asesor Técnico Principal', style: pw.TextStyle(font: baseFont, fontSize: 9, color: neutralDark)),
                      pw.Text('Teléfono: +58 412 9876543', style: pw.TextStyle(font: baseFont, fontSize: 9, color: neutralDark)),
                      pw.Text('Email: asesor@d-una.app', style: pw.TextStyle(font: baseFont, fontSize: 9, color: neutralDark)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // 3. TABLA DE ÍTEMS EN NEUTRO
          pw.Table(
            border: pw.TableBorder.all(color: neutralBorder, width: 1),
            columnWidths: {
              0: const pw.FlexColumnWidth(4),
              1: const pw.FlexColumnWidth(1),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
            },
            children: [
              // Header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: neutralBgHeader),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Descripción de Productos / Servicios', style: pw.TextStyle(font: boldFont, fontSize: 8, color: neutralDark)),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Cant.', style: pw.TextStyle(font: boldFont, fontSize: 8, color: neutralDark), textAlign: pw.TextAlign.right),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('P. Unit USD', style: pw.TextStyle(font: boldFont, fontSize: 8, color: neutralDark), textAlign: pw.TextAlign.right),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('Total USD', style: pw.TextStyle(font: boldFont, fontSize: 8, color: neutralDark), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              // Row 1
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Cámara IP Exterior Full HD 1080p', style: pw.TextStyle(font: boldFont, fontSize: 8, color: neutralDark)),
                        pw.Text('Marca: Hikvision - Modelo: DS-2CD2143G0-I', style: pw.TextStyle(font: baseFont, fontSize: 7, color: neutralMuted)),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('4 Und', style: pw.TextStyle(font: baseFont, fontSize: 8), textAlign: pw.TextAlign.right),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('\$65.00', style: pw.TextStyle(font: baseFont, fontSize: 8), textAlign: pw.TextAlign.right),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('\$260.00', style: pw.TextStyle(font: baseFont, fontSize: 8), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              // Row 2
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: neutralBgSubtle),
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('DVR Grabador 8 Canales 4K', style: pw.TextStyle(font: boldFont, fontSize: 8, color: neutralDark)),
                        pw.Text('Marca: Dahua - Modelo: XVR5108HS-X', style: pw.TextStyle(font: baseFont, fontSize: 7, color: neutralMuted)),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('1 Und', style: pw.TextStyle(font: baseFont, fontSize: 8), textAlign: pw.TextAlign.right),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('\$120.00', style: pw.TextStyle(font: baseFont, fontSize: 8), textAlign: pw.TextAlign.right),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('\$120.00', style: pw.TextStyle(font: baseFont, fontSize: 8), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
              // Row 3
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Servicio de Instalación y Configuración', style: pw.TextStyle(font: boldFont, fontSize: 8, color: neutralDark)),
                        pw.Text('Incluye cableado estructurado UTP Cat6 y conectores', style: pw.TextStyle(font: baseFont, fontSize: 7, color: neutralMuted)),
                      ],
                    ),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('1 Serv.', style: pw.TextStyle(font: baseFont, fontSize: 8), textAlign: pw.TextAlign.right),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('\$150.00', style: pw.TextStyle(font: baseFont, fontSize: 8), textAlign: pw.TextAlign.right),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(8),
                    child: pw.Text('\$150.00', style: pw.TextStyle(font: baseFont, fontSize: 8), textAlign: pw.TextAlign.right),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 16),

          // 4. TOTALES
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 220,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: neutralBgSubtle,
                  border: pw.Border.all(color: neutralBorder),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Subtotal:', style: pw.TextStyle(font: baseFont, fontSize: 8, color: neutralMuted)),
                        pw.Text('\$530.00', style: pw.TextStyle(font: baseFont, fontSize: 8, color: neutralDark)),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('IVA (16%):', style: pw.TextStyle(font: baseFont, fontSize: 8, color: neutralMuted)),
                        pw.Text('\$84.80', style: pw.TextStyle(font: baseFont, fontSize: 8, color: neutralDark)),
                      ],
                    ),
                    pw.Divider(color: neutralDark, thickness: 1),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('TOTAL USD:', style: pw.TextStyle(font: boldFont, fontSize: 10, color: neutralDark)),
                        pw.Text('\$614.80', style: pw.TextStyle(font: boldFont, fontSize: 10, color: neutralDark)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          // 5. CONDICIONES
          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: neutralBgSubtle,
              border: pw.Border.all(color: neutralBorder),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('CONDICIONES COMERCIALES', style: pw.TextStyle(font: boldFont, fontSize: 9, color: neutralDark)),
                pw.SizedBox(height: 4),
                pw.Text('• Tiempo de entrega estimado: 3 a 5 días hábiles tras recibir la aprobación.', style: pw.TextStyle(font: baseFont, fontSize: 8, color: neutralMedium)),
                pw.Text('• Forma de Pago: 50% al aprobar la cotización y 50% contra entrega e instalación.', style: pw.TextStyle(font: baseFont, fontSize: 8, color: neutralMedium)),
                pw.Text('• Garantía de equipos: 12 meses contra defectos de fábrica.', style: pw.TextStyle(font: baseFont, fontSize: 8, color: neutralMedium)),
              ],
            ),
          ),
        ];
      },
      footer: (pw.Context context) {
        return pw.Container(
          alignment: pw.Alignment.center,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Sistema Transaccional D-UNA • Cotización Oficial',
            style: pw.TextStyle(font: baseFont, fontSize: 8, color: neutralMuted),
          ),
        );
      },
    ),
  );

  final file = File('firebase_hosting/public/demo_quote.pdf');
  await file.writeAsBytes(await pdf.save());
  print('PDF de demostración generado exitosamente en: ${file.path}');
}
