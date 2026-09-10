import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';

enum DeliveryNoteStatus {
  draft('draft', 'Borrador', 'assets/icons/status_draft.png'),
  sent('sent', 'Enviada', 'assets/icons/status_sent.png'),
  resent('resent', 'Reenviada', 'assets/icons/status_resent.png'),
  opened('opened', 'Abierta', 'assets/icons/status_opened.png'),
  finalized('finalized', 'Finalizada', 'assets/icons/status_finalized.png'),
  cancelled('cancelled', 'Cancelada', 'assets/icons/status_cancelled.png');

  final String dbValue;
  final String label;
  final String iconPath;

  const DeliveryNoteStatus(this.dbValue, this.label, this.iconPath);

  static const DeliveryNoteStatus delivered = DeliveryNoteStatus.finalized;

  IconData get iconData {
    switch (this) {
      case DeliveryNoteStatus.draft:
        return Symbols.edit;
      case DeliveryNoteStatus.sent:
        return Symbols.send;
      case DeliveryNoteStatus.resent:
        return Symbols.double_arrow;
      case DeliveryNoteStatus.opened:
        return Symbols.visibility;
      case DeliveryNoteStatus.finalized:
        return Symbols.check_circle;
      case DeliveryNoteStatus.cancelled:
        return Symbols.cancel;
    }
  }

  static DeliveryNoteStatus fromDbValue(String value) {
    if (value == 'delivered') return DeliveryNoteStatus.finalized;
    return values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => DeliveryNoteStatus.draft,
    );
  }

  bool get canEdit =>
      this != DeliveryNoteStatus.finalized &&
      this != DeliveryNoteStatus.cancelled;

  bool get canSendDirectly =>
      this == DeliveryNoteStatus.draft ||
      this == DeliveryNoteStatus.sent ||
      this == DeliveryNoteStatus.resent ||
      this == DeliveryNoteStatus.opened;

  Color statusColor(ColorScheme colors) {
    switch (this) {
      case DeliveryNoteStatus.draft:
        return colors.onSurfaceVariant;
      case DeliveryNoteStatus.sent:
        return colors.primary;
      case DeliveryNoteStatus.resent:
        return const Color(0xFF1D8DC7);
      case DeliveryNoteStatus.opened:
        return const Color(0xFF5C6BC0);
      case DeliveryNoteStatus.finalized:
        return const Color(0xFF6A53AD);
      case DeliveryNoteStatus.cancelled:
        return colors.error;
    }
  }
}
