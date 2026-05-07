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
        .replaceAll('{{number}}', documentNumber)
        .replaceAll('{{category}}', category ?? '')
        .replaceAll('{{tag}}', tag ?? '')
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
  }) {
    return template
        .replaceAll('{{client_name}}', clientName)
        .replaceAll('{{user_name}}', userName)
        .replaceAll('{{company_name}}', companyName ?? '');
  }

  /// Plantillas por defecto para nuevos usuarios o cuando no se ha configurado nada.
  static String getDefaultSubject(String type) {
    switch (type) {
      case 'quote':
        return 'Cotización #{{number}} - {{category}}';
      case 'order':
        return 'Pedido #{{number}}';
      case 'report':
        return 'Reporte de {{category}}';
      default:
        return 'Envío de {{document_type}} #{{number}}';
    }
  }

  static String getDefaultBody(String type) {
    return 'Estimado(a) {{client_name}},\n\n'
        'Es un gusto saludarle. Adjunto encontrará el documento solicitado.\n\n'
        'Quedo atento(a) a cualquier duda o comentario.\n\n'
        'Atentamente,\n'
        '{{user_name}}';
  }
}
