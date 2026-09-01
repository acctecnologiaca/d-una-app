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
    final effectiveCompany =
        (companyName != null && companyName.trim().isNotEmpty)
        ? companyName.trim()
        : userName;
    final effectiveCollaborator =
        (collaboratorName != null && collaboratorName.trim().isNotEmpty)
        ? collaboratorName.trim()
        : effectiveCompany;

    return template
        .replaceAll('{{nombre_cliente}}', clientName)
        .replaceAll('{{client_name}}', clientName)
        .replaceAll('{{nombre_usuario}}', userName)
        .replaceAll('{{user_name}}', userName)
        .replaceAll('{{nombre_empresa}}', effectiveCompany)
        .replaceAll('{{company_name}}', effectiveCompany)
        .replaceAll('{{nombre_colaborador}}', effectiveCollaborator)
        .replaceAll('{{collaborator_name}}', effectiveCollaborator)
        .replaceAll('{{nombre_asesor}}', effectiveCollaborator)
        .replaceAll('{{nombre asesor}}', effectiveCollaborator)
        .replaceAll('{{nombre_tecnico}}', effectiveCollaborator)
        .replaceAll('{{nombre tecnico}}', effectiveCollaborator);
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
    if (type == 'report') {
      return 'Estimado(a) {{nombre_cliente}},\n\n'
          'Es un gusto saludarle. Adjunto encontrará el reporte de servicio solicitado.\n\n'
          'Quedamos atentos a cualquier duda o comentario.\n\n'
          'Atentamente,\n'
          '{{nombre_empresa}}';
    }
    return 'Estimado(a) {{nombre_cliente}},\n\n'
        'Es un gusto saludarle. Adjunto encontrará el documento solicitado.\n\n'
        'Quedo atento(a) a cualquier duda o comentario.\n\n'
        'Atentamente,\n'
        '{{nombre_asesor}}';
  }
}
