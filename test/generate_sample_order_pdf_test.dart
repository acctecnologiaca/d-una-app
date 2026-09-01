import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  test('Generate Sample Supplier Order PDF', () async {
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
                  // Columna Izquierda: Título + Membrete Comprador
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
                                  'ORDEN DE COMPRA',
                                  style: pw.TextStyle(
                                    fontSize: 18,
                                    fontWeight: pw.FontWeight.bold,
                                    color: slate900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  'OC-2026-0031   |   22/08/2026',
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
                          style: const pw.TextStyle(fontSize: 7.5, color: slate500),
                        ),
                        pw.Text(
                          'Dirección: Av. Francisco de Miranda, Torre Cavendes, Piso 8, Caracas, Venezuela',
                          style: const pw.TextStyle(fontSize: 7.5, color: slate500),
                        ),
                        pw.Text(
                          'Teléfono: +58 (414) 123-4567   |   Email: compras@tecnologiaglobal.com',
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
          // 1. Grilla de Información: Proveedor + Condiciones de Entrega / Envío (2 columnas)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Tarjeta 1: Datos del Proveedor
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
                          'DATOS DEL PROVEEDOR',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: slate900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      _buildInfoRow('Razón Social / Nombre:', 'Distribuidora Tech Mayorista C.A.', slate500, slate900),
                      _buildInfoRow('RIF / ID Fiscal:', 'J-30948512-3', slate500, slate900),
                      _buildInfoRow('Teléfono:', '+58 (212) 234-5678', slate500, slate900),
                      _buildInfoRow('Email:', 'ventas@techmayorista.com', slate500, slate900),
                      _buildInfoRow('Sucursal:', 'Sede Principal Caracas', slate500, slate900),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              // Tarjeta 2: Condiciones de Entrega / Envío y Persona Autorizada
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
                          'CONDICIONES DE ENTREGA / ENVÍO',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: slate900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      _buildInfoRow('Modalidad:', 'Envío a Agencia con Cobro en Destino', slate500, slate900),
                      _buildInfoRow('Empresa de Envío:', 'MRW Envíos Express', slate500, slate900),
                      _buildInfoRow('Código Sucursal:', 'CCS-042 (Agencia Chacao)', slate500, slate900),
                      _buildInfoRow('Dirección de Entrega:', 'Av. Francisco de Miranda, Edif. Centro Plaza, Nivel PB', slate500, slate900),
                      pw.SizedBox(height: 4),
                      pw.Container(
                        width: double.infinity,
                        padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
                        decoration: const pw.BoxDecoration(
                          border: pw.Border(top: pw.BorderSide(color: slate200, width: 0.8)),
                        ),
                        child: pw.Text(
                          'Persona Autorizada',
                          style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: slate700),
                        ),
                      ),
                      _buildInfoRow('Nombre:', 'Marcos Aurelio Pérez', slate500, slate900),
                      _buildInfoRow('C.I. / ID:', 'V-18.456.789', slate500, slate900),
                      _buildInfoRow('Teléfono:', '+58 (412) 345-6789', slate500, slate900),
                    ],
                  ),
                ),
              ),
            ],
          ),

          pw.SizedBox(height: 14),

          // 2. Tabla de Productos (con Desglose por Sucursales)
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
              1: pw.FixedColumnWidth(55),
              2: pw.FixedColumnWidth(75),
              3: pw.FixedColumnWidth(80),
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
                  _buildTableHeaderCell('PRODUCTO', pw.Alignment.centerLeft, slate900),
                  _buildTableHeaderCell('CANT.', pw.Alignment.center, slate900),
                  _buildTableHeaderCell('P. UNIT', pw.Alignment.centerRight, slate900),
                  _buildTableHeaderCell('TOTAL', pw.Alignment.centerRight, slate900),
                ],
              ),
              // Filas de Datos (con Desglose por Sucursal)
              _buildOrderProductRow(
                title: '[LAT-5540] Laptop Dell Latitude 5540 15.6"',
                brand: 'Dell',
                branchLines: [
                  '- Sede Principal Caracas: 3 Ud',
                  '- Sucursal Valencia: 2 Ud',
                ],
                totalQuantity: '5 Ud',
                unitPrice: '\$820.00',
                totalPrice: '\$4,100.00',
                isEven: false,
                slate900: slate900,
                slate700: slate700,
                slate500: slate500,
                slate200: slate200,
                slate50: slate50,
                white: white,
              ),
              _buildOrderProductRow(
                title: '[U2723QE] Monitor Dell UltraSharp 27" 4K USB-C Hub',
                brand: 'Dell',
                branchLines: [
                  '- Sede Principal Caracas: 2 Ud',
                ],
                totalQuantity: '2 Ud',
                unitPrice: '\$390.00',
                totalPrice: '\$780.00',
                isEven: true,
                slate900: slate900,
                slate700: slate700,
                slate500: slate500,
                slate200: slate200,
                slate50: slate50,
                white: white,
              ),
              _buildOrderProductRow(
                title: '[C920-HD] Cámara Web Logitech C920 HD Pro 1080p',
                brand: 'Logitech',
                branchLines: [
                  '- Sede Principal Caracas: 4 Ud',
                ],
                totalQuantity: '4 Ud',
                unitPrice: '\$75.00',
                totalPrice: '\$300.00',
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

          // 3. Grilla de Totales y Condiciones de Pago (2 Columnas)
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Columna Izquierda: Condiciones de Pago
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
                          'CONDICIONES DE PAGO',
                          style: pw.TextStyle(
                            fontSize: 8,
                            fontWeight: pw.FontWeight.bold,
                            color: slate900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      _buildInfoRow('Método de Pago:', 'Transferencia Bancaria Nacional / Zelle Corporativo', slate500, slate900),
                      _buildInfoRow('Términos:', '100% anticipado contra emisión de factura fiscal', slate500, slate900),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 12),
              // Columna Derecha: Tarjeta de Totales
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
                          pw.Text('\$5,180.00', style: const pw.TextStyle(fontSize: 7.5, color: slate700)),
                        ],
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('IVA (16%):', style: const pw.TextStyle(fontSize: 7.5, color: slate500)),
                          pw.Text('\$828.80', style: const pw.TextStyle(fontSize: 7.5, color: slate700)),
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
                            '\$6,008.80',
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
        ],
      ),
    );

    final Uint8List bytes = await pdf.save();

    final fileFirebase = File('firebase_hosting/public/sample_order_homologado.pdf');
    await fileFirebase.writeAsBytes(bytes);

    final fileWorkspace = File('scratch/sample_order_homologado.pdf');
    await fileWorkspace.create(recursive: true);
    await fileWorkspace.writeAsBytes(bytes);
    // PDF Generado con éxito
  });
}

pw.Widget _buildInfoRow(String label, String value, PdfColor labelColor, PdfColor valColor) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 2),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.SizedBox(
          width: 80,
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

pw.TableRow _buildOrderProductRow({
  required String title,
  required String brand,
  required List<String> branchLines,
  required String totalQuantity,
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
      // Producto / Marca / Sucursales
      pw.Padding(
        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              title,
              style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: slate900),
            ),
            if (brand.isNotEmpty) ...[
              pw.SizedBox(height: 1),
              pw.Text('Marca: $brand', style: pw.TextStyle(fontSize: 6.5, color: slate500)),
            ],
            pw.SizedBox(height: 2),
            ...branchLines.map(
              (line) => pw.Text(line, style: pw.TextStyle(fontSize: 6.5, color: slate700)),
            ),
          ],
        ),
      ),
      // Cantidad Total
      pw.Container(
        alignment: pw.Alignment.center,
        padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: pw.Text(
          totalQuantity,
          style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: slate900),
        ),
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
