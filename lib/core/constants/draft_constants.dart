import 'package:flutter/material.dart';

class DraftConstants {
  static const String quotesModule = 'quotes';
  static const String reportsModule = 'reports';
  static const String supplierOrdersModule = 'supplier_orders';
  static const String purchasesModule = 'purchases';
  static const String deliveryNotesModule = 'delivery_notes'; // Para futuros módulos

  static const Duration autoSaveDebounce = Duration(milliseconds: 500);

  /// Ícono oficial para documentos con cambios locales / borradores activos
  static const IconData draftIcon = Icons.bookmark_added_outlined;
}
