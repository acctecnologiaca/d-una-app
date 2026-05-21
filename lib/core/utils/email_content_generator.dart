class EmailContentGenerator {
  /// Genera el asunto del correo reemplazando los marcadores por valores reales.
  static String generateSubject({
    required String template,
    required String documentNumber,
    String? category,
    String? tag,
    String documentType = 'Documento',
  }) {
    return template
        .replaceAll('{{numero}}', documentNumber)
        .replaceAll('{{number}}', documentNumber)
        .replaceAll('{{categoria}}', category ?? '')
        .replaceAll('{{category}}', category ?? '')
        .replaceAll('{{etiqueta}}', tag ?? '')
        .replaceAll('{{tag}}', tag ?? '')
        .replaceAll('{{tipo_documento}}', documentType)
        .replaceAll('{{document_type}}', documentType)
        .replaceAll(' -  - ', ' - ') // Limpieza de guiones vacíos
        .replaceAll(' - ', ' ')
        .trim();
  }

  /// Genera el cuerpo del correo reemplazando los marcadores por valores reales.
  static String generateBody({
    required String template,
    required String clientName,
    required String userName,
    String? companyName,
    String? collaboratorName,
  }) {
    return template
        .replaceAll('{{nombre_cliente}}', clientName)
        .replaceAll('{{client_name}}', clientName)
        .replaceAll('{{nombre_usuario}}', userName)
        .replaceAll('{{user_name}}', userName)
        .replaceAll('{{nombre_empresa}}', companyName ?? '')
        .replaceAll('{{company_name}}', companyName ?? '')
        .replaceAll('{{nombre_colaborador}}', collaboratorName ?? '')
        .replaceAll('{{collaborator_name}}', collaboratorName ?? '')
        .replaceAll('{{nombre_asesor}}', collaboratorName ?? '')
        .replaceAll('{{nombre asesor}}', collaboratorName ?? '')
        .replaceAll('{{nombre_tecnico}}', collaboratorName ?? '')
        .replaceAll('{{nombre tecnico}}', collaboratorName ?? '');
  }

  /// Plantillas por defecto para nuevos usuarios o cuando no se ha configurado nada.
  static String getDefaultSubject(String type) {
    switch (type) {
      case 'quote':
        return 'Cotización #{{numero}} - {{categoria}}';
      case 'order':
        return 'Pedido #{{numero}}';
      case 'report':
        return 'Reporte de {{categoria}}';
      default:
        return 'Envío de {{tipo_documento}} #{{numero}}';
    }
  }

  static String getDefaultBody(String type) {
    final firma = type == 'report' ? '{{nombre_tecnico}}' : '{{nombre_asesor}}';
    return 'Estimado(a) {{nombre_cliente}},\n\n'
        'Es un gusto saludarle. Adjunto encontrará el documento solicitado.\n\n'
        'Quedo atento(a) a cualquier duda o comentario.\n\n'
        'Atentamente,\n'
        '$firma';
  }
}
