import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../portfolio/data/models/service_model.dart';
import '../../../data/models/quote_item_service.dart';
import '../../../../portfolio/data/models/delivery_time_model.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';
import '../providers/create_quote_provider.dart';
import '../../../../../features/settings/presentation/widgets/add_edit_delivery_time_sheet.dart';
import 'package:flutter/services.dart';

class QuoteServiceSaleDetailsSheet extends ConsumerStatefulWidget {
  final ServiceModel service;
  final double selectedQuantity;
  final QuoteItemService? existingItem;

  const QuoteServiceSaleDetailsSheet({
    super.key,
    required this.service,
    this.selectedQuantity = 1.0,
    this.existingItem,
  });

  static Future<QuoteItemService?> show(
    BuildContext context, {
    required ServiceModel service,
    double selectedQuantity = 1.0,
    QuoteItemService? existingItem,
  }) {
    return showModalBottomSheet<QuoteItemService?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => QuoteServiceSaleDetailsSheet(
        service: service,
        selectedQuantity: selectedQuantity,
        existingItem: existingItem,
      ),
    );
  }

  @override
  ConsumerState<QuoteServiceSaleDetailsSheet> createState() =>
      _QuoteServiceSaleDetailsSheetState();
}

class _QuoteServiceSaleDetailsSheetState
    extends ConsumerState<QuoteServiceSaleDetailsSheet> {
  final _descriptionController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _customPriceController = TextEditingController();

  double _quantity = 1.0;
  bool _modifyDescription = false;
  bool _modifyPrice = false;
  bool _isOutsourced = false;

  String? _selectedExecutionTimeId;

  // Warranty state
  bool _offerWarranty = false;
  final _warrantyQtyController = TextEditingController(text: '7');
  String _warrantyPeriod = 'Días';

  @override
  void initState() {
    super.initState();
    _quantity = widget.existingItem != null
        ? widget.existingItem!.quantity
        : widget.selectedQuantity;

    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _descriptionController.text =
          item.description ?? widget.service.description ?? '';
      _modifyDescription =
          item.description != null &&
          item.description != widget.service.description;

      _isOutsourced = item.costPrice > 0;
      _costPriceController.text = _isOutsourced
          ? CurrencyFormatter.formatNumber(item.costPrice)
          : '';

      _modifyPrice = item.unitPrice != widget.service.price;
      _customPriceController.text = CurrencyFormatter.formatNumber(
        item.unitPrice,
      );

      if (item.executionTimeId != null) {
        _selectedExecutionTimeId = item.executionTimeId;
      }
    } else {
      _descriptionController.text = widget.service.description ?? '';
      _costPriceController.text = '';
      _customPriceController.text = CurrencyFormatter.formatNumber(
        widget.service.price,
      );
    }

    // Initialize warranty
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      if (item.warrantyTime != null && item.warrantyTime! > 0) {
        _warrantyQtyController.text = item.warrantyTime.toString();
        _warrantyPeriod = _warrantyUnitToDisplay(item.warrantyUnit);
        _offerWarranty = true;
      } else {
        _warrantyQtyController.text = '7';
        _warrantyPeriod = 'Días';
        _offerWarranty = false;
      }
    } else if (widget.service.warrantyTime != null &&
        widget.service.warrantyTime! > 0) {
      _warrantyQtyController.text = widget.service.warrantyTime.toString();
      _warrantyPeriod = _warrantyUnitToDisplay(widget.service.warrantyUnit);
      _offerWarranty = widget.service.hasWarranty;
    } else {
      _warrantyQtyController.text = '7';
      _warrantyPeriod = 'Días';
      _offerWarranty = widget.service.hasWarranty;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _costPriceController.dispose();
    _customPriceController.dispose();
    _warrantyQtyController.dispose();
    super.dispose();
  }

  bool _isRateTimeBased() {
    final name = widget.service.serviceRate?.name.toLowerCase() ?? '';
    final symbol = widget.service.serviceRate?.symbol.toLowerCase() ?? '';
    return symbol == 'h' ||
        symbol == 'hr' ||
        symbol == 'hrs' ||
        name.contains('segundo') ||
        name.contains('minuto') ||
        name.contains('hora') ||
        name.contains('día') ||
        name.contains('dia') ||
        name.contains('mes') ||
        name.contains('año');
  }

  Future<void> _showAddExecutionTimeSheet() async {
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
        _selectedExecutionTimeId = newTime.id;
      });
      ref.invalidate(deliveryTimesProvider);
    }
  }

  void _onConfirm() {
    final finalCost = _isOutsourced
        ? (CurrencyFormatter.parse(_costPriceController.text) ?? 0.0)
        : 0.0;

    final finalDescription = _modifyDescription
        ? _descriptionController.text
        : widget.service.description;

    final finalUnitPrice = _modifyPrice
        ? (CurrencyFormatter.parse(_customPriceController.text) ??
              widget.service.price)
        : widget.service.price;

    final globalTaxRate = ref.read(createQuoteProvider).globalTaxRate;
    final taxRate = globalTaxRate / 100;
    final taxAmount = finalUnitPrice * taxRate;
    final unitPriceIncludingTax = finalUnitPrice + taxAmount;

    final executionTimes =
        ref.read(deliveryTimesForExecutionProvider).valueOrNull ?? [];
    final executionTimeLabel = executionTimes
        .where((e) => e.id == _selectedExecutionTimeId)
        .map((e) => e.name)
        .firstOrNull;

    final item = QuoteItemService(
      id: widget.existingItem?.id ?? '', // Preserved if modifying
      quoteId: widget.existingItem?.quoteId ?? '', // Preserved if modifying
      serviceId: widget.service.id,
      executionTimeId: _isRateTimeBased() ? null : _selectedExecutionTimeId,
      name: widget.service.name,
      description: finalDescription,
      quantity: _quantity,
      costPrice: finalCost,
      profitMargin: 0.0, // Assuming 0% for now
      unitPrice: finalUnitPrice,
      taxRate: globalTaxRate,
      taxAmount: taxAmount,
      totalPrice: unitPriceIncludingTax * _quantity,
      warrantyTime: _offerWarranty
          ? int.tryParse(_warrantyQtyController.text)
          : null,
      warrantyUnit: _offerWarranty
          ? _warrantyPeriodToDb(_warrantyPeriod)
          : null,
      rateSymbol: widget.service.serviceRate?.symbol ?? 'ud.',
      rateIconName: widget.service.serviceRate?.iconName,
      categoryName: widget.service.category?.name,
      executionTimeLabel: executionTimeLabel,
    );

    Navigator.of(context).pop(item);
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
    if (dbUnit == null) return 'Meses';
    final normalized = dbUnit.toLowerCase().trim();
    if (normalized == 'days' ||
        normalized == 'días' ||
        normalized == 'dias' ||
        normalized == 'dia') {
      return 'Días';
    }
    if (normalized == 'months' ||
        normalized == 'meses' ||
        normalized == 'mes') {
      return 'Meses';
    }
    if (normalized == 'years' || normalized == 'años' || normalized == 'año') {
      return 'Años';
    }
    return 'Meses';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final bool isTimeBased = _isRateTimeBased();

    return CustomActionSheet(
      title: 'Detalles del servicio',
      showDivider: false,
      isContentScrollable: true,
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 140,
              child: CustomButton(onPressed: _onConfirm, text: 'Confirmar'),
            ),
          ),
        ),
      ],
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isTimeBased) ...[
              // Tiempo de ejecución
              Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    color: colors.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Tiempo de ejecución',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ref
                  .watch(deliveryTimesForExecutionProvider)
                  .when(
                    data: (executionTimes) {
                      // Set initial value if not set and options exist
                      if (_selectedExecutionTimeId == null &&
                          executionTimes.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() {
                              _selectedExecutionTimeId =
                                  executionTimes.first.id;
                            });
                          }
                        });
                      }

                      return CustomDropdown<DeliveryTime>(
                        value:
                            executionTimes.any(
                              (e) => e.id == _selectedExecutionTimeId,
                            )
                            ? executionTimes.firstWhere(
                                (e) => e.id == _selectedExecutionTimeId,
                              )
                            : (executionTimes.isNotEmpty
                                  ? executionTimes.first
                                  : null),
                        items: executionTimes,
                        label: 'Seleccionar tiempo',
                        searchable: true,
                        itemLabelBuilder: (dt) => dt.name,
                        onChanged: (val) {
                          if (val != null && val.id != '___ADD___') {
                            setState(() => _selectedExecutionTimeId = val.id);
                          }
                        },
                        showAddOption: true,
                        addOptionLabel: 'Agregar tiempo de ejecución',
                        addOptionValue: DeliveryTime(
                          id: '___ADD___',
                          name: '___ADD___',
                          unit: '',
                          type: '',
                          orderIdx: 0,
                        ),
                        onAddPressed: _showAddExecutionTimeSheet,
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) => FriendlyErrorWidget(error: err),
                  ),
            ],

            const SizedBox(height: 24),
            // --- WARRANTY SECTION ---
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Ofrecer tiempo de garantía',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              value: _offerWarranty,
              onChanged: (v) => setState(() => _offerWarranty = v),
              activeThumbColor: colors.onPrimary,
              activeTrackColor: colors.primary,
            ),
            if (_offerWarranty) ...[
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

            // Servicio tercerizado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Servicio tercerizado',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _isOutsourced,
                  onChanged: (val) => setState(() => _isOutsourced = val),
                  activeTrackColor: colors.primary,
                ),
              ],
            ),
            if (_isOutsourced) ...[
              const SizedBox(height: 12),
              CustomTextField(
                controller: _costPriceController,
                label: 'Precio costo*',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                prefixIcon: const Icon(Icons.attach_money),
                inputFormatters: [CurrencyInputFormatter()],
              ),
              const SizedBox(height: 8),
              Text(
                'Sin impuesto',
                style: textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Modificar precio
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Modificar precio de venta',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _modifyPrice,
                  onChanged: (val) => setState(() => _modifyPrice = val),
                  activeTrackColor: colors.primary,
                ),
              ],
            ),
            if (_modifyPrice) ...[
              const SizedBox(height: 12),
              CustomTextField(
                controller: _customPriceController,
                label: 'Nuevo precio de venta*',
                prefixText: '\$ ',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [CurrencyInputFormatter()],
                helperText: 'Sin impuesto',
              ),
            ],
            const SizedBox(height: 24),

            // Modificar descripción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Modificar descripción del servicio',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: _modifyDescription,
                  onChanged: (val) => setState(() => _modifyDescription = val),
                  activeTrackColor: colors.primary,
                ),
              ],
            ),
            if (_modifyDescription) ...[
              const SizedBox(height: 12),
              CustomTextField(
                controller: _descriptionController,
                label: 'Descripción',
                maxLines: 4,
              ),
            ],

            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
