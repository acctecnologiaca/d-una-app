import 'package:flutter/material.dart';
import '../../../domain/models/supplier_order.dart';
import 'merge_supplier_orders_sheet.dart';

class MergeSupplierOrdersDialog {
  MergeSupplierOrdersDialog._();

  static Future<bool?> show({
    required BuildContext context,
    required List<SupplierOrder> selectedOrders,
  }) {
    return MergeSupplierOrdersSheet.show(
      context: context,
      selectedOrders: selectedOrders,
    );
  }
}
