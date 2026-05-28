import 'package:flutter/material.dart';

enum SupplierOrderStatus {
  draft('draft', 'Borrador', 'assets/icons/status_draft.png'),
  sent('sent', 'Enviada', 'assets/icons/status_sent.png'),
  resent('resent', 'Reenviada', 'assets/icons/status_resent.png'),
  finalized('finalized', 'Finalizada', 'assets/icons/status_finalized.png'),
  cancelled('cancelled', 'Cancelada', 'assets/icons/status_cancelled.png');

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

  Color statusColor(ColorScheme colors) {
    switch (this) {
      case SupplierOrderStatus.draft:
        return colors.onSurfaceVariant;
      case SupplierOrderStatus.sent:
        return colors.primary;
      case SupplierOrderStatus.resent:
        return const Color(0xFF1D8DC7);
      case SupplierOrderStatus.finalized:
        return const Color(0xFF6A53AD);
      case SupplierOrderStatus.cancelled:
        return colors.error;
    }
  }
}
