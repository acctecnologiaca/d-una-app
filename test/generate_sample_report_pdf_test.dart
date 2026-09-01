import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  test('Generate Sample Service Report PDF', () async {
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
                  // Columna Izquierda: Título + Membrete Emisor
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
                                  'REPORTE DE SERVICIO',
                                  style: pw.TextStyle(
                                    fontSize: 18,
                                    fontWeight: pw.FontWeight.bold,
                                    color: slate900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'RS-2026-0018   |   22/08/2026',
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
                          'Servicios & Soluciones Técnicas Globales C.A.',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: slate900,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'RIF / ID Fiscal: J-40891234-5',
                          style: const pw.TextStyle(fontSize: 7.5, color: slate500),
                        ),
                        pw.Text(
                          'Dirección: Av. Francisco de Miranda, Torre Cavendes, Piso 8, Caracas, Venezuela',
                          style: const pw.TextStyle(fontSize: 7.5, color: slate500),
                        ),
                        pw.Text(
                          'Teléfono: +58 (414) 123-4567   |   Email: contacto@tecnologiaglobal.com',
                          style: const pw.TextStyle(fontSize: 7.5, color: slate500),
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
          // 1. Grilla de Información: Cliente + Detalles del Servicio (2 columnas)
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
                      _buildInfoRow('Razón Social:', 'Inversiones Las Mercedes C.A.', slate500, slate900),
                      _buildInfoRow('RIF:', 'J-29834712-4', slate500, slate900),
                      _buildInfoRow('Atención:', 'Lic. Roberto Morales', slate500, slate900),
                      _buildInfoRow('Teléfono:', '+58 (412) 555-9876', slate500, slate900),
                      _buildInfoRow('Email:', 'operaciones@lasmercedes.com', slate500, slate900),
                      _buildInfoRow('Dirección:', 'Calle Paris con Madrid, Edif. Centro, Local 2, Caracas', slate500, slate900),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              // Tarjeta 2: Detalles del Servicio
              pw.Expanded(
                child: pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: slate50,
                    border: pw.Border.all(color: slate200, width: 1),
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
                            bottom: pw.BorderSide(color: slate300, width: 1.5),
                          ),
                        ),
                        child: pw.Text(
                          'DETALLES DEL SERVICIO',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: slate900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      _buildInfoRow('Tipo de servicio:', 'Mantenimiento Correctivo', slate500, slate900),
                      _buildInfoRow('Categoría:', 'Sistemas de Climatización y Refrigeración', slate500, slate900),
                      _buildInfoRow('Técnico responsable:', 'Ing. Alejandro Colmenares', slate500, slate900),
                      _buildInfoRow('Horario / Duración:', '08:30 AM - 12:00 PM (210 min)', slate500, slate900),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 14),

          // 2. Tarjeta Estructurada de INFORME TÉCNICO (Idéntica al WebView report.html)
          pw.Container(
            decoration: pw.BoxDecoration(
              color: slate50,
              border: pw.Border.all(color: slate200, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.ClipRRect(
              horizontalRadius: 7,
              verticalRadius: 7,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Cabecera del Informe Técnico
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: const pw.BoxDecoration(
                      color: slate100,
                      border: pw.Border(
                        bottom: pw.BorderSide(color: slate300, width: 1.5),
                      ),
                    ),
                    child: pw.Text(
                      'INFORME TÉCNICO',
                      style: pw.TextStyle(
                        fontSize: 8,
                        fontWeight: pw.FontWeight.bold,
                        color: slate900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                // Contenido del Informe en Cajas Blancas
                pw.Padding(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      _buildTechnicalSection(
                        title: 'REQUERIMIENTO O FALLA REPORTADA',
                        content: 'Equipo de aire acondicionado central de 5TR presenta ruido anormal en compresor y deficiencia de enfriamiento en el área de servidores.',
                        slate900: slate900,
                        slate700: slate700,
                        slate300: slate300,
                        slate200: slate200,
                        white: white,
                      ),
                      pw.SizedBox(height: 8),
                      _buildTechnicalSection(
                        title: 'DIAGNÓSTICO Y/O TRABAJO REALIZADO',
                        content: 'Se realizó revisión integral del circuito frigorífico. Se detectó fuga en válvula de servicio de alta presión y capacitor de arranque desvalorizado. Se ejecutó corrección de fuga, presurización con nitrógeno, vacío a 500 micrones, recarga completa de refrigerante R410A y reemplazo de capacitor.',
                        slate900: slate900,
                        slate700: slate700,
                        slate300: slate300,
                        slate200: slate200,
                        white: white,
                      ),
                      pw.SizedBox(height: 8),
                      _buildTechnicalSection(
                        title: 'RECOMENDACIONES',
                        content: 'Se recomienda programar el siguiente mantenimiento preventivo en 90 días y mantener limpia la rejilla perimetral de la unidad condensadora exterior.',
                        slate900: slate900,
                        slate700: slate700,
                        slate300: slate300,
                        slate200: slate200,
                        white: white,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

          pw.SizedBox(height: 14),

          // 3. Tabla Unificada de Ítems (Servicios + Repuestos)
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
                      _buildTableHeaderCell('PRODUCTO / SERVICIO', pw.Alignment.centerLeft, slate900),
                      _buildTableHeaderCell('GARANTÍA', pw.Alignment.center, slate900),
                      _buildTableHeaderCell('CANT.', pw.Alignment.centerRight, slate900),
                      _buildTableHeaderCell('P. UNIT', pw.Alignment.centerRight, slate900),
                      _buildTableHeaderCell('TOTAL', pw.Alignment.centerRight, slate900),
                    ],
                  ),
                  // Filas de Datos (con Cebrado: Productos primero, luego Servicios)
                  _buildItemRow(
                    name: 'Capacitor de Arranque Dual 60/5 uF 450VAC',
                    subtitle: 'Titan Pro - Heavy Duty Industrial',
                    warranty: '6 Meses',
                    quantity: '1 Ud',
                    unitPrice: '\$35.00',
                    totalPrice: '\$35.00',
                    isEven: false,
                    slate900: slate900,
                    slate700: slate700,
                    slate500: slate500,
                    slate200: slate200,
                    slate50: slate50,
                    white: white,
                  ),
                  _buildItemRow(
                    name: 'Refrigerante Ecológico R410A Virgen (Carga Completa)',
                    subtitle: 'Gas de alta pureza certificado (2.8 Kg)',
                    warranty: '---',
                    quantity: '1 Ud',
                    unitPrice: '\$65.00',
                    totalPrice: '\$65.00',
                    isEven: true,
                    slate900: slate900,
                    slate700: slate700,
                    slate500: slate500,
                    slate200: slate200,
                    slate50: slate50,
                    white: white,
                  ),
                  _buildItemRow(
                    name: 'Mantenimiento y Corrección de Fuga en Unidad Central',
                    subtitle: 'Presurización con nitrógeno, vacío profundo y recarga de refrigerante ecológico R410A',
                    warranty: '60 Días',
                    quantity: '1 Serv.',
                    unitPrice: '\$180.00',
                    totalPrice: '\$180.00',
                    isEven: false,
                    isLast: true,
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

          // 4. Bloque de Totales (Alineado a la derecha)
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 190,
                decoration: pw.BoxDecoration(
                  color: slate50,
                  border: pw.Border.all(color: slate300, width: 1),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Column(
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('SUB-TOTAL:', style: const pw.TextStyle(fontSize: 7.5, color: slate500)),
                          pw.Text('\$280.00', style: const pw.TextStyle(fontSize: 7.5, color: slate700)),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('IVA (16%):', style: const pw.TextStyle(fontSize: 7.5, color: slate500)),
                          pw.Text('\$44.80', style: const pw.TextStyle(fontSize: 7.5, color: slate700)),
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
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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
                            '\$324.80',
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

          // 5. Términos y Condiciones de Garantía
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
                  'TÉRMINOS Y CONDICIONES DE GARANTÍA',
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: slate900,
                    letterSpacing: 0.5,
                  ),
                ),
                pw.SizedBox(height: 6),
                _buildBulletPoint('La garantía cubre exclusivamente la mano de obra realizada y repuestos suministrados especificados en este reporte.', slate700),
                _buildBulletPoint('No cubre fallas ocasionadas por fluctuaciones eléctricas, mala manipulación de terceros o causas de fuerza mayor.', slate700),
                _buildBulletPoint('Cualquier reclamo debe ser notificado dentro del lapso de garantía especificado adjuntando el número de reporte.', slate700),
              ],
            ),
          ),
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();

    final fileFirebase = File('firebase_hosting/public/sample_report_homologado.pdf');
    await fileFirebase.writeAsBytes(bytes);

    final fileWorkspace = File('scratch/sample_report_homologado.pdf');
    await fileWorkspace.create(recursive: true);
    await fileWorkspace.writeAsBytes(bytes);
    // PDF Generado con éxito
  });
}

pw.Widget _buildTechnicalSection({
  required String title,
  required String content,
  required PdfColor slate900,
  required PdfColor slate700,
  required PdfColor slate300,
  required PdfColor slate200,
  required PdfColor white,
}) {
  return pw.Container(
    width: double.infinity,
    padding: const pw.EdgeInsets.all(8),
    decoration: pw.BoxDecoration(
      color: white,
      border: pw.Border.all(color: slate200, width: 1),
      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.only(bottom: 3),
          margin: const pw.EdgeInsets.only(bottom: 4),
          decoration: pw.BoxDecoration(
            border: pw.Border(bottom: pw.BorderSide(color: slate300, width: 1)),
          ),
          child: pw.Text(
            title,
            style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: slate900, letterSpacing: 0.4),
          ),
        ),
        pw.Text(
          content,
          style: pw.TextStyle(fontSize: 7.5, color: slate700, lineSpacing: 1.2),
        ),
      ],
    ),
  );
}

