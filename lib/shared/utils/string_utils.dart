class StringUtils {
  /// Sanitize a string to be used as a file name.
  /// 1. Removes common company suffixes (C.A., S.A., Corp., etc.)
  /// 2. Removes hyphens (-)
  /// 3. Replaces spaces with underscores (_)
  /// 4. Removes non-alphanumeric characters except underscores
  static String sanitizeForFileName(String input) {
    if (input.isEmpty) return 'documento';

    // 1. Sustituir vocales con acentos y Ñ por versiones sin acento
    String result = input
        .replaceAll(RegExp(r'[áàäâ]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöô]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll(RegExp(r'[ÁÀÄÂ]'), 'A')
        .replaceAll(RegExp(r'[ÉÈËÊ]'), 'E')
        .replaceAll(RegExp(r'[ÍÌÏÎ]'), 'I')
        .replaceAll(RegExp(r'[ÓÒÖÔ]'), 'O')
        .replaceAll(RegExp(r'[ÚÙÜÛ]'), 'U')
        .replaceAll(RegExp(r'[ñ]'), 'n')
        .replaceAll(RegExp(r'[Ñ]'), 'N');

    // 2. Eliminar siglas de empresas (incluyendo variaciones con puntos y espacios)
    final companySuffixes = [
      r'\bc\.a\.?\b',
      r'\bs\.a\.?\b',
      r'\bcorp\.?\b',
      r'\binc\.?\b',
      r'\bllc\b',
      r'\bs\.r\.l\.?\b',
      r'\bs\.a\.s\.?\b',
      r'\bg\.p\.?\b',
    ];

    for (var suffix in companySuffixes) {
      final regex = RegExp(suffix, caseSensitive: false);
      result = result.replaceAll(regex, '');
    }

    // 3. Eliminar guiones (uniendo caracteres)
    result = result.replaceAll('-', '');

    // 4. Reemplazar espacios por guiones bajos
    result = result.replaceAll(' ', '_');

    // 5. Limpiar caracteres especiales excepto guiones bajos y puntos (para la extensión)
    result = result.replaceAll(RegExp(r'[^\w\.]'), '');

    // 6. Normalizar guiones bajos y puntos
    result = result.replaceAll(RegExp(r'_+'), '_');
    result = result.trim().replaceAll(RegExp(r'^_+|_+$'), '');

    return result.isEmpty ? 'archivo' : result;
  }
}
