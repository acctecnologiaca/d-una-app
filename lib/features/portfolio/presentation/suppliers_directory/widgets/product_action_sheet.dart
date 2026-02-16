import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/bottom_sheet_action_item.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import 'supplier_product_row.dart';
import '../../widgets/estimate_price_sheet.dart';

class ProductActionSheet {
  static void show(
    BuildContext context, {
    required String supplierName,
    required String productName,
    required double price,
    required int stock,
    required bool isWholesale,
    String uom = 'ud.',
    String? location,
    String? brand,
    String? model,
  }) {
    CustomActionSheet.show(
      context: context,
      title: 'Proveedor y sucursal seleccionada',
      content: SupplierProductRow(
        supplierName: supplierName,
        price: price,
        stock: stock,
        uom: uom,
        isWholesale: isWholesale,
        locationName: location,
      ),
      actions: [
        BottomSheetActionItem(
          icon: Icons.sell_outlined,
          label: 'Estimar precio de venta',
          onTap: () {
            context.pop();
            EstimatePriceSheet.show(
              context,
              basePrice: price,
              productName: productName,
              productBrand: brand,
              productModel: model,
              uom: uom,
            );
          },
        ),
        BottomSheetActionItem(
          icon: Icons.shopping_cart_outlined,
          label: 'Realizar nuevo pedido',
          onTap: () {
            context.pop();
            // Implementation pending
          },
        ),
        BottomSheetActionItem(
          icon: Icons.add_shopping_cart,
          label: 'Agregar a pedido existente',
          onTap: () {
            context.pop();
            // Implementation pending
          },
        ),
        BottomSheetActionItem(
          icon: Icons.request_quote_outlined,
          label: 'Cotizar a cliente',
          onTap: () {
            context.pop();
            // Implementation pending
          },
        ),
        BottomSheetActionItem(
          icon: 'assets/icons/add_request_quote.png',
          label: 'Agregar a cotización existente',
          onTap: () {
            context.pop();
            // Implementation pending
          },
        ),
      ],
    );
  }
}
