import 'package:intl/intl.dart';
import '../models/supplier_order.dart';
import '../models/supplier_order_item.dart';
import '../../../../features/profile/domain/models/user_profile.dart';
import '../../../../features/settings/data/models/shipping_method.dart';
import '../../../../features/collaborators/domain/models/collaborator.dart';

class OcEmailTemplateBuilder {
  static String buildSubject({
    required SupplierOrder order,
    required UserProfile userProfile,
  }) {
    final hasCompany =
        userProfile.companyName != null &&
        userProfile.companyName!.trim().isNotEmpty;
    final userDisplayName = hasCompany
        ? userProfile.companyName!.trim()
        : '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}'.trim();

    return "D-Una - Orden de Compra ${order.orderNumber} - $userDisplayName";
  }

  static String buildHtmlBody({
    required SupplierOrder order,
    required List<SupplierOrderItem> items,
    required UserProfile userProfile,
    required String userEmail,
    required String actionToken,
    required String apiBaseUrl,
    ShippingMethod? shippingMethod,
    Collaborator? receiverCollaborator,
  }) {
    final currencyFormatter = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );
    final dateFormat = DateFormat('dd/MM/yyyy');

    // URL de acción para la Landing Page en Firebase Hosting (Dominio Personalizado)
    const firebaseHostingUrl = 'https://d-una.app/order_response.html';
    final confirmUrl = '$firebaseHostingUrl?token=$actionToken&action=confirm';
    final rejectUrl = '$firebaseHostingUrl?token=$actionToken&action=reject';

    // Fecha y Ciudad
    final formattedDate = dateFormat.format(order.date);
    final locationDateStr =
        (userProfile.mainCity != null &&
            userProfile.mainCity!.trim().isNotEmpty)
        ? '${userProfile.mainCity!.trim()}, $formattedDate'
        : formattedDate;

    // Datos del Usuario Emisor (Empresa vs Persona Natural)
    final hasCompany =
        userProfile.companyName != null &&
        userProfile.companyName!.trim().isNotEmpty;
    final userDisplayName = hasCompany
        ? userProfile.companyName!.trim()
        : '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}'.trim();
    final userContactName =
        '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}'.trim();
    final userIdOrRif = hasCompany
        ? (userProfile.companyRif ?? '-')
        : (userProfile.nationalId ?? '-');
    final userAddress = hasCompany
        ? (userProfile.companyAddress ?? '-')
        : ([
            userProfile.mainAddress,
            userProfile.mainCity,
          ].where((e) => e != null && e.trim().isNotEmpty).join(', '));

    // Detalles del Método de Envío
    final companyName =
        shippingMethod?.company?.name ??
        shippingMethod?.company?.legalName ??
        '-';
    final deliveryOption = shippingMethod?.deliveryOption ?? '-';
    final isBranchDelivery = deliveryOption.toLowerCase().contains('sucursal');
    final branchCodeStr = shippingMethod?.branchCode?.trim();
    final showBranchCode =
        isBranchDelivery && branchCodeStr != null && branchCodeStr.isNotEmpty;

    final addressParts = <String>[];
    if (shippingMethod != null) {
      if (shippingMethod.useMainAddress) {
        if (userProfile.companyAddress != null &&
            userProfile.companyAddress!.trim().isNotEmpty) {
          addressParts.add(userProfile.companyAddress!.trim());
        }
      } else {
        if (shippingMethod.address != null &&
            shippingMethod.address!.trim().isNotEmpty) {
          addressParts.add(shippingMethod.address!.trim());
        }
        if (shippingMethod.city != null &&
            shippingMethod.city!.trim().isNotEmpty) {
          addressParts.add(shippingMethod.city!.trim());
        }
        if (shippingMethod.state != null &&
            shippingMethod.state!.trim().isNotEmpty) {
          addressParts.add(shippingMethod.state!.trim());
        }
      }
    }
    final fullAddress = addressParts.isNotEmpty ? addressParts.join(', ') : '-';
    final isPersonalPickup =
        deliveryOption.toLowerCase().contains('retiro en persona') ||
        deliveryOption.toLowerCase().contains('retiro personal');

    // Persona que retira
    final receiverName =
        receiverCollaborator?.fullName ?? order.receiverName ?? '-';
    final receiverId = receiverCollaborator?.identificationId;
    final receiverPhone = receiverCollaborator?.phone;

