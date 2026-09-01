import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../pdf_theme.dart';
import '../pdf_helpers.dart';
import '../pdf_common_sections.dart';
import '../../../features/supplier_orders/domain/models/supplier_order.dart';
import '../../../features/supplier_orders/domain/models/supplier_order_item.dart';
import '../../../features/profile/domain/models/user_profile.dart';
import '../../../features/settings/data/models/shipping_method.dart';
import '../../../features/collaborators/domain/models/collaborator.dart';

class SupplierOrderPdfTemplate {
  final SupplierOrder order;
  final List<SupplierOrderItem> items;
  final UserProfile userProfile;
  final String? userEmail;
  final ShippingMethod? shippingMethod;
  final Collaborator? receiverCollaborator;

  SupplierOrderPdfTemplate({
    required this.order,
    required this.items,
    required this.userProfile,
    this.userEmail,
    this.shippingMethod,
    this.receiverCollaborator,
  });

  Future<Uint8List> generate(PdfPageFormat format) async {
    try {
      // 0. Validación de Seguridad
      if (order.id.isEmpty) {
        return _buildErrorDocument('Datos de la orden de compra incompletos.');
      }

      final pdf = pw.Document(theme: PdfThemeConfig.buildTheme());

      // Resolver info del comprador (senderInfo)
      final senderInfo = PdfHelpers.resolvePdfSenderInfo(userProfile, userEmail);

      // Cargar logo si existe (o logo por defecto, con timeout de seguridad)
      pw.MemoryImage? logoImage = await PdfHelpers.loadNetworkImage(senderInfo.logoUrl);
      logoImage ??= await PdfHelpers.loadAssetImage('assets/images/logo_d_una.png');

      // Cargar imagen de marca para el footer
      final footerImage = await PdfHelpers.loadAssetImage(
        'assets/images/creado_con_d_una.png',
      );

      pdf.addPage(
        pw.MultiPage(
          pageFormat: format,
          margin: const pw.EdgeInsets.symmetric(
            horizontal: PdfThemeConfig.horizontalMargin,
            vertical: PdfThemeConfig.verticalMargin,
          ),
          header: (context) => PdfCommonSections.buildLetterhead(
            title: 'ORDEN DE COMPRA',
            documentNumber: order.orderNumber,
            date: order.date,
            senderInfo: senderInfo,
            logoImage: logoImage,
          ),
          footer: (context) =>
              PdfCommonSections.buildFooter(context, footerLogoImage: footerImage),
          build: (context) => [
            // 1. Grilla de Información (Proveedor + Condiciones de Envío)
            _buildInfoGrid(),
            pw.SizedBox(height: 14),

            // 2. Tabla de Productos (con Desglose por Sucursales)
            _buildItemsTable(),
            pw.SizedBox(height: 12),

            // 3. Totales y Condiciones de Pago (2 Columnas)
            _buildTotalsAndPaymentBlock(),
          ],
        ),
      );

      return await pdf.save();
    } catch (e, stack) {
      debugPrint('Error generating SupplierOrder PDF: $e\n$stack');
      return _buildErrorDocument('Error al generar PDF: $e');
    }
  }

