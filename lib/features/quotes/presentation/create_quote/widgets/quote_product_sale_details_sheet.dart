import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_stepper.dart';
import '../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/create_quote_provider.dart';
import '../../../../portfolio/data/models/delivery_time_model.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';

class QuoteProductSaleDetailsSheet extends ConsumerStatefulWidget {
  final double averageCost;
  final String productName;
  final String? brand;
  final String? model;
  final double? initialPrice;
  final double? initialMargin;
  final String? initialDeliveryTimeId;

  const QuoteProductSaleDetailsSheet({
    super.key,
    required this.averageCost,
    required this.productName,
    this.brand,
    this.model,
    this.initialPrice,
    this.initialMargin,
    this.initialDeliveryTimeId,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required double averageCost,
    required String productName,
    String? brand,
    String? model,
    double? initialPrice,
    double? initialMargin,
    String? initialDeliveryTimeId,
  }) {
    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => QuoteProductSaleDetailsSheet(
        averageCost: averageCost,
        productName: productName,
        brand: brand,
        model: model,
        initialPrice: initialPrice,
        initialMargin: initialMargin,
        initialDeliveryTimeId: initialDeliveryTimeId,
      ),
    );
  }

  @override
  ConsumerState<QuoteProductSaleDetailsSheet> createState() =>
      _QuoteProductSaleDetailsSheetState();
}

class _QuoteProductSaleDetailsSheetState
    extends ConsumerState<QuoteProductSaleDetailsSheet> {
  final _marginController = TextEditingController();
  final _priceController = TextEditingController();

  double _currentMargin = 25.0; // Default margin
  double _currentPrice = 0.0;
  String? _selectedDeliveryTimeId;
  late final String _pricingMethod;

  @override
  void initState() {
    super.initState();
    _pricingMethod = ref.read(createQuoteProvider).pricingMethod;
    if (widget.initialPrice != null && widget.initialMargin != null) {
      _currentPrice = widget.initialPrice!;
      _currentMargin = widget.initialMargin! * 100;
      _priceController.text = CurrencyFormatter.formatNumber(_currentPrice);
      _marginController.text = CurrencyFormatter.formatNumber(_currentMargin);
      _selectedDeliveryTimeId = widget.initialDeliveryTimeId;
    } else {
      _currentMargin = ref.read(createQuoteProvider).globalMargin;
      _recalculatePriceFromMargin();
    }
  }

  @override
  void dispose() {
    _marginController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _recalculatePriceFromMargin() {
    if (_pricingMethod == 'margin') {
      // Margin: price = cost / (1 - margin/100)
      final factor = 1 - (_currentMargin / 100);
      _currentPrice = factor > 0
          ? widget.averageCost / factor
          : widget.averageCost;
    } else {
      // Markup: price = cost * (1 + margin/100)
      _currentPrice = widget.averageCost * (1 + (_currentMargin / 100));
    }
    _marginController.text = CurrencyFormatter.formatNumber(_currentMargin);
    _priceController.text = CurrencyFormatter.formatNumber(_currentPrice);
    setState(() {});
  }

  void _recalculateMarginFromPrice() {
    if (widget.averageCost > 0) {
      if (_currentPrice <= widget.averageCost) {
        _currentMargin = 0;
      } else if (_pricingMethod == 'margin') {
        // Margin: margin% = (1 - cost/price) * 100
        _currentMargin = (1 - (widget.averageCost / _currentPrice)) * 100;
      } else {
        // Markup: margin% = (price/cost - 1) * 100
        _currentMargin = ((_currentPrice / widget.averageCost) - 1) * 100;
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
    // Clean string by removing currency symbols and spaces
    String cleanValue = value.replaceAll(RegExp(r'[^0-9,\.]'), '');

    // Attempt to handle format like 1.000,50
    if (cleanValue.contains('.') && cleanValue.contains(',')) {
      cleanValue = cleanValue.replaceAll('.', '').replaceAll(',', '.');
    } else {
      cleanValue = cleanValue.replaceAll(',', '.');
    }

    var price = double.tryParse(cleanValue) ?? 0;
    _currentPrice = price;
    _recalculateMarginFromPrice();
  }

  void _onConfirm() {
    String? deliveryTimeId = _selectedDeliveryTimeId;
    if (deliveryTimeId == null) {
      final list = ref.read(deliveryTimesForDeliveryProvider).valueOrNull;
      if (list != null && list.isNotEmpty) {
        deliveryTimeId = list.first.id;
      }
    }

    Navigator.of(context).pop({
      'sellingPrice': _currentPrice,
      'profitMargin': _currentMargin / 100, // as decimal
      'taxRate':
          ref.read(createQuoteProvider).globalTaxRate / 100, // as decimal
      'deliveryTimeId': deliveryTimeId,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final profitAmount = _currentPrice - widget.averageCost;

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
              child: CustomButton(text: 'Confirmar', onPressed: _onConfirm),
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
                  CurrencyFormatter.format(widget.averageCost),
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
                    final current =
                        double.tryParse(
                          _marginController.text.replaceAll(',', '.'),
                        ) ??
                        0;
                    _currentMargin = current + 1;
                    _recalculatePriceFromMargin();
                  },
                  onDecrement: () {
                    final current =
                        double.tryParse(
                          _marginController.text.replaceAll(',', '.'),
                        ) ??
                        0;
                    if (current >= 1) {
                      _currentMargin = current - 1;
                      _recalculatePriceFromMargin();
                    }
                  },
                ),
                const SizedBox(width: 4),
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
                    '${CurrencyFormatter.format(profitAmount)}/ud.',
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

            // Delivery Time (moved from actions to content)
            Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Tiempo de entrega',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ref
                .watch(deliveryTimesForDeliveryProvider)
                .when(
                  data: (deliveryTimes) {
                    if (_selectedDeliveryTimeId == null &&
                        deliveryTimes.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _selectedDeliveryTimeId == null) {
                          setState(() {
                            _selectedDeliveryTimeId = deliveryTimes.first.id;
                          });
                        }
                      });
                    }

                    return CustomDropdown<String>(
                      value: _selectedDeliveryTimeId,
                      items: deliveryTimes.map((e) => e.id).toList(),
                      label: 'Tiempo de entrega',
                      itemLabelBuilder: (id) {
                        final dt = deliveryTimes.firstWhere(
                          (e) => e.id == id,
                          orElse: () => DeliveryTime(
                            id: '',
                            name: 'Desconocido',
                            unit: 'days',
                            type: 'delivery',
                            orderIdx: 0,
                          ),
                        );
                        return dt.name;
                      },
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedDeliveryTimeId = val);
                        }
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => FriendlyErrorWidget(error: err),
                ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
