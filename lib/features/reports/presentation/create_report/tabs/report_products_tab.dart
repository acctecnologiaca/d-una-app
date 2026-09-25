import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/utils/fab_scroll_padding.dart';
import '../../../../portfolio/presentation/providers/products_provider.dart';
import '../../../data/models/service_report_item_product.dart';
import '../providers/create_report_provider.dart';
import '../providers/report_product_selection_provider.dart';
import '../widgets/report_added_product_card.dart';
import '../widgets/report_product_sale_details_sheet.dart';

import '../screens/report_manage_serials_screen.dart';

class ReportProductsTab extends ConsumerStatefulWidget {
  const ReportProductsTab({super.key});

  @override
  ConsumerState<ReportProductsTab> createState() => _ReportProductsTabState();
}

class _ReportProductsTabState extends ConsumerState<ReportProductsTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(createReportProvider);
    final notifier = ref.read(createReportProvider.notifier);
    final productsAsync = ref.watch(productsProvider);
    final catalogProducts = productsAsync.valueOrNull ?? [];

    if (state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos agregados',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final products = [...state.products]
      ..sort((a, b) => a.groupIndex.compareTo(b.groupIndex));

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: FabScrollPadding.single),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final originalIndex = state.products.indexOf(product);
        final isTemporal =
            product.sourceType == ReportProductSourceType.temporal;

        final catalogProduct = catalogProducts
            .where((cp) => cp.id == product.productId)
            .firstOrNull;
        final effectiveStock =
            catalogProduct?.availableQuantity ?? product.availableStock;
        final effectiveRequiresSerials = product.requiresSerials ||
            (catalogProduct?.requiresSerials ?? false) ||
            product.serials.isNotEmpty;
        final effectiveProduct = product.copyWith(
          availableStock: effectiveStock,
          requiresSerials: effectiveRequiresSerials,
        );

        return ReportAddedProductCard(
          product: effectiveProduct,
          isReadOnly: state.isReadOnly,
          onQuantityChanged: (newQty) {
            final newSubtotal = product.unitPrice * newQty;
            final taxAmount = newSubtotal * (product.taxRate / 100);
            var updatedSerials = product.serials;
            final needed = newQty.round();
            if (updatedSerials.length > needed) {
              updatedSerials = updatedSerials.take(needed).toList();
            }
            final updated = product.copyWith(
              quantity: newQty,
              taxAmount: taxAmount,
              totalPrice: newSubtotal,
              serials: updatedSerials,
            );
            notifier.updateProduct(originalIndex, updated);
          },
          onDelete: () {
            notifier.removeProduct(originalIndex);
          },
          onManageSerials: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ReportManageSerialsScreen(
                  item: effectiveProduct,
                  onRequiresSerialsChanged: (requires) {
                    notifier.setProductRequiresSerials(originalIndex, requires);
                  },
                  onSerialsSaved: (serials) {
                    notifier.updateProductSerials(
                      originalIndex,
                      serials,
                      requiresSerials: serials.isNotEmpty ? true : null,
                    );
                  },
                ),
              ),
            );
          },
          onEditPrice: !isTemporal
              ? () async {
                  final allProducts = await ref.read(
                    reportOwnProductSuggestionsProvider.future,
                  );
                  final productModel = allProducts
                      .where((p) => p.id == product.productId)
                      .firstOrNull;

                  if (productModel != null && context.mounted) {
                    final updated =
                        await ReportProductSaleDetailsSheet.show(
                      context,
                      product: productModel,
                      reportState: state,
                      existingItem: product,
                    );

                    if (updated != null) {
                      notifier.updateProduct(originalIndex, updated);
                    }
                  }
                }
              : null,
          onEditTemporal: isTemporal
              ? () async {
                  final updatedItem = await context
                      .push<ServiceReportItemProduct>(
                        '/reports/create/select-product/temporal',
                        extra: product,
                      );
                  if (updatedItem != null) {
                    notifier.updateProduct(originalIndex, updatedItem);
                  }
                }
              : null,
        );
      },
    );
  }
}
