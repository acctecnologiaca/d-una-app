import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/service_report_item_product.dart';
import '../providers/create_report_provider.dart';
import '../providers/report_product_selection_provider.dart';
import '../widgets/report_added_product_card.dart';
import '../widgets/report_product_sale_details_sheet.dart';

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
      padding: const EdgeInsets.only(top: 8, bottom: 120),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final originalIndex = state.products.indexOf(product);
        final isTemporal =
            product.sourceType == ReportProductSourceType.temporal;

        return ReportAddedProductCard(
          product: product,
          isReadOnly: state.isReadOnly,
          onQuantityChanged: (newQty) {
            final newSubtotal = product.unitPrice * newQty;
            final taxAmount = newSubtotal * (product.taxRate / 100);
            final updated = product.copyWith(
              quantity: newQty,
              taxAmount: taxAmount,
              totalPrice: newSubtotal,
            );
            notifier.updateProduct(originalIndex, updated);
          },
          onDelete: () {
            notifier.removeProduct(originalIndex);
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