    // Agrupar productos por (Nombre + Modelo + Marca)
    final Map<String, List<SupplierOrderItem>> groupedItems = {};
    for (final item in items) {
      final key = '${item.name}|${item.model ?? ''}|${item.brand ?? ''}';
      groupedItems.putIfAbsent(key, () => []).add(item);
    }

    final itemsRowsHtml = groupedItems.values
        .map((group) {
          final firstItem = group.first;
          final totalQuantity = group.fold(
            0.0,
            (sum, item) => sum + item.quantity,
          );
          final totalPrice = group.fold(0.0, (sum, item) => sum + item.total);

          final hasModel =
              firstItem.model != null && firstItem.model!.trim().isNotEmpty;
          final productTitle = hasModel
              ? '[${firstItem.model!.trim()}] ${firstItem.name}'
              : firstItem.name;

          final branchLinesHtml = group
              .map((item) {
                final bName =
                    (item.branchName != null && item.branchName!.isNotEmpty)
                    ? item.branchName!
                    : (order.branchName ?? 'Sucursal principal');
                final qtyStr = item.quantity.toStringAsFixed(
                  item.quantity.truncateToDouble() == item.quantity ? 0 : 2,
                );
                return '&bull; $bName: $qtyStr ${item.uom}';
              })
              .join('<br>');

          final qtyDisplay = totalQuantity.toStringAsFixed(
            totalQuantity.truncateToDouble() == totalQuantity ? 0 : 2,
          );

          return '''
        <tr style="border-bottom: 1px solid #E2E8F0;">
          <td style="padding: 6px 10px; font-size: 12px; color: #2D3748; font-weight: bold; text-align: center; vertical-align: top;">
            $qtyDisplay
          </td>
          <td style="padding: 6px 10px; font-size: 12px; color: #2D3748; vertical-align: top;">
            <strong style="color: #1A202C;">$productTitle</strong><br>
            ${firstItem.brand != null && firstItem.brand!.trim().isNotEmpty ? '<span style="font-size: 10px; color: #718096; font-style: italic;">Marca: ${firstItem.brand}</span><br>' : ''}
            <span style="font-size: 10px; color: #718096; line-height: 1.2;">$branchLinesHtml</span>
          </td>
          <td style="padding: 6px 10px; font-size: 12px; color: #2D3748; text-align: right; vertical-align: top;">
            ${currencyFormatter.format(firstItem.unitPrice)}
          </td>
          <td style="padding: 6px 10px; font-size: 12px; color: #1A202C; font-weight: bold; text-align: right; vertical-align: top;">
            ${currencyFormatter.format(totalPrice)}
          </td>
        </tr>
      ''';
        })
        .join('');

    final taxRate = order.subtotal > 0
        ? (order.tax / order.subtotal) * 100
        : 0.0;

