class OCCreditHelper {
  /// Calcula la cantidad de créditos ganados por una Orden de Compra ($1 crédito por cada $10 USD).
  static int calculateEarnedCredits(double totalAmountUsd) {
    if (totalAmountUsd <= 0) return 0;
    return (totalAmountUsd / 10.0).floor();
  }

  /// Calcula el monto faltante para alcanzar el siguiente crédito.
  static double calculateShortfallForNextCredit(double totalAmountUsd) {
    if (totalAmountUsd <= 0) return 10.0;
    final remainder = totalAmountUsd % 10.0;
    if (remainder == 0) return 0.0;
    return 10.0 - remainder;
  }

  /// Determina si debe mostrarse la sugerencia promocional (umbral <= $3.00 USD por defecto).
  static bool shouldShowSuggestion(double totalAmountUsd, {double threshold = 3.0}) {
    if (totalAmountUsd <= 0) return false;
    final shortfall = calculateShortfallForNextCredit(totalAmountUsd);
    return shortfall > 0 && shortfall <= threshold;
  }
}
