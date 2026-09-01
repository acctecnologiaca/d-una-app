import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  test('Generate Sample Quote PDF', () async {
    // 1. Color Palette Tokens (Slate Palette)
    const slate900 = PdfColor.fromInt(0xFF0F172A);
    const slate700 = PdfColor.fromInt(0xFF334155);
    const slate500 = PdfColor.fromInt(0xFF64748B);
    const slate300 = PdfColor.fromInt(0xFFCBD5E1);
    const slate200 = PdfColor.fromInt(0xFFE2E8F0);
    const slate100 = PdfColor.fromInt(0xFFF1F5F9);
    const slate50 = PdfColor.fromInt(0xFFF8FAFC);
    const white = PdfColor.fromInt(0xFFFFFFFF);

    final creadoConDUnaBytes = File('assets/images/creado_con_d_una.png').readAsBytesSync();
    final creadoConDUnaImage = pw.MemoryImage(creadoConDUnaBytes);

    final logoBytes = File('assets/images/logo_d_una.png').readAsBytesSync();
    final logoImage = pw.MemoryImage(logoBytes);

    final pdfTheme = pw.ThemeData.withFont(
      base: pw.Font.helvetica(),
      bold: pw.Font.helveticaBold(),
      italic: pw.Font.helveticaOblique(),
      boldItalic: pw.Font.helveticaBoldOblique(),
    );

    final pdf = pw.Document(theme: pdfTheme);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.letter,
        margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        header: (context) => pw.Column(
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.only(bottom: 12),
              decoration: const pw.BoxDecoration(
                border: pw.Border(
                  bottom: pw.BorderSide(color: slate900, width: 2),
                ),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  // Columna Izquierda: Logo / Título + Membrete Emisor
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
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
                                  'COTIZACIÓN',
                                  style: pw.TextStyle(
                                    fontSize: 18,
                                    fontWeight: pw.FontWeight.bold,
                                    color: slate900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'COT-2026-0042   |   22/08/2026',
                                  style: pw.TextStyle(
                                    fontSize: 9,
                                    fontWeight: pw.FontWeight.bold,
                                    color: slate500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          'Tecnología & Soluciones Globales C.A.',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: slate900,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'RIF / ID Fiscal: J-40891234-5',
                          style: const pw.TextStyle(
                            fontSize: 7.5,
                            color: slate500,
                          ),
                        ),
                        pw.Text(
                          'Dirección: Av. Francisco de Miranda, Torre Cavendes, Piso 8, Caracas, Venezuela',
                          style: const pw.TextStyle(
                            fontSize: 7.5,
                            color: slate500,
                          ),
                        ),
                        pw.Text(
                          'Teléfono: +58 (414) 123-4567   |   Email: contacto@tecnologiaglobal.com',
                          style: const pw.TextStyle(
                            fontSize: 7.5,
                            color: slate500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(width: 16),
                  // Columna Derecha: Badge de Validez
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: pw.BoxDecoration(
                      color: slate50,
                      border: pw.Border.all(color: slate300, width: 1),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Text(
                          'Vigente hasta: 06/09/2026',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: slate900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),
          ],
        ),
        footer: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(top: 8),
          child: pw.Stack(
            alignment: pw.Alignment.bottomCenter,
            children: [
              pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  pw.Opacity(
                    opacity: 0.5,
                    child: pw.Container(
                      height: 14,
                      child: pw.Image(creadoConDUnaImage, fit: pw.BoxFit.contain),
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '© 2026',
                    style: const pw.TextStyle(fontSize: 6.5, color: slate500),
                  ),
                ],
              ),
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Text(
                  'Página ${context.pageNumber} de ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 6.5, color: slate500),
                ),
              ),
            ],
          ),
        ),
        build: (context) => [
          // 1. Grilla de Información (2 columnas)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Tarjeta 1: Datos del Cliente
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: slate50,
                    border: pw.Border.all(color: slate200, width: 1),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
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
                            bottom: pw.BorderSide(color: slate300, width: 1.5),
                          ),
                        ),
                        child: pw.Text(
                          'DATOS DEL CLIENTE',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: slate900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      _buildInfoRow(
                        'Razón Social:',
                        'Corporación Industrial del Centro S.A.',
                        slate500,
                        slate900,
                      ),
                      _buildInfoRow('RIF:', 'J-31298456-0', slate500, slate900),
                      _buildInfoRow(
                        'Atención:',
                        'Ing. Carlos Mendoza',
                        slate500,
                        slate900,
                      ),
                      _buildInfoRow(
                        'Teléfono:',
                        '+58 (412) 987-6543',
                        slate500,
                        slate900,
                      ),
                      _buildInfoRow(
                        'Email:',
                        'compras@corping.com',
                        slate500,
                        slate900,
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              // Tarjeta 2: Asesor Comercial
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: slate50,
                    border: pw.Border.all(color: slate200, width: 1),
                    borderRadius: const pw.BorderRadius.all(
                      pw.Radius.circular(8),
                    ),
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
                            bottom: pw.BorderSide(color: slate300, width: 1.5),
                          ),
                        ),
                        child: pw.Text(
                          'ASESOR COMERCIAL',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: slate900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      _buildInfoRow(
                        'Nombre:',
                        'Alejandro Colmenares',
                        slate500,
                        slate900,
                      ),
                      _buildInfoRow(
                        'Teléfono:',
                        '+58 (424) 555-1234',
                        slate500,
                        slate900,
                      ),
                      _buildInfoRow(
                        'Email:',
                        'alejandro@d-una.app',
                        slate500,
                        slate900,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 14),

          // 2. Tabla de Ítems (Productos / Servicios)
          pw.Table(
            border: const pw.TableBorder(
              top: pw.BorderSide(color: slate200, width: 1),
              bottom: pw.BorderSide(color: slate200, width: 1),
              left: pw.BorderSide(color: slate200, width: 1),
              right: pw.BorderSide(color: slate200, width: 1),
              horizontalInside: pw.BorderSide(color: slate200, width: 0.5),
            ),
            columnWidths: const {
              0: pw.FlexColumnWidth(1),
              1: pw.FixedColumnWidth(60),
              2: pw.FixedColumnWidth(48),
              3: pw.FixedColumnWidth(65),
              4: pw.FixedColumnWidth(70),
            },
            children: [
                  // Cabecera de Tabla
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(
                      color: slate100,
                      border: pw.Border(
                        bottom: pw.BorderSide(color: slate300, width: 1.5),
                      ),
                    ),
                    children: [
                      _buildTableHeaderCell(
                        'PRODUCTO / SERVICIO',
                        pw.Alignment.centerLeft,
                        slate900,
                      ),
                      _buildTableHeaderCell(
                        'GARANTÍA',
                        pw.Alignment.center,
                        slate900,
                      ),
                      _buildTableHeaderCell(
                        'CANT.',
                        pw.Alignment.centerRight,
                        slate900,
                      ),
                      _buildTableHeaderCell(
                        'P. UNIT',
                        pw.Alignment.centerRight,
                        slate900,
                      ),
                      _buildTableHeaderCell(
                        'TOTAL',
                        pw.Alignment.centerRight,
                        slate900,
                      ),
                    ],
                  ),
                  // Filas de Datos (con Cebrado)
                  _buildItemRow(
                    name: 'Laptop Dell Latitude 5540 15.6"',
                    subtitle:
                        'Core i7 13va Gen - 16GB RAM - 512GB SSD PCIe NVMe',
                    warranty: '1 Año',
                    quantity: '3 Ud',
                    unitPrice: '\$950.00',
                    totalPrice: '\$2,850.00',
                    isEven: false,
                    slate900: slate900,
                    slate700: slate700,
                    slate500: slate500,
                    slate200: slate200,
                    slate50: slate50,
                    white: white,
                  ),
                  _buildItemRow(
                    name: 'Monitor Dell UltraSharp 27" 4K',
                    subtitle: 'Modelo U2723QE - IPS Black - USB-C Hub 90W PD',
                    warranty: '6 Meses',
                    quantity: '3 Ud',
                    unitPrice: '\$420.00',
                    totalPrice: '\$1,260.00',
                    isEven: true,
                    slate900: slate900,
                    slate700: slate700,
                    slate500: slate500,
                    slate200: slate200,
                    slate50: slate50,
                    white: white,
                  ),
                  _buildItemRow(
                    name: 'Instalación, Configuración e Integración de Red',
                    subtitle:
                        'Puesta en marcha, configuración de dominios corporativos y políticas de seguridad endpoint',
                    warranty: '30 Días',
                    quantity: '1 Serv.',
                    unitPrice: '\$350.00',
                    totalPrice: '\$350.00',
                    isEven: false,
                    slate900: slate900,
                    slate700: slate700,
                    slate500: slate500,
                    slate200: slate200,
                    slate50: slate50,
                    white: white,
                  ),
                ],
              ),

          pw.SizedBox(height: 12),

          // 3. Bloque de Totales (Alineado a la derecha)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 190,
                decoration: pw.BoxDecoration(
                  color: slate50,
                  border: pw.Border.all(color: slate300, width: 1),
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(8),
                  ),
                ),
                child: pw.Column(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'SUB-TOTAL:',
                            style: const pw.TextStyle(
                              fontSize: 7.5,
                              color: slate500,
                            ),
                          ),
                          pw.Text(
                            '\$4,460.00',
                            style: const pw.TextStyle(
                              fontSize: 7.5,
                              color: slate700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'IVA (16%):',
                            style: const pw.TextStyle(
                              fontSize: 7.5,
                              color: slate500,
                            ),
                          ),
                          pw.Text(
                            '\$713.60',
                            style: const pw.TextStyle(
                              fontSize: 7.5,
                              color: slate700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Divisor oscuro del total
                    pw.Container(
                      width: double.infinity,
                      height: 1.5,
                      color: slate900,
                    ),
                    // Grand Total
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'TOTAL USD:',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                              color: slate900,
                            ),
                          ),
                          pw.Text(
                            '\$5,173.60',
                            style: pw.TextStyle(
                              fontSize: 9.5,
                              fontWeight: pw.FontWeight.bold,
                              color: slate900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 12),

          // 4. Condiciones Comerciales y Observaciones
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              color: slate50,
              border: pw.Border.all(color: slate200, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'CONDICIONES COMERCIALES Y OBSERVACIONES',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: slate900,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 6),
                _buildBulletPoint(
                  'Validez de la oferta: 15 días continuos a partir de su emisión (Válida hasta el 06/09/2026).',
                  slate700,
                ),
                _buildBulletPoint(
                  'Forma de pago: 50% anticipo para confirmación de pedido y 50% contra entrega.',
                  slate700,
                ),
                _buildBulletPoint(
                  'Tiempo estimado de entrega: 3 a 5 días hábiles tras confirmación del anticipo.',
                  slate700,
                ),
                _buildBulletPoint(
                  'Precios no incluyen flete fuera del área metropolitana de Caracas.',
                  slate700,
                ),
                pw.SizedBox(height: 6),
                pw.RichText(
                  text: pw.TextSpan(
                    children: [
                      pw.TextSpan(
                        text: 'Notas adicionales: ',
                        style: pw.TextStyle(
                          fontSize: 7.5,
                          fontWeight: pw.FontWeight.bold,
                          color: slate900,
                        ),
                      ),
                      const pw.TextSpan(
                        text:
                            'Equipos originales en caja sellada con garantía directa de fabricante y soporte técnico local.',
                        style: pw.TextStyle(fontSize: 7.5, color: slate700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();

    // Guardar en public de firebase hosting y en scratch para acceso directo
    final fileFirebase = File(
      'firebase_hosting/public/sample_quote_homologado.pdf',
    );
    await fileFirebase.writeAsBytes(bytes);

    final fileWorkspace = File('scratch/sample_quote_homologado.pdf');
    await fileWorkspace.create(recursive: true);
    await fileWorkspace.writeAsBytes(bytes);
    // PDF Generado con éxito en firebase_hosting/public/ y scratch/
  });
}

pw.Widget _buildInfoRow(
  String label,
  String value,
  PdfColor labelColor,
  PdfColor valColor,
) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 65,
          child: pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 7.5,
              fontWeight: pw.FontWeight.bold,
              color: labelColor,
            ),
          ),
        ),
        pw.Expanded(
          child: pw.Text(
            value,
            style: pw.TextStyle(fontSize: 7.5, color: valColor),
          ),
        ),
      ],
    ),
  );
}

