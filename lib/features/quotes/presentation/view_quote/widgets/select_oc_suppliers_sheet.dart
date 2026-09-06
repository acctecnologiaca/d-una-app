import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:d_una_app/shared/widgets/custom_extended_fab.dart';
import 'package:d_una_app/features/supplier_orders/domain/models/quote_supplier_oc_status.dart';

class OcSupplierSelectionResult {
  final List<String> selectedSupplierIds;
  final Map<String, bool> supplierDestinations; // supplierId -> isDropshipping (true = cliente, false = propia)

  const OcSupplierSelectionResult({
    required this.selectedSupplierIds,
    required this.supplierDestinations,
  });
}

class SelectOcSuppliersSheet extends StatefulWidget {
  final List<QuoteSupplierOcStatus> suppliers;
  final ValueChanged<OcSupplierSelectionResult> onConfirm;

  const SelectOcSuppliersSheet({
    super.key,
    required this.suppliers,
    required this.onConfirm,
  });

  static Future<OcSupplierSelectionResult?> show({
    required BuildContext context,
    required List<QuoteSupplierOcStatus> suppliers,
  }) async {
    return showModalBottomSheet<OcSupplierSelectionResult>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => SelectOcSuppliersSheet(
        suppliers: suppliers,
        onConfirm: (result) {
          Navigator.of(context).pop(result);
        },
      ),
    );
  }

  @override
  State<SelectOcSuppliersSheet> createState() => _SelectOcSuppliersSheetState();
}

class _SelectOcSuppliersSheetState extends State<SelectOcSuppliersSheet> {
  final Set<String> _selectedSupplierIds = {};
  final Map<String, bool> _supplierDestinations = {};

  @override
  void initState() {
    super.initState();
    for (final s in widget.suppliers) {
      if (!s.hasExistingOc) {
        _selectedSupplierIds.add(s.supplierId);
      }
      _supplierDestinations[s.supplierId] = false; // default: Recepción propia
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final currencyFormat = NumberFormat.currency(
      symbol: '\$',
      decimalDigits: 2,
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHandle(),
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Selecciona los proveedores a los cuales deseas generar una orden de compra y quién recibirá la mercancía.',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: widget.suppliers.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: colors.outlineVariant.withValues(alpha: 0.3)),
                    itemBuilder: (context, index) {
                      final supplier = widget.suppliers[index];
                      final isSelected = _selectedSupplierIds.contains(
                        supplier.supplierId,
                      );
                      final isDisabled = supplier.hasExistingOc;
                      final firstLetter = supplier.supplierName.isNotEmpty
                          ? supplier.supplierName[0].toUpperCase()
                          : '?';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CheckboxListTile(
                            value: isDisabled ? false : isSelected,
                            enabled: !isDisabled,
                            controlAffinity: ListTileControlAffinity.trailing,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 4,
                            ),
                            secondary: CircleAvatar(
                              backgroundColor: isDisabled
                                  ? colors.surfaceContainerHigh
                                  : colors.secondaryContainer,
                              child: Text(
                                firstLetter,
                                style: TextStyle(
                                  color: isDisabled
                                      ? colors.onSurfaceVariant.withValues(
                                          alpha: 0.5,
                                        )
                                      : colors.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            activeColor: colors.primary,
                            onChanged: isDisabled
                                ? null
                                : (checked) {
                                    setState(() {
                                      if (checked == true) {
                                        _selectedSupplierIds.add(
                                          supplier.supplierId,
                                        );
                                      } else {
                                        _selectedSupplierIds.remove(
                                          supplier.supplierId,
                                        );
                                      }
                                    });
                                  },
                            title: Text(
                              supplier.supplierName,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDisabled
                                    ? colors.onSurface.withValues(alpha: 0.5)
                                    : colors.onSurface,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '${supplier.itemCount} ${supplier.itemCount == 1 ? 'producto' : 'productos'} • ${currencyFormat.format(supplier.total)}',
                                  style: TextStyle(
                                    color: isDisabled
                                        ? colors.onSurfaceVariant.withValues(
                                            alpha: 0.5,
                                          )
                                        : colors.onSurfaceVariant,
                                    fontSize: 13,
                                  ),
                                ),
                                if (isDisabled) ...[
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.surfaceContainerHigh,
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(
                                        color: colors.outlineVariant.withValues(
                                          alpha: 0.5,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      'OC emitida: ${supplier.existingOrderNumber ?? 'Existente'}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.onSurfaceVariant,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          if (isSelected && !isDisabled)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(72, 0, 24, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '¿Quién recibe la mercancía?',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: colors.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  SizedBox(
                                    width: double.infinity,
                                    child: SegmentedButton<bool>(
                                      segments: [
                                        const ButtonSegment<bool>(
                                          value: false,
                                          label: Text(
                                            'Recepción propia',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          icon: Icon(Icons.storefront_outlined, size: 16),
                                        ),
                                        ButtonSegment<bool>(
                                          value: true,
                                          label: const Text(
                                            'Envío al cliente',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          icon: const Icon(Icons.local_shipping_outlined, size: 16),
                                          enabled: supplier.allowsDropshipping,
                                        ),
                                      ],
                                      selected: {
                                        _supplierDestinations[supplier.supplierId] ?? false,
                                      },
                                      onSelectionChanged: (newSelection) {
                                        setState(() {
                                          _supplierDestinations[supplier.supplierId] =
                                              newSelection.first;
                                        });
                                      },
                                      style: SegmentedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ),
                                  if (!supplier.allowsDropshipping) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Este proveedor no admite envíos directos al cliente.',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: colors.error,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
            if (_selectedSupplierIds.isNotEmpty)
              Positioned(
                bottom: 24,
                right: 16,
                child: CustomExtendedFab(
                  onPressed: () {
                    widget.onConfirm(
                      OcSupplierSelectionResult(
                        selectedSupplierIds: _selectedSupplierIds.toList(),
                        supplierDestinations: _supplierDestinations,
                      ),
                    );
                  },
                  label: 'Generar (${_selectedSupplierIds.length})',
                  icon: Icons.check,
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        height: 4,
        width: 32,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Text(
            'Generar órdenes de compra',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
