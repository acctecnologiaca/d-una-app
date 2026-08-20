import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/info_disclaimer_card.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_search_bar.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../shared/widgets/friendly_error_widget.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../portfolio/data/models/product_model.dart';
import '../providers/create_report_provider.dart';
import '../providers/report_product_selection_provider.dart';
import '../widgets/report_product_selection_card.dart';
import '../widgets/report_product_sale_details_sheet.dart';
import '../../../data/models/service_report_item_product.dart';

class SelectReportProductScreen extends ConsumerStatefulWidget {
  const SelectReportProductScreen({super.key});

  @override
  ConsumerState<SelectReportProductScreen> createState() =>
      _SelectReportProductScreenState();
}

class _SelectReportProductScreenState
    extends ConsumerState<SelectReportProductScreen> {
  SortOption _currentSort = SortOption.recent;
  String? _selectedProductId;
  double _selectedQuantity = 0.0;
  Product? _selectedProduct;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final productsAsync = ref.watch(reportOwnProductSuggestionsProvider);
    final reportState = ref.watch(createReportProvider);
    final reportNumber =
        reportState.report?.reportNumber ??
        reportState.currentReportNumber ??
        '';
    final reportProducts = reportState.products;

    final hasSelection = _selectedQuantity > 0 && _selectedProduct != null;

    final formattedQty =
        _selectedQuantity.truncateToDouble() == _selectedQuantity
        ? _selectedQuantity.toInt().toString()
        : _selectedQuantity.toStringAsFixed(2);
    final totalCost =
        (_selectedProduct?.averageCost ?? 0.0) * _selectedQuantity;
    final formattedTotal = CurrencyFormatter.format(totalCost);
    final uom = _selectedProduct?.uom ?? 'ud.';

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Agregar producto',
        subtitle: reportNumber.isNotEmpty ? 'Reporte #$reportNumber' : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Search Bar (Read-only -> Navigates to Search)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: InkWell(
              onTap: () {
                context.push('/reports/create/select-product/search').then((
                  result,
                ) {
                  if (result == true) {
                    if (context.mounted) {
                      context.pop(true);
                    }
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: IgnorePointer(
                child: CustomSearchBar(
                  hintText: 'Buscar producto...',
                  onChanged: (_) {},
                  readOnly: true,
                  showFilterIcon: true,
                ),
              ),
            ),
          ),

          // 2. Add Temporal Product Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(
              onPressed: () async {
                final result = await context.push<ServiceReportItemProduct>(
                  '/reports/create/select-product/temporal',
                );
                if (result != null && context.mounted) {
                  ref.read(createReportProvider.notifier).addProduct(result);
                  context.pop(true);
                }
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: colors.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                foregroundColor: colors.onSurface,
              ),
              child: const Text(
                'Agregar producto temporal',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // 3. Disclaimer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const InfoDisclaimerCard(
              text: 'Precios no incluyen impuestos',
              showCloseButton: true,
            ),
          ),

          // 4. Sort Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SortSelector(
                  currentSort: _currentSort,
                  onSortChanged: (val) => setState(() => _currentSort = val),
                  options: const [
                    SortOption.recent,
                    SortOption.nameAZ,
                    SortOption.nameZA,
                  ],
                ),
              ],
            ),
          ),

          // 4. Products List
          Expanded(
            child: productsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => FriendlyErrorWidget(
                error: err,
                onRetry: () =>
                    ref.invalidate(reportOwnProductSuggestionsProvider),
              ),
              data: (allProducts) {
                final sortedProducts = List.of(allProducts);

                // Sort logic
                sortedProducts.sort((a, b) {
                  switch (_currentSort) {
                    case SortOption.nameAZ:
                      return a.name.toLowerCase().compareTo(
                        b.name.toLowerCase(),
                      );
                    case SortOption.nameZA:
                      return b.name.toLowerCase().compareTo(
                        a.name.toLowerCase(),
                      );
                    case SortOption.recent:
                    default:
                      return b.updatedAt.compareTo(a.updatedAt);
                  }
                });

                if (sortedProducts.isEmpty) {
                  return Center(
                    child: Text(
                      'No tienes productos en tu inventario propio',
                      style: TextStyle(color: colors.onSurfaceVariant),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 120),
                  itemCount: sortedProducts.length,
                  itemBuilder: (context, index) {
                    final product = sortedProducts[index];
                    final isAlreadyInReport = reportProducts.any(
                      (p) => p.productId == product.id,
                    );
                    final isThisSelected = _selectedProductId == product.id;
                    final currentQty = isThisSelected ? _selectedQuantity : 0.0;
                    final isLocked =
                        _selectedProductId != null &&
                        _selectedProductId != product.id;

                    return ReportProductSelectionCard(
                      key: ValueKey(product.id),
                      product: product,
                      selectedQty: currentQty,
                      isLocked: isLocked,
                      isAlreadyInReport: isAlreadyInReport,
                      onQtyChanged: (qty) {
                        setState(() {
                          if (qty > 0) {
                            _selectedProductId = product.id;
                            _selectedQuantity = qty;
                            _selectedProduct = product;
                          } else {
                            if (_selectedProductId == product.id) {
                              _selectedProductId = null;
                              _selectedQuantity = 0.0;
                              _selectedProduct = null;
                            }
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: hasSelection
          ? Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: CustomExtendedFab(
                icon: Icons.check,
                label: 'Confirmar ($formattedQty $uom - $formattedTotal)',
                isEnabled: true,
                onPressed: () async {
                  if (_selectedProduct == null || _selectedQuantity <= 0) {
                    return;
                  }

                  final item = await ReportProductSaleDetailsSheet.show(
                    context,
                    product: _selectedProduct!,
                    reportState: reportState,
                    selectedQuantity: _selectedQuantity,
                  );

                  if (item != null && context.mounted) {
                    ref.read(createReportProvider.notifier).addProduct(item);
                    context.pop(true);
                  }
                },
              ),
            )
          : null,
    );
  }
}
