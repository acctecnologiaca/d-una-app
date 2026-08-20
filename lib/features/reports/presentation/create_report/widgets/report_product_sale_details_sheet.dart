import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_stepper.dart';
import '../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../portfolio/data/models/product_model.dart';
import '../providers/create_report_provider.dart';
import '../../../data/models/service_report_item_product.dart';

class ReportProductSaleDetailsSheet extends ConsumerStatefulWidget {
  final Product product;
  final ServiceReportCreateState reportState;
  final double selectedQuantity;
  final ServiceReportItemProduct? existingItem;

  const ReportProductSaleDetailsSheet({
    super.key,
    required this.product,
    required this.reportState,
    this.selectedQuantity = 1.0,
    this.existingItem,
  });

  static Future<ServiceReportItemProduct?> show(
    BuildContext context, {
    required Product product,
    required ServiceReportCreateState reportState,
    double selectedQuantity = 1.0,
    ServiceReportItemProduct? existingItem,
  }) {
    return showModalBottomSheet<ServiceReportItemProduct>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => ReportProductSaleDetailsSheet(
        product: product,
        reportState: reportState,
        selectedQuantity: selectedQuantity,
        existingItem: existingItem,
      ),
    );
  }

  @override
  ConsumerState<ReportProductSaleDetailsSheet> createState() =>
      _ReportProductSaleDetailsSheetState();
}