pw.Widget _buildTableHeaderCell(
  String text,
  pw.Alignment alignment,
  PdfColor color,
) {
  return pw.Container(
    alignment: alignment,
    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 7,
        fontWeight: pw.FontWeight.bold,
        color: color,
        letterSpacing: 0.5,
      ),
    ),
  );
}

pw.TableRow _buildItemRow({
  required String name,
  required String subtitle,
  required String warranty,
  required String quantity,
  required String unitPrice,
  required String totalPrice,
  required bool isEven,
  bool isLast = false,
  required PdfColor slate900,
  required PdfColor slate700,
  required PdfColor slate500,
  required PdfColor slate200,
  required PdfColor slate50,
  required PdfColor white,
}) {
  return pw.TableRow(
    decoration: pw.BoxDecoration(
      color: isEven ? slate50 : white,
      border: isLast
          ? null
          : pw.Border(bottom: pw.BorderSide(color: slate200, width: 0.5)),
    ),
    children: [
      // Producto / Descripción
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              name,
              style: pw.TextStyle(
                fontSize: 7.5,
                fontWeight: pw.FontWeight.bold,
                color: slate900,
              ),
            ),
            pw.SizedBox(height: 1),
            pw.Text(
              subtitle,
              style: pw.TextStyle(fontSize: 6.5, color: slate500),
            ),
          ],
        ),
      ),
      // Garantía
      pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: pw.Text(
          warranty,
          style: pw.TextStyle(fontSize: 7.5, color: slate700),
        ),
      ),
      // Cantidad
      pw.Container(
        alignment: pw.Alignment.centerRight,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(
          quantity,
          style: pw.TextStyle(fontSize: 7.5, color: slate700),
        ),
      ),
      // P. Unit
      pw.Container(
        alignment: pw.Alignment.centerRight,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(
          unitPrice,
          style: pw.TextStyle(fontSize: 7.5, color: slate700),
        ),
      ),
      // Total
      pw.Container(
        alignment: pw.Alignment.centerRight,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(
          totalPrice,
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: slate900,
          ),
        ),
      ),
    ],
  );
}

pw.Widget _buildBulletPoint(String text, PdfColor color) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2.5),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          margin: const pw.EdgeInsets.only(top: 3, right: 5),
          width: 3,
          height: 3,
          decoration: pw.BoxDecoration(color: color, shape: pw.BoxShape.circle),
        ),
        pw.Expanded(
          child: pw.Text(
            text,
            style: pw.TextStyle(fontSize: 7.5, color: color),
          ),
        ),
      ],
    ),
  );
}
