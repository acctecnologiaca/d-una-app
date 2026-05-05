import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_stepper.dart';
import '../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/create_quote_provider.dart';
import '../../../../portfolio/data/models/delivery_time_model.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';
import '../../../../../features/settings/presentation/widgets/add_edit_delivery_time_sheet.dart';

class QuoteProductSaleDetailsSheet extends ConsumerStatefulWidget {
  final double averageCost;
  final String productName;
  final String uom;
  final String? brand;
  final String? model;
  final double? initialPrice;
  final double? initialMargin;
  final String? initialDeliveryTimeId;
  final int? initialWarrantyTime;
  final String? initialWarrantyUnit;
  final int? suggestedWarrantyTime;
  final String? suggestedWarrantyUnit;
  final bool? isWarrantyExpired;
  final String? warrantySuggestionLabel;

  const QuoteProductSaleDetailsSheet({
    super.key,
    required this.averageCost,
    required this.productName,
    required this.uom,
    this.brand,
    this.model,
    this.initialPrice,
    this.initialMargin,
    this.initialDeliveryTimeId,
    this.initialWarrantyTime,
    this.initialWarrantyUnit,
    this.suggestedWarrantyTime,
    this.suggestedWarrantyUnit,
    this.isWarrantyExpired,
    this.warrantySuggestionLabel,
  });

  static Future<Map<String, dynamic>?> show(
    BuildContext context, {
    required double averageCost,
    required String productName,
    required String uom,
    String? brand,
    String? model,
    double? initialPrice,
    double? initialMargin,
    String? initialDeliveryTimeId,
    int? initialWarrantyTime,
    String? initialWarrantyUnit,
    int? suggestedWarrantyTime,
    String? suggestedWarrantyUnit,
    bool? isWarrantyExpired,
    String? warrantySuggestionLabel,
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
        uom: uom,
        brand: brand,
        model: model,
        initialPrice: initialPrice,
        initialMargin: initialMargin,
        initialDeliveryTimeId: initialDeliveryTimeId,
        initialWarrantyTime: initialWarrantyTime,
        initialWarrantyUnit: initialWarrantyUnit,
        suggestedWarrantyTime: suggestedWarrantyTime,
        suggestedWarrantyUnit: suggestedWarrantyUnit,
        isWarrantyExpired: isWarrantyExpired,
        warrantySuggestionLabel: warrantySuggestionLabel,
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

  // Warranty state
  bool _noWarranty = false;
  final _warrantyQtyController = TextEditingController(text: '30');
  String _warrantyPeriod = 'Meses';

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

    // Initialize warranty
    if (widget.initialWarrantyTime != null) {
      // 1. Explicit saved warranty
      _warrantyQtyController.text = widget.initialWarrantyTime.toString();
      _warrantyPeriod = _warrantyUnitToDisplay(widget.initialWarrantyUnit);
      _noWarranty = false;
    } else if (widget.initialPrice != null) {
      // 2. Editing an item that explicitly had no warranty (or was saved as null)
      _noWarranty = true;
    } else if (widget.suggestedWarrantyTime != null) {
      // 3. New item with a supplier suggestion
      _warrantyQtyController.text = widget.suggestedWarrantyTime.toString();
      _warrantyPeriod = _warrantyUnitToDisplay(widget.suggestedWarrantyUnit);
      _noWarranty = false;
    } else {
      // 4. Default for new items if no suggestion
      _noWarranty = false;
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

  Future<void> _showAddDeliveryTimeSheet() async {
    final newTime = await showModalBottomSheet<DeliveryTime>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => const AddEditDeliveryTimeSheet(),
    );

    if (newTime != null && mounted) {
      setState(() {
        _selectedDeliveryTimeId = newTime.id;
      });
      ref.invalidate(deliveryTimesProvider);
    }
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
      'warrantyTime': _noWarranty
          ? null
          : int.tryParse(_warrantyQtyController.text),
      'warrantyUnit': _noWarranty ? null : _warrantyPeriodToDb(_warrantyPeriod),
    });
  }

  String _warrantyPeriodToDb(String displayPeriod) {
    return switch (displayPeriod) {
      'Días' => 'days',
      'Meses' => 'months',
      'Años' => 'years',
      _ => 'days',
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
                    '${CurrencyFormatter.format(profitAmount)}/${widget.uom}',
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
              if (widget.isWarrantyExpired == true) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 14,
                      color: colors.error,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'La garantía original expiró. Puedes definir una a discreción.',
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.error,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else if (widget.warrantySuggestionLabel != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 14, color: colors.primary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        widget.warrantySuggestionLabel!,
                        style: textTheme.bodySmall?.copyWith(
                          color: colors.primary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],

            const SizedBox(height: 24),

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

                    return CustomDropdown<DeliveryTime>(
                      value:
                          deliveryTimes.any(
                            (e) => e.id == _selectedDeliveryTimeId,
                          )
                          ? deliveryTimes.firstWhere(
                              (e) => e.id == _selectedDeliveryTimeId,
                            )
                          : (deliveryTimes.isNotEmpty
                                ? deliveryTimes.first
                                : null),
                      items: deliveryTimes,
                      label: 'Tiempo de entrega',
                      searchable: true,
                      itemLabelBuilder: (dt) => dt.name,
                      onChanged: (val) {
                        if (val != null && val.id != '___ADD___') {
                          setState(() => _selectedDeliveryTimeId = val.id);
                        }
                      },
                      showAddOption: true,
                      addOptionLabel: 'Agregar tiempo de entrega',
                      addOptionValue: DeliveryTime(
                        id: '___ADD___',
                        name: '___ADD___',
                        unit: '',
                        type: '',
                        orderIdx: 0,
                      ),
                      onAddPressed: _showAddDeliveryTimeSheet,
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