  Future<Uint8List> _buildErrorDocument(String message) async {
    final errorPdf = pw.Document(theme: PdfThemeConfig.buildTheme());
    errorPdf.addPage(
      pw.Page(
        build: (context) => pw.Center(
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(24),
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  'No se pudo generar el documento PDF',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfThemeConfig.slate900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  message,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfThemeConfig.slate500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    return errorPdf.save();
  }

  /// Grilla de 2 columnas: Datos del Proveedor y Condiciones de Entrega / Envío
  pw.Widget _buildInfoGrid() {
    final companyName = shippingMethod?.company?.name ??
        shippingMethod?.company?.legalName ??
        '-';
    final deliveryOption = shippingMethod?.deliveryOption ?? order.shippingMethodLabel ?? 'Por definir';

    final isPersonalPickup = deliveryOption.toLowerCase().contains('retiro en persona') ||
        deliveryOption.toLowerCase().contains('retiro personal');

    final isBranchDelivery = deliveryOption.toLowerCase().contains('sucursal');
    final showBranchCode = isBranchDelivery &&
        shippingMethod?.branchCode != null &&
        shippingMethod!.branchCode!.trim().isNotEmpty;

    final addressParts = <String>[];
    if (shippingMethod != null) {
      if (shippingMethod!.useMainAddress) {
        final mainAddr = userProfile.companyAddress ?? userProfile.mainAddress;
        if (mainAddr != null && mainAddr.trim().isNotEmpty) {
          addressParts.add(mainAddr.trim());
        }
      } else {
        if (shippingMethod!.address != null && shippingMethod!.address!.trim().isNotEmpty) {
          addressParts.add(shippingMethod!.address!.trim());
        }
        if (shippingMethod!.city != null && shippingMethod!.city!.trim().isNotEmpty) {
          addressParts.add(shippingMethod!.city!.trim());
        }
        if (shippingMethod!.state != null && shippingMethod!.state!.trim().isNotEmpty) {
          addressParts.add(shippingMethod!.state!.trim());
        }
      }
    }
    final fullDeliveryAddress = addressParts.isNotEmpty ? addressParts.join(', ') : '-';

    final receiverName = receiverCollaborator?.fullName ?? order.receiverName;
    final receiverId = receiverCollaborator?.identificationId;
    final receiverPhone = receiverCollaborator?.phone;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Tarjeta 1: Datos del Proveedor
        pw.Expanded(
          child: PdfCommonSections.buildInfoCard(
            title: 'DATOS DEL PROVEEDOR',
            children: [
              PdfCommonSections.buildInfoRow(
                'Razón Social / Nombre:',
                order.supplierName,
              ),
              if (order.branchName != null && order.branchName!.trim().isNotEmpty)
                PdfCommonSections.buildInfoRow('Sucursal:', order.branchName!),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        // Tarjeta 2: Condiciones de Entrega / Envío
        pw.Expanded(
          child: PdfCommonSections.buildInfoCard(
            title: 'CONDICIONES DE ENTREGA / ENVÍO',
            children: [
              PdfCommonSections.buildInfoRow('Modalidad:', deliveryOption),
              if (!isPersonalPickup) ...[
                if (companyName != '-')
                  PdfCommonSections.buildInfoRow('Empresa de Envío:', companyName),
                if (showBranchCode)
                  PdfCommonSections.buildInfoRow('Código Sucursal:', shippingMethod!.branchCode!.trim()),
                if (fullDeliveryAddress != '-')
                  PdfCommonSections.buildInfoRow('Dirección de Entrega:', fullDeliveryAddress),
              ],
              if (receiverName != null && receiverName.trim().isNotEmpty && receiverName != '-') ...[
                pw.SizedBox(height: 4),
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.only(top: 4, bottom: 2),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(top: pw.BorderSide(color: PdfThemeConfig.slate200, width: 0.8)),
                  ),
                  child: pw.Text(
                    'Persona Autorizada',
                    style: pw.TextStyle(
                      fontSize: 7,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfThemeConfig.slate700,
                    ),
                  ),
                ),
                PdfCommonSections.buildInfoRow('Nombre:', receiverName),
                if (receiverId != null && receiverId.isNotEmpty && receiverId != '-')
                  PdfCommonSections.buildInfoRow('C.I. / ID:', receiverId),
                if (receiverPhone != null && receiverPhone.isNotEmpty && receiverPhone != '-')
                  PdfCommonSections.buildInfoRow('Teléfono:', receiverPhone),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Tabla de Productos (con Desglose por Sucursales)
  pw.Widget _buildItemsTable() {
    // 1. Agrupar ítems si comparten producto / modelo / marca
    final itemsMap = <String, List<SupplierOrderItem>>{};
    for (var item in items) {
      final key = '${item.name}|${item.model ?? ''}|${item.brand ?? ''}';
      itemsMap.putIfAbsent(key, () => []).add(item);
    }

    final rows = <pw.TableRow>[
      pw.TableRow(
        decoration: const pw.BoxDecoration(
          color: PdfThemeConfig.slate100,
          border: pw.Border(
            bottom: pw.BorderSide(color: PdfThemeConfig.slate300, width: 1.5),
          ),
        ),
        children: [
          PdfCommonSections.buildTableHeaderCell('PRODUCTO', pw.Alignment.centerLeft),
          PdfCommonSections.buildTableHeaderCell('CANT.', pw.Alignment.center),
          PdfCommonSections.buildTableHeaderCell('P. UNIT', pw.Alignment.centerRight),
          PdfCommonSections.buildTableHeaderCell('TOTAL', pw.Alignment.centerRight),
        ],
      ),
    ];

    int rowIndex = 0;

    for (var group in itemsMap.values) {
      final first = group.first;
      final totalQty = group.fold<double>(0.0, (sum, it) => sum + it.quantity);
      final totalPrice = group.fold<double>(0.0, (sum, it) => sum + it.total);

      final hasModel = first.model != null && first.model!.trim().isNotEmpty;
      final productTitle = hasModel ? '[${first.model!.trim()}] ${first.name}' : first.name;

      final branchLines = group.map((it) {
        final bName = it.branchName ?? 'Sucursal Principal';
        final qtyStr = it.quantity % 1 == 0 ? it.quantity.toInt().toString() : it.quantity.toStringAsFixed(2);
        return '- $bName: $qtyStr ${it.uom}';
      }).toList();

      final isEven = rowIndex % 2 == 1;
      rowIndex++;

      final totalQtyStr = totalQty % 1 == 0 ? '${totalQty.toInt()} Ud' : '${totalQty.toStringAsFixed(2)} Ud';

      rows.add(
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: isEven ? PdfThemeConfig.slate50 : PdfThemeConfig.white,
            border: const pw.Border(
              bottom: pw.BorderSide(color: PdfThemeConfig.slate200, width: 0.5),
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
                    productTitle,
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfThemeConfig.slate900,
                    ),
                  ),
                  if (first.brand != null && first.brand!.trim().isNotEmpty) ...[
                    pw.SizedBox(height: 1),
                    pw.Text(
                      'Marca: ${first.brand}',
                      style: const pw.TextStyle(fontSize: 6.5, color: PdfThemeConfig.slate500),
                    ),
                  ],
                  if (branchLines.isNotEmpty) ...[
                    pw.SizedBox(height: 2),
                    ...branchLines.map(
                      (line) => pw.Text(
                        line,
                        style: const pw.TextStyle(fontSize: 6.5, color: PdfThemeConfig.slate700),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Cantidad Total
            pw.Container(
              alignment: pw.Alignment.center,
              padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 6),
              child: pw.Text(
                totalQtyStr,
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfThemeConfig.slate900,
                ),
              ),
            ),
            // P. Unit
            pw.Container(
              alignment: pw.Alignment.centerRight,
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              child: pw.Text(
                PdfHelpers.formatCurrency(first.unitPrice),
                style: const pw.TextStyle(fontSize: 7.5, color: PdfThemeConfig.slate700),
              ),
            ),
            // Total
            pw.Container(
              alignment: pw.Alignment.centerRight,
              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: pw.Text(
                PdfHelpers.formatCurrency(totalPrice),
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfThemeConfig.slate900,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return pw.Table(
      border: const pw.TableBorder(
        top: pw.BorderSide(color: PdfThemeConfig.slate200, width: 1),
        bottom: pw.BorderSide(color: PdfThemeConfig.slate200, width: 1),
        left: pw.BorderSide(color: PdfThemeConfig.slate200, width: 1),
        right: pw.BorderSide(color: PdfThemeConfig.slate200, width: 1),
        horizontalInside: pw.BorderSide(color: PdfThemeConfig.slate200, width: 0.5),
      ),
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FixedColumnWidth(55),
        2: pw.FixedColumnWidth(75),
        3: pw.FixedColumnWidth(80),
      },
      children: rows,
    );
  }

  /// Grilla de Totales y Condiciones de Pago (2 Columnas)
  pw.Widget _buildTotalsAndPaymentBlock() {
    final subtotal = order.subtotal;
    final tax = order.tax;
    final total = order.total;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Columna Izquierda: Condiciones de Pago
        pw.Expanded(
          child: PdfCommonSections.buildInfoCard(
            title: 'CONDICIONES DE PAGO',
            children: [
              if (order.paymentMethod != null && order.paymentMethod!.isNotEmpty)
                PdfCommonSections.buildInfoRow('Método de Pago:', order.paymentMethod!),
              PdfCommonSections.buildInfoRow(
                'Términos:',
                '100% anticipado contra emisión de factura fiscal',
              ),
            ],
          ),
        ),
        pw.SizedBox(width: 12),
        // Columna Derecha: Tarjeta de Totales
        pw.Container(
          width: 190,
          decoration: pw.BoxDecoration(
            color: PdfThemeConfig.slate50,
            border: pw.Border.all(color: PdfThemeConfig.slate300, width: 1),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'SUB-TOTAL:',
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfThemeConfig.slate500,
                      ),
                    ),
                    pw.Text(
                      PdfHelpers.formatCurrency(subtotal),
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfThemeConfig.slate700,
                      ),
                    ),
                  ],
                ),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'IVA (16%):',
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfThemeConfig.slate500,
                      ),
                    ),
                    pw.Text(
                      PdfHelpers.formatCurrency(tax),
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfThemeConfig.slate700,
                      ),
                    ),
                  ],
                ),
              ),
              // Divisor oscuro del total
              pw.Container(
                width: double.infinity,
                height: 1.5,
                color: PdfThemeConfig.slate900,
              ),
              // Grand Total
              pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL USD:',
                      style: PdfThemeConfig.grandTotalStyle,
                    ),
                    pw.Text(
                      PdfHelpers.formatCurrency(total),
                      style: PdfThemeConfig.grandTotalStyle,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
