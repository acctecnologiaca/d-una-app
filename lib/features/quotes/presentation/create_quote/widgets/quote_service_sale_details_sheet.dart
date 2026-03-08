import 'package:flutter/material.dart';
import '../../../../../shared/widgets/custom_button.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../../shared/widgets/custom_stepper.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../portfolio/data/models/service_model.dart';
import '../../../data/models/quote_item_service.dart';
import '../../../../portfolio/data/models/delivery_time_model.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';

class QuoteServiceSaleDetailsSheet extends ConsumerStatefulWidget {
  final ServiceModel service;
  final QuoteItemService? existingItem;

  const QuoteServiceSaleDetailsSheet({
    super.key,
    required this.service,
    this.existingItem,
  });

  static Future<QuoteItemService?> show(
    BuildContext context, {
    required ServiceModel service,
    QuoteItemService? existingItem,
  }) {
    return showModalBottomSheet<QuoteItemService?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: QuoteServiceSaleDetailsSheet(
          service: service,
          existingItem: existingItem,
        ),
      ),
    );
  }

  @override
  ConsumerState<QuoteServiceSaleDetailsSheet> createState() =>
      _QuoteServiceSaleDetailsSheetState();
}

class _QuoteServiceSaleDetailsSheetState
    extends ConsumerState<QuoteServiceSaleDetailsSheet> {
  final _quantityController = TextEditingController(text: '1');
  final _descriptionController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _customPriceController = TextEditingController();

  double _quantity = 1.0;
  bool _modifyDescription = false;
  bool _modifyPrice = false;
  bool _isOutsourced = false;

  String? _selectedExecutionTimeId;

  @override
  void initState() {
    super.initState();
    if (widget.existingItem != null) {
      final item = widget.existingItem!;
      _quantity = item.quantity;
      _quantityController.text = _quantity.truncateToDouble() == _quantity
          ? _quantity.toInt().toString()
          : _quantity.toStringAsFixed(1);

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
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _customPriceController.dispose();
    super.dispose();
  }

  bool _isRateTimeBased() {
    final rateName = widget.service.serviceRate?.name.toLowerCase() ?? '';
    return rateName.contains('hora') ||
        rateName.contains('h') ||
        rateName.contains('día') ||
        rateName.contains('dia') ||
        rateName.contains('mes') ||
        rateName.contains('año');
  }

  String _getRateLabel() {
    final rateName = widget.service.serviceRate?.name.toLowerCase() ?? 'ud.';
    if (rateName.contains('hora') || rateName.contains('h')) return 'Horas';
    if (rateName.contains('día') || rateName.contains('dia')) return 'Días';
    if (rateName.contains('mes')) return 'Meses';
    if (rateName.contains('serv')) return 'Serv.';
    return 'Ud.';
  }

  String _getRateSuffix() {
    final rateName = widget.service.serviceRate?.name.toLowerCase() ?? 'ud.';
    if (rateName.contains('hora') || rateName.contains('h')) return '/h';
    if (rateName.contains('día') || rateName.contains('dia')) return '/dia';
    if (rateName.contains('mes')) return '/mes';
    if (rateName.contains('serv')) return '/serv.';
    return '/ud.';
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

    final item = QuoteItemService(
      id: widget.existingItem?.id ?? '', // Preserved if modifying
      quoteId: widget.existingItem?.quoteId ?? '', // Preserved if modifying
      serviceId: widget.service.id,
      serviceRateId: widget.service.serviceRateId,
      executionTimeId: _isRateTimeBased() ? null : _selectedExecutionTimeId,
      name: widget.service.name,
      description: finalDescription,
      quantity: _quantity,
      costPrice: finalCost,
      profitMargin: 0.0, // Assuming 0% for now
      unitPrice: finalUnitPrice,
      taxRate: 0.0, // Replace with proper tax rate if needed
      totalPrice: finalUnitPrice * _quantity,
      warrantyTime: widget.service.warrantyTime?.toString(),
    );

    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final rateLabel = _getRateLabel();
    final bool isTimeBased = _isRateTimeBased();

    return CustomActionSheet(
      title: 'Servicio a agregar',
      showDivider: false,
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
            // Service Info Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.service.name,
                        style: textTheme.titleMedium?.copyWith(
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.service.category?.name ?? 'Sin categoría',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${CurrencyFormatter.format(widget.service.price)}${_getRateSuffix()}',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: colors.outlineVariant, height: 1),
            const SizedBox(height: 16),

            // Cantidad
            Row(
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  color: colors.onSurfaceVariant,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Cantidad',
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Center(
              child: CustomStepper(
                controller: _quantityController,
                label: rateLabel,
                onIncrement: () {
                  setState(() {
                    _quantity++;
                    _quantityController.text = _quantity.toInt().toString();
                  });
                },
                onDecrement: () {
                  if (_quantity > 1) {
                    setState(() {
                      _quantity--;
                      _quantityController.text = _quantity.toInt().toString();
                    });
                  }
                },
                onChanged: (val) {
                  setState(() {
                    _quantity = double.tryParse(val) ?? 0;
                  });
                },
              ),
            ),
            if (!isTimeBased) ...[
              const SizedBox(height: 24),
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

                      return CustomDropdown<String>(
                        value: _selectedExecutionTimeId,
                        items: executionTimes.map((e) => e.id).toList(),
                        label: 'Seleccionar tiempo',
                        itemLabelBuilder: (id) {
                          final dt = executionTimes.firstWhere(
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
                            setState(() => _selectedExecutionTimeId = val);
                          }
                        },
                      );
                    },
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (err, stack) =>
                        Text('Error al cargar tiempos de ejecución: $err'),
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
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
