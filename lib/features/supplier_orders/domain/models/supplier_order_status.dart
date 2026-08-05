import 'package:flutter/material.dart';

enum SupplierOrderStatus {
  draft('draft', 'Borrador', 'assets/icons/status_draft.png'),
  sent('sent', 'Enviada', 'assets/icons/status_sent.png'),
  resent('resent', 'Reenviada', 'assets/icons/status_resent.png'),
  approved('approved', 'Aprobada', 'assets/icons/status_approved.png'),
  rejected('rejected', 'Rechazada', 'assets/icons/status_rejected.png'),
  finalized('finalized', 'Finalizada', 'assets/icons/status_finalized.png'),
  cancelled('cancelled', 'Cancelada', 'assets/icons/status_cancelled.png'),
  merged('merged', 'Consolidada', 'assets/icons/status_merged.png');

  final String dbValue;
  final String label;
  final String iconPath;

  const SupplierOrderStatus(this.dbValue, this.label, this.iconPath);

  static SupplierOrderStatus fromDbValue(String value) {
    return values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => SupplierOrderStatus.draft,
    );
  }

  /// Indica si la OC puede ser modificada por el usuario
  bool get canEdit =>
      this != SupplierOrderStatus.approved &&
      this != SupplierOrderStatus.finalized &&
      this != SupplierOrderStatus.cancelled &&
      this != SupplierOrderStatus.merged;

  /// Indica si la OC puede enviarse/reenviarse directamente desde el botón principal
  bool get canSendDirectly =>
      this == SupplierOrderStatus.draft ||
      this == SupplierOrderStatus.sent ||
      this == SupplierOrderStatus.resent;

  Color statusColor(ColorScheme colors) {
    switch (this) {
      case SupplierOrderStatus.draft:
        return colors.onSurfaceVariant;
      case SupplierOrderStatus.sent:
        return colors.primary;
      case SupplierOrderStatus.resent:
        return const Color(0xFF1D8DC7);
      case SupplierOrderStatus.approved:
        return const Color(0xFF2E7D32); // Verde esmeralda
      case SupplierOrderStatus.rejected:
        return colors.error; // Rojo
      case SupplierOrderStatus.finalized:
        return const Color(0xFF6A53AD);
      case SupplierOrderStatus.cancelled:
        return colors.error;
      case SupplierOrderStatus.merged:
        return const Color(0xFF009688); //Teal
    }
  }
}