    return '''
      <div style="font-family: 'Segoe UI', Helvetica, Arial, sans-serif; color: #2D3748; max-width: 600px; margin: 0 auto; border: 1px solid #CBD5E0; border-radius: 10px; background-color: #FFFFFF; overflow: hidden; box-shadow: 0 4px 12px rgba(0,0,0,0.05);">
        
        <!-- CABECERA CENTRADA CON LOGO DE D-UNA -->
        <div style="padding: 16px 20px; text-align: center; border-bottom: 2px solid #E2E8F0; background-color: #FAFAFA;">
          <img src="https://fdkswvzrozijbizdthge.supabase.co/storage/v1/object/sign/app_images/logo_d_una.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV8yNjZhOWZkMS0xYWQyLTQ3OWEtOGNlYS1kYjQzMjA0OGNlMjkiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJhcHBfaW1hZ2VzL2xvZ29fZF91bmEucG5nIiwic2NvcGUiOiJkb3dubG9hZCIsImlhdCI6MTc4NTI2NTY0NSwiZXhwIjo0OTM4ODY1NjQ1fQ.2vHh0Q0-FA0ZQDV-HeBtlf6CKCS7jrPI5CIFjK7yPVw" style="max-height: 42px; object-fit: contain; margin-bottom: 4px;" alt="D-Una"><br>
          <h2 style="margin: 2px 0 1px 0; font-size: 16px; font-weight: 700; color: #2D3748; text-transform: uppercase; letter-spacing: 0.5px;">Orden de Compra</h2>
          <h3 style="margin: 0 0 2px 0; font-size: 15px; font-weight: 700; color: #616161;">${order.orderNumber}</h3>
          <span style="font-size: 11px; color: #718096;"><strong>Fecha y Lugar:</strong> $locationDateStr</span>
        </div>

        <div style="padding: 16px 20px;">

          <!-- GRILLA DE INFORMACIÓN (2 Columnas: Datos del Cliente vs Condiciones de Envío y Entrega) -->
          <table style="width: 100%; border-collapse: collapse; margin-bottom: 14px;">
            <tr>
              <!-- Columna Izquierda: Datos del Cliente -->
              <td style="width: 48%; vertical-align: top; padding-right: 10px;">
                <h4 style="margin: 0 0 4px 0; font-size: 12px; color: #616161; text-transform: uppercase; border-bottom: 1px solid #E2E8F0; padding-bottom: 2px;">Datos del Cliente</h4>
                <p style="margin: 2px 0; font-size: 11px; line-height: 1.35; color: #4A5568;"><strong>${hasCompany ? 'Razón Social:' : 'Nombre:'}</strong> ${userDisplayName.isEmpty ? '-' : userDisplayName}</p>
                <p style="margin: 2px 0; font-size: 11px; line-height: 1.35; color: #4A5568;"><strong>${hasCompany ? 'RIF/ID Fiscal:' : 'C.I. / ID:'}</strong> ${userIdOrRif.isEmpty ? '-' : userIdOrRif}</p>
                <p style="margin: 2px 0; font-size: 11px; line-height: 1.35; color: #4A5568;"><strong>Dirección:</strong> ${userAddress.isEmpty ? '-' : userAddress}</p>
                <p style="margin: 2px 0; font-size: 11px; line-height: 1.35; color: #4A5568;"><strong>Contacto:</strong> ${userContactName.isEmpty ? '-' : userContactName}</p>
                <p style="margin: 2px 0; font-size: 11px; line-height: 1.35; color: #4A5568;"><strong>Teléfono:</strong> ${userProfile.phone ?? '-'}</p>
              </td>
              
              <!-- Separador -->
              <td style="width: 4%;"></td>

              <!-- Columna Derecha: Condiciones de Envío y Entrega -->
              <td style="width: 48%; vertical-align: top; padding-left: 10px;">
                <h4 style="margin: 0 0 4px 0; font-size: 12px; color: #616161; text-transform: uppercase; border-bottom: 1px solid #E2E8F0; padding-bottom: 2px;">Condiciones de Envío / Entrega</h4>
                ${!isPersonalPickup ? '''
                  <p style="margin: 2px 0; font-size: 11px; line-height: 1.35; color: #4A5568;"><strong>Empresa de Envío:</strong> $companyName</p>
                  ${showBranchCode ? '<p style="margin: 2px 0; font-size: 11px; line-height: 1.35; color: #4A5568;"><strong>Código Sucursal:</strong> $branchCodeStr</p>' : ''}
                  <p style="margin: 2px 0; font-size: 11px; line-height: 1.35; color: #4A5568;"><strong>Dirección Envío:</strong> $fullAddress</p>
                ''' : ''}
                <p style="margin: 2px 0; font-size: 11px; line-height: 1.35; color: #4A5568;"><strong>Opción de Entrega:</strong> $deliveryOption</p>

                <h4 style="margin: 8px 0 4px 0; font-size: 11px; color: #616161; text-transform: uppercase; border-bottom: 1px solid #E2E8F0; padding-bottom: 2px;">Persona que Retira</h4>
                <p style="margin: 2px 0; font-size: 11px; line-height: 1.35; color: #4A5568;"><strong>Nombre:</strong> $receiverName</p>
                ${receiverId != null && receiverId.trim().isNotEmpty ? '<p style="margin: 2px 0; font-size: 11px; line-height: 1.35; color: #4A5568;"><strong>ID:</strong> ${receiverId.trim()}</p>' : ''}
                ${receiverPhone != null && receiverPhone.trim().isNotEmpty ? '<p style="margin: 2px 0; font-size: 11px; line-height: 1.35; color: #4A5568;"><strong>Teléfono:</strong> ${receiverPhone.trim()}</p>' : ''}
              </td>
            </tr>
          </table>

          <!-- TABLA DE PRODUCTOS -->
          <table style="width: 100%; border-collapse: collapse; margin-bottom: 14px; border: 1px solid #CBD5E0;">
            <thead>
              <tr style="background-color: #616161; color: #FFFFFF; font-size: 11px; text-transform: uppercase;">
                <th style="padding: 6px 8px; width: 50px; text-align: center;">Cant.</th>
                <th style="padding: 6px 8px; text-align: left;">Productos</th>
                <th style="padding: 6px 8px; width: 90px; text-align: right;">Precio Unit.</th>
                <th style="padding: 6px 8px; width: 90px; text-align: right;">Sub-Total</th>
              </tr>
            </thead>
            <tbody>
              $itemsRowsHtml
            </tbody>
          </table>

          <!-- TOTALES Y CONDICIONES DE PAGO -->
          <table style="width: 100%; border-collapse: collapse; margin-bottom: 16px;">
            <tr>
              <td style="vertical-align: top; width: 55%;">
                <h4 style="margin: 0 0 4px 0; font-size: 11px; color: #616161; text-transform: uppercase; border-bottom: 1px solid #E2E8F0; padding-bottom: 2px;">Condiciones de Pago</h4>
                <p style="margin: 2px 0; font-size: 11px; color: #4A5568;"><strong>Método:</strong> ${order.paymentMethod ?? 'Por definir'}</p>
              </td>
              <td style="vertical-align: top; width: 45%;">
                <table style="width: 100%; border-collapse: collapse; border: 1px solid #CBD5E0; background-color: #F7FAFC;">
                  <tr>
                    <td style="padding: 4px 8px; font-size: 11px; color: #4A5568;">Sub-Total (USD):</td>
                    <td style="padding: 4px 8px; font-size: 11px; color: #2D3748; font-weight: bold; text-align: right;">${currencyFormatter.format(order.subtotal)}</td>
                  </tr>
                  <tr>
                    <td style="padding: 4px 8px; font-size: 11px; color: #4A5568;">IVA (${taxRate.toStringAsFixed(0)}%):</td>
                    <td style="padding: 4px 8px; font-size: 11px; color: #2D3748; text-align: right;">${currencyFormatter.format(order.tax)}</td>
                  </tr>
                  <tr style="border-top: 2px solid #CBD5E0; background-color: #EDF2F7;">
                    <td style="padding: 6px 8px; font-size: 13px; color: #1A202C; font-weight: bold;">Total (USD):</td>
                    <td style="padding: 6px 8px; font-size: 13px; color: #616161; font-weight: bold; text-align: right;">${currencyFormatter.format(order.total)}</td>
                  </tr>
                </table>
              </td>
            </tr>
          </table>

          <!-- BOTONES DE ACCIÓN TRANSACCIONAL -->
          <div style="text-align: center; margin: 16px 0 8px 0; padding: 14px 16px; background-color: #F8FAFC; border: 1px dashed #CBD5E0; border-radius: 8px;">
            <p style="font-size: 13px; font-weight: bold; color: #2D3748; margin: 0 0 10px 0;">Por favor confirme la disponibilidad de esta orden:</p>
            
            <a href="$confirmUrl" style="background-color: #388E3C; color: #FFFFFF; text-decoration: none; padding: 10px 10px; border-radius: 6px; font-weight: bold; font-size: 13px; display: inline-block; margin-right: 8px; margin-bottom: 6px; box-shadow: 0 2px 4px rgba(46,125,50,0.2);">
              Aprobar
            </a>
            
            <a href="$rejectUrl" style="background-color: #F86F28; color: #FFFFFF; text-decoration: none; padding: 10px 10px; border-radius: 6px; font-weight: bold; font-size: 13px; display: inline-block; margin-bottom: 6px; box-shadow: 0 2px 4px rgba(198,40,40,0.2);">
              Rechazar
            </a>
            <br><br>
            <p style="font-size: 13px; font-weight: bold; color: #2D3748; margin: 0 0 10px 0;">Agradecemos aprobar esta orden solo si se cuenta con el inventario completo y los precios validados; de lo contrario, por favor, rechazarla.</p>
            <br>
            <p style="font-size: 13px; font-weight: bold; color: #2D3748; margin: 0 0 10px 0;">ESTA ORDEN CADUCA EN 72 H</p>
          </div>

        </div>

        <!-- FOOTER INSTITUCIONAL -->
        <div style="background-color: #F7FAFC; padding: 12px 20px; border-top: 1px solid #E2E8F0; text-align: center; font-size: 10px; color: #A0AEC0;">
          Enviado con D-UNA &bull; Gestión Operativa de Órdenes de Compra
        </div>

      </div>
    ''';
  }
}
