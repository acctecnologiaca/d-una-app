import '../models/supplier_order.dart';
import '../models/supplier_order_item.dart';
import '../../../../features/profile/domain/models/user_profile.dart';
//import '../../../../features/settings/data/models/shipping_method.dart';
//import '../../../../features/collaborators/domain/models/collaborator.dart';

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

    return "Ha recibido una nueva orden de compra (${order.orderNumber}) de $userDisplayName";
  }

  static String buildHtmlBody({
    required SupplierOrder order,
    required List<SupplierOrderItem> items,
    required UserProfile userProfile,
    required String userEmail,
    required String actionToken,
    //required String apiBaseUrl,
    //  ShippingMethod? shippingMethod,
    //  Collaborator? receiverCollaborator,
  }) {
    // URL del visor web en Firebase Hosting
    const orderViewerUrl = 'https://d-una.app/order.html';
    final viewerUrl = '$orderViewerUrl?token=$actionToken';

    // Datos del Usuario Emisor
    final hasCompany =
        userProfile.companyName != null &&
        userProfile.companyName!.trim().isNotEmpty;
    final userDisplayName = hasCompany
        ? userProfile.companyName!.trim()
        : '${userProfile.firstName ?? ''} ${userProfile.lastName ?? ''}'.trim();
    final finalUserName = userDisplayName.isEmpty
        ? 'un cliente'
        : userDisplayName;

    final userPhone =
        (userProfile.phone != null && userProfile.phone!.trim().isNotEmpty)
        ? userProfile.phone!.trim()
        : 'su número de contacto habitual';

    return '''
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Orden de Compra D-Una</title>
</head>
<body style="font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; background-color: #F8FAFC; margin: 0; padding: 24px 16px; color: #1E293B; line-height: 1.6;">
  <div style="max-width: 640px; margin: 0 auto; background-color: #FFFFFF; border-radius: 12px; overflow: hidden; border: 1px solid #E2E8F0; box-shadow: 0 4px 12px rgba(0, 0, 0, 0.05);">
    
    <div style="padding: 28px 24px;">
      <p style="font-size: 15px; color: #334155; margin: 0 0 16px 0;">
        Al final de este mensaje encontrará el enlace a la orden de compra <strong>#${order.orderNumber}</strong> emitida por <strong>$finalUserName</strong>.
      </p>

      <p style="font-size: 14px; color: #475569; margin: 0 0 16px 0;">
        📞 Si tiene alguna duda o requiere información adicional, puede contactarle a través de la dirección de correo <strong>$userEmail</strong> o al número <strong>$userPhone</strong>.
      </p>

      <p style="font-size: 14px; color: #475569; margin: 0 0 28px 0;">
        📝 <strong>Nota: Esta orden de compra tiene una vigencia máxima de 72h</strong>, luego de ese tiempo, no podrá ser visualizada ni procesada, por lo que se recomienda atenderla a la brevedad posible.
      </p>

      <!-- BOTÓN PRINCIPAL DE ACCIÓN -->
      <div style="text-align: center; margin: 28px 0 14px 0;">
        <a href="$viewerUrl" style="background-color: #0F172A; color: #FFFFFF; text-decoration: none; padding: 14px 28px; border-radius: 10px; font-weight: 700; font-size: 14px; display: inline-block; box-shadow: 0 4px 12px rgba(15, 23, 42, 0.25);">
          Ver orden de compra
        </a>
      </div>

      <!-- RESPALDO CON ENLACE DIRECTO -->
      <p style="font-size: 12px; color: #64748B; text-align: center; margin: 0 0 20px 0; line-height: 1.5;">
        Si el botón no funciona en su gestor de correo, copie y pegue este enlace en su navegador:<br>
        <a href="$viewerUrl" style="color: #0284C7; word-break: break-all; text-decoration: underline;">$viewerUrl</a>
      </p>
    </div>

    <!-- FOOTER INSTITUCIONAL -->
    <div style="background-color: #F1F5F9; padding: 18px 20px; border-top: 1px solid #E2E8F0; text-align: center;">
      <img src="https://fdkswvzrozijbizdthge.supabase.co/storage/v1/object/sign/app_images/creado_con_d_una.png?token=eyJraWQiOiJzdG9yYWdlLXVybC1zaWduaW5nLWtleV8yNjZhOWZkMS0xYWQyLTQ3OWEtOGNlYS1kYjQzMjA0OGNlMjkiLCJhbGciOiJIUzI1NiJ9.eyJ1cmwiOiJhcHBfaW1hZ2VzL2NyZWFkb19jb25fZF91bmEucG5nIiwiaWF0IjoxNzc4MjUwNzI0LCJleHAiOjQ5MzE4NTA3MjR9.sP-lgLmlurZ3oMZxk6IGFwaRQ6_OTKZgMmiZQ0CM4Mc" width="110" style="display: inline-block; opacity: 0.85;" alt="Creado con D-UNA">
    </div>

  </div>
</body>
</html>
''';
  }
}