pw.Widget _buildInfoRow(String label, String value, PdfColor labelColor, PdfColor valColor) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 85,
          child: pw.Text(
            label,
            style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: labelColor),
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

pw.Widget _buildTableHeaderCell(String text, pw.Alignment alignment, PdfColor color) {
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
      border: isLast ? null : pw.Border(
        bottom: pw.BorderSide(color: slate200, width: 0.5),
      ),
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
              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: slate900),
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
        child: pw.Text(warranty, style: pw.TextStyle(fontSize: 7.5, color: slate700)),
      ),
      // Cantidad
      pw.Container(
        alignment: pw.Alignment.centerRight,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(quantity, style: pw.TextStyle(fontSize: 7.5, color: slate700)),
      ),
      // P. Unit
      pw.Container(
        alignment: pw.Alignment.centerRight,
        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        child: pw.Text(unitPrice, style: pw.TextStyle(fontSize: 7.5, color: slate700)),
      ),
      // Total
      pw.Container(
        alignment: pw.Alignment.centerRight,
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Text(
          totalPrice,
          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: slate900),
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
          decoration: pw.BoxDecoration(
            color: color,
            shape: pw.BoxShape.circle,
          ),
        ),
        pw.Expanded(
          child: pw.Text(text, style: pw.TextStyle(fontSize: 7.5, color: color)),
        ),
      ],
    ),
  );
}