class _ReportProductSaleDetailsSheetState
    extends ConsumerState<ReportProductSaleDetailsSheet> {
  final _marginController = TextEditingController();
  final _priceController = TextEditingController();

  double _currentMargin = 25.0;
  double _currentPrice = 0.0;
  double _averageCost = 0.0;

  // Warranty
  bool _noWarranty = false;
  final _warrantyQtyController = TextEditingController(text: '12');
  String _warrantyPeriod = 'Meses';

  @override
  void initState() {
    super.initState();
    _averageCost = widget.product.averageCost;

    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _currentPrice = item.unitPrice;
      _currentMargin = item.profitMargin;
      _priceController.text = CurrencyFormatter.formatNumber(_currentPrice);
      _marginController.text = CurrencyFormatter.formatNumber(_currentMargin);

      if (item.warrantyTime != null && item.warrantyTime! > 0) {
        _warrantyQtyController.text = item.warrantyTime.toString();
        _warrantyPeriod = _warrantyUnitToDisplay(item.warrantyUnit);
        _noWarranty = false;
      } else {
        _noWarranty = true;
      }
    } else {
      _currentMargin = widget.reportState.globalMargin;
      _recalculatePriceFromMargin();
      _noWarranty = !widget.product.hasWarranty;
      _warrantyQtyController.text = '12';
      _warrantyPeriod = 'Meses';
    }
  }

  @override
  void dispose() {
    _marginController.dispose();
    _priceController.dispose();
    _warrantyQtyController.dispose();
    super.dispose();
  }

  void _recalculatePriceFromMargin() {
    // Markup: price = cost * (1 + margin / 100)
    _currentPrice = _averageCost * (1 + (_currentMargin / 100));
    _marginController.text = CurrencyFormatter.formatNumber(_currentMargin);
    _priceController.text = CurrencyFormatter.formatNumber(_currentPrice);
    setState(() {});
  }

  void _recalculateMarginFromPrice() {
    if (_averageCost > 0) {
      if (_currentPrice <= _averageCost) {
        _currentMargin = 0;
      } else {
        _currentMargin = ((_currentPrice / _averageCost) - 1) * 100;
      }
      _marginController.text = CurrencyFormatter.formatNumber(_currentMargin);
    } else {
      _currentMargin = 100.0;
      _marginController.text = CurrencyFormatter.formatNumber(_currentMargin);
    }
    setState(() {});
  }

  void _onMarginChanged(String value) {
    var margin = double.tryParse(value.replaceAll(',', '.')) ?? 0;
    _currentMargin = margin;
    _recalculatePriceFromMargin();
  }

  void _onPriceChanged(String value) {
    String cleanValue = value.replaceAll(RegExp(r'[^0-9,\.]'), '');
    if (cleanValue.contains('.') && cleanValue.contains(',')) {
      cleanValue = cleanValue.replaceAll('.', '').replaceAll(',', '.');
    } else {
      cleanValue = cleanValue.replaceAll(',', '.');
    }

    var price = double.tryParse(cleanValue) ?? 0;
    _currentPrice = price;
    _recalculateMarginFromPrice();
  }

  String _warrantyPeriodToDb(String displayPeriod) {
    return switch (displayPeriod) {
      'Días' => 'days',
      'Meses' => 'months',
      'Años' => 'years',
      _ => 'months',
    };
  }

  String _warrantyUnitToDisplay(String? dbUnit) {
    return switch (dbUnit) {
      'days' => 'Días',
      'months' => 'Meses',
      'years' => 'Años',
      _ => 'Meses',
    };
  }

  void _onConfirm() {
    final taxRate = widget.reportState.globalTaxRate;
    final qty = widget.selectedQuantity;
    final subtotal = _currentPrice * qty;
    final taxAmount = subtotal * (taxRate / 100);

    final item = ServiceReportItemProduct(
      id: widget.existingItem?.id ?? const Uuid().v4(),
      reportId: widget.reportState.report?.id ?? '',
      productId: widget.product.id,
      name: widget.product.name,
      brand: widget.product.brand?.name,
      model: widget.product.model,
      uom: widget.product.uom ?? 'ud.',
      uomIconName: widget.product.uomModel?.iconName,
      availableStock: widget.product.availableQuantity,
      quantity: qty,
      costPrice: _averageCost,
      profitMargin: _currentMargin,
      unitPrice: _currentPrice,
      taxRate: taxRate,
      taxAmount: taxAmount,
      totalPrice: subtotal,
      warrantyTime: _noWarranty ? null : int.tryParse(_warrantyQtyController.text),
      warrantyUnit: _noWarranty ? null : _warrantyPeriodToDb(_warrantyPeriod),
      sourceType: ReportProductSourceType.own,
      groupIndex: widget.existingItem?.groupIndex ?? widget.reportState.nextGroupIndex,
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final profitAmount = _currentPrice - _averageCost;
    final uom = widget.product.uom ?? 'ud.';

    return CustomActionSheet(
      title: 'Detalles de venta',
      showDivider: false,
      isContentScrollable: true,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 140,
              child: CustomButton(
                text: 'Confirmar',
                onPressed: _onConfirm,
              ),
            ),
          ),
        ),
      ],
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 8),
            // Costo promedio
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Costo promedio del producto',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message:
                      'Costo promedio = suma de todos los costos / suma de todas las cantidades',
                  triggerMode: TooltipTriggerMode.tap,
                  child: Icon(Icons.help, size: 16, color: colors.primary),
                ),
                Text(
                  ': ',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(_averageCost),
                  style: textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Margin & Price Controllers
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomStepper(
                  controller: _marginController,
                  label: 'Porcentaje',
                  prefixText: '%',
                  onChanged: _onMarginChanged,
                  onIncrement: () {
                    final current = double.tryParse(
                          _marginController.text.replaceAll(',', '.'),
                        ) ??
                        0;
                    _currentMargin = current + 1;
                    _recalculatePriceFromMargin();
                  },
                  onDecrement: () {
                    final current = double.tryParse(
                          _marginController.text.replaceAll(',', '.'),
                        ) ??
                        0;
                    if (current >= 1) {
                      _currentMargin = current - 1;
                      _recalculatePriceFromMargin();
                    }
                  },
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 144,
                  child: CustomTextField(
                    controller: _priceController,
                    label: 'Precio*',
                    prefixText: r'$ ',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [CurrencyInputFormatter()],
                    helperText: 'Sin impuesto',
                    onChanged: _onPriceChanged,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Precio de venta
            Text(
              'Precio de venta',
              style: textTheme.titleMedium?.copyWith(
                color: colors.onSurface,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              CurrencyFormatter.format(_currentPrice),
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
                fontSize: 28,
              ),
            ),

            const SizedBox(height: 16),

            // Profit pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surface.withAlpha(128),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ganancia: ',
                    style: textTheme.labelLarge?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${CurrencyFormatter.format(profitAmount)}/$uom',
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Divider(color: colors.outlineVariant),
            const SizedBox(height: 16),

            // --- WARRANTY SECTION ---
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Este producto no tiene garantía',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              value: _noWarranty,
              onChanged: (v) => setState(() => _noWarranty = v),
              activeThumbColor: colors.onPrimary,
              activeTrackColor: colors.primary,
            ),
            if (!_noWarranty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: colors.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Garantía',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _warrantyQtyController,
                      label: 'Cantidad',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDropdown<String>(
                      value: _warrantyPeriod,
                      items: const ['Días', 'Meses', 'Años'],
                      label: 'Período',
                      itemLabelBuilder: (v) => v,
                      onChanged: (v) {
                        if (v != null) setState(() => _warrantyPeriod = v);
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
