import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/view_quote_provider.dart';
import '../../create_quote/widgets/quote_added_product_card.dart';
import '../../create_quote/providers/quote_validation_provider.dart';
import '../../../data/models/quote_item_product.dart';
import '../widgets/view_product_details_sheet.dart';
import '../../../domain/models/product_origin.dart';

class ViewQuoteProductsTab extends ConsumerStatefulWidget {
  final String quoteId;
  const ViewQuoteProductsTab({super.key, required this.quoteId});

  @override
  ConsumerState<ViewQuoteProductsTab> createState() =>
      _ViewQuoteProductsTabState();
}

class _ViewQuoteProductsTabState extends ConsumerState<ViewQuoteProductsTab> {
  bool _showRefreshHint = true;
  Timer? _hintTimer;

  @override
  void initState() {
    super.initState();
    // La validación ahora se inicia desde ViewQuoteScreen para alimentar los badges de los Tabs
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(viewQuoteProvider(widget.quoteId));
    final validationState = ref.watch(quoteValidationProvider(widget.quoteId));

    final hasMissingValidation = state.products.any(
      (p) =>
          p.sourceType != QuoteItemSourceType.temporal &&
          p.sourceType != QuoteItemSourceType.external &&
          !validationState.items.containsKey(p.id),
    );

    final needsInitialValidation =
        state.products.isNotEmpty &&
        !validationState.isValidating &&
        (validationState.items.isEmpty || hasMissingValidation);

    if (needsInitialValidation) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(quoteValidationProvider(widget.quoteId).notifier)
            .startValidation();
      });
    }

    if (state.products.isNotEmpty &&
        (validationState.isValidating || needsInitialValidation) &&
        (validationState.items.isEmpty || hasMissingValidation)) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Sincronizando inventario...',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    if (state.products.isNotEmpty && _showRefreshHint && _hintTimer == null) {
      _hintTimer = Timer(const Duration(seconds: 5), () {
        if (mounted) {
          setState(() => _showRefreshHint = false);
        }
      });
    }

    if (state.isLoading && state.quote == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Symbols.package_2,
              size: 64,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay productos en esta cotización',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 16,
              ),
            ),
          ],
        ),
      );
    }

    final groupedProducts = <int, List<QuoteItemProduct>>{};
    for (var product in state.products) {
      if (!groupedProducts.containsKey(product.groupIndex)) {
        groupedProducts[product.groupIndex] = [];
      }
      groupedProducts[product.groupIndex]!.add(product);
    }

    final sortedIndices = groupedProducts.keys.toList()..sort();

    return Column(
      children: [
        if (validationState.isValidating)
          const LinearProgressIndicator(minHeight: 2)
        else
          const SizedBox(height: 2),
        AnimatedSize(
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          child: _showRefreshHint
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    'Desliza hacia abajo para actualizar disponibilidad y precios actuales',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : const SizedBox(width: double.infinity, height: 0),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => ref
                .read(quoteValidationProvider(widget.quoteId).notifier)
                .validate(),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: sortedIndices.length,
              padding: const EdgeInsets.only(bottom: 120),
              itemBuilder: (context, index) {
                final groupIndex = sortedIndices[index];
                final items = groupedProducts[groupIndex]!;
                final firstItem = items.first;
                final groupName = firstItem.name;

                double totalQuantity = 0;
                double totalAvailableStock = 0;
                double totalCost = 0;
                double subtotal = 0;

                for (var item in items) {
                  totalQuantity += item.quantity;
                  totalCost += item.costPrice * item.quantity;
                  subtotal += item.unitPrice * item.quantity;
                }

                final averageCost = totalQuantity > 0
                    ? totalCost / totalQuantity
                    : 0.0;
                final bool isTemporal =
                    firstItem.sourceType == QuoteItemSourceType.temporal;

                // Determine group validation status and fresh stock
                final Set<QuoteValidationStatus> groupAlerts = {};

                if (!isTemporal) {
                  for (var item in items) {
                    if (item.sourceType == QuoteItemSourceType.external) {
                      totalAvailableStock += item.quantity;
                      continue;
                    }
                    final vInfo = validationState.items[item.id];
                    // SYNC: Use fresh stock from validation if available
                    if (vInfo != null) {
                      totalAvailableStock += vInfo.currentStock;
                    } else if (item.sourceType ==
                        QuoteItemSourceType.external) {
                      totalAvailableStock += item.quantity;
                    } else {
                      // Fallback to model stock (usually null for loaded quotes)
                      totalAvailableStock +=
                          item.availableStock ?? double.infinity;
                    }

                    if (vInfo != null &&
                        vInfo.status != QuoteValidationStatus.ok) {
                      groupAlerts.add(vInfo.status);
                    }
                  }
                } else {
                  // Para productos temporales, el stock disponible es igual a la cantidad solicitada
                  for (var item in items) {
                    totalAvailableStock += item.quantity;
                  }
                }

                final bool hasOwnInventory = items.any(
                  (i) => i.sourceType == QuoteItemSourceType.own,
                );
                final bool hasSupplierInventory = items.any(
                  (i) => i.sourceType == QuoteItemSourceType.affiliated,
                );
                final bool isExternalManagement = items.any(
                  (i) => i.sourceType == QuoteItemSourceType.external,
                );

                return QuoteAddedProductCard(
                  name: groupName,
                  brand: firstItem.brand,
                  model: firstItem.model,
                  uom: firstItem.uom,
                  uomIconName: firstItem.uomIconName,
                  subtotal: subtotal,
                  totalQuantity: totalQuantity,
                  totalAvailableStock: totalAvailableStock,
                  hasOwnInventory: hasOwnInventory,
                  hasSupplierInventory: hasSupplierInventory,
                  isTemporal: isTemporal,
                  isExternalManagement: isExternalManagement,
                  isReadOnly: true,
                  alerts: groupAlerts.toList(),
                  onTap: () {
                    final List<ProductOrigin> origins = [];

                    for (final item in items) {
                      final String name;
                      final OriginType type;

                      switch (item.sourceType) {
                        case QuoteItemSourceType.own:
                          name = 'Inventario Propio';
                          type = OriginType.own;
                          break;
                        case QuoteItemSourceType.affiliated:
                          name = item.supplierName ?? 'Proveedor Afiliado';
                          type = OriginType.affiliated;
                          break;
                        case QuoteItemSourceType.external:
                          name =
                              item.externalProviderName ?? 'Proveedor Externo';
                          type = OriginType.external;
                          break;
                        case QuoteItemSourceType.temporal:
                          name =
                              (item.externalProviderName?.isNotEmpty ?? false)
                              ? item.externalProviderName!
                              : 'Temporal';
                          type = OriginType.temporal;
                          break;
                      }

                      // Para temporales y externos, el stock es igual a la cantidad (según requerimiento)
                      double itemStock = 0.0;
                      if (type == OriginType.temporal ||
                          type == OriginType.external) {
                        itemStock = item.quantity;
                      } else {
                        // SYNC: Leer stock fresco de la validación
                        final vInfo = validationState.items[item.id];
                        itemStock = vInfo != null
                            ? vInfo.currentStock
                            : (item.availableStock ?? 0.0);
                      }

                      final index = origins.indexWhere((o) => o.label == name);
                      if (index >= 0) {
                        origins[index] = origins[index].copyWith(
                          quantity: origins[index].quantity + item.quantity,
                          availableStock:
                              origins[index].availableStock + itemStock,
                        );
                      } else {
                        origins.add(
                          ProductOrigin(
                            type: type,
                            label: name,
                            quantity: item.quantity,
                            availableStock: itemStock,
                          ),
                        );
                      }
                    }

                    ViewProductDetailsSheet.show(
                      context,
                      productName: groupName,
                      brand: firstItem.brand,
                      model: firstItem.model,
                      uom: firstItem.uom,
                      uomIconName: firstItem.uomIconName,
                      averageCost: averageCost,
                      salePrice: firstItem.unitPrice,
                      origins: origins,
                      subtotal: subtotal,
                      totalQuantity: totalQuantity,
                      totalAvailableStock: totalAvailableStock,
                      hasOwnInventory: hasOwnInventory,
                      hasSupplierInventory: hasSupplierInventory,
                      isTemporal: isTemporal,
                      isExternalManagement: isExternalManagement,
                      alerts: groupAlerts.toList(),
                    );
                  },
                  onDelete: () {},
                  onEditPrice: () {},
                  onEditSources: () {},
                  onQuantityChanged: (_) {},
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
