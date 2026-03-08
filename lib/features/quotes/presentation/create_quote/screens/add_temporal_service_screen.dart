import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../shared/widgets/form_bottom_bar.dart';
import '../../../../../shared/widgets/custom_stepper.dart';
import '../../../data/models/quote_item_service.dart';
import '../providers/create_quote_provider.dart';
import '../../../../portfolio/presentation/providers/services_provider.dart';
import '../../../../portfolio/data/models/service_rate_model.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';
import '../../../../portfolio/data/models/delivery_time_model.dart';
import '../../../../../shared/utils/currency_formatter.dart';

class AddTemporalServiceScreen extends ConsumerStatefulWidget {
  final QuoteItemService? existingItem;

  const AddTemporalServiceScreen({super.key, this.existingItem});

  @override
  ConsumerState<AddTemporalServiceScreen> createState() =>
      _AddTemporalServiceScreenState();
}

class _AddTemporalServiceScreenState
    extends ConsumerState<AddTemporalServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');

  String? _selectedRate;

  // Prices
  final _costController = TextEditingController();
  final _marginController = TextEditingController();
  final _salePriceController = TextEditingController();

  // Settings
  bool _hasWarranty = true;
  final _warrantyQtyController = TextEditingController(text: '15');
  String _warrantyPeriod = 'Días';

  // Execution Time
  String? _selectedExecutionTimeId;

  bool _isOutsourced = false; // Based on screenshot
  bool _addToOwnServices = false;

  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingItem;
    if (existing != null) {
      _nameController.text = existing.name;
      _descriptionController.text = existing.description ?? '';
      _quantityController.text =
          existing.quantity.truncateToDouble() == existing.quantity
          ? existing.quantity.toInt().toString()
          : existing.quantity.toString();
      _selectedRate =
          existing.serviceRateId != null && existing.serviceRateId!.isNotEmpty
          ? existing.serviceRateId
          : null;
      _salePriceController.text = CurrencyFormatter.formatNumber(
        existing.unitPrice,
      );
      if (existing.costPrice > 0) {
        _isOutsourced = true;
        _costController.text = CurrencyFormatter.formatNumber(
          existing.costPrice,
        );
        _marginController.text = (existing.profitMargin * 100)
            .toStringAsFixed(2)
            .replaceAll('.', ',');
      } else {
        _isOutsourced = false;
      }
      if (existing.warrantyTime != null) {
        _hasWarranty = true;
        final parts = existing.warrantyTime!.split(' ');
        if (parts.length == 2) {
          _warrantyQtyController.text = parts[0];
          _warrantyPeriod = parts[1];
        }
      } else {
        _hasWarranty = false;
      }
      _selectedExecutionTimeId = existing.executionTimeId;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = ref.read(createQuoteProvider);
        _marginController.text = state.globalMargin
            .toStringAsFixed(2)
            .replaceAll('.', ',');
      });
    }

    _costController.addListener(_calculateSalePriceFromMargin);
    _marginController.addListener(_calculateSalePriceFromMargin);
    _quantityController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    _marginController.dispose();
    _salePriceController.dispose();
    _warrantyQtyController.dispose();
    super.dispose();
  }

  void _calculateSalePriceFromMargin() {
    if (_isCalculating || !_isOutsourced) return;
    _isCalculating = true;

    final cost = CurrencyFormatter.parse(_costController.text) ?? 0;
    final marginPercent =
        double.tryParse(_marginController.text.replaceAll(',', '.')) ?? 0;

    if (cost > 0) {
      final margin = marginPercent / 100;
      final salePrice = cost * (1 + margin);
      _salePriceController.text = CurrencyFormatter.formatNumber(salePrice);
    } else {
      _salePriceController.text = '';
    }

    _isCalculating = false;
  }

  void _calculateMarginFromSalePrice() {
    if (_isCalculating || !_isOutsourced) return;
    _isCalculating = true;

    final cost = CurrencyFormatter.parse(_costController.text) ?? 0;
    final salePrice = CurrencyFormatter.parse(_salePriceController.text) ?? 0;

    if (cost > 0 && salePrice > 0) {
      final margin = (salePrice - cost) / cost;
      _marginController.text = (margin * 100)
          .toStringAsFixed(2)
          .replaceAll('.', ',');
    } else {
      _marginController.text = '';
    }

    _isCalculating = false;
  }

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    final cost = _isOutsourced
        ? (CurrencyFormatter.parse(_costController.text) ?? 0)
        : 0.0;
    final qty =
        double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 1;
    final marginPercent =
        double.tryParse(_marginController.text.replaceAll(',', '.')) ?? 0;
    final margin = _isOutsourced ? (marginPercent / 100) : 0.0;

    final salePrice = CurrencyFormatter.parse(_salePriceController.text) ?? 0;

    final warrantyTime = _hasWarranty
        ? '${_warrantyQtyController.text} $_warrantyPeriod'
        : null;

    // In temporal services, we might not have a full UUID for serviceRateId, but we can store a string representation or leave null
    // Here we'll map the name to a dummy ID or just leave it null since it's draft.

    final rateSymbol =
        ref
            .read(serviceRatesProvider)
            .value
            ?.where((r) => r.id == _selectedRate)
            .firstOrNull
            ?.symbol ??
        'ud.';

    // Check if rate is time based
    final isTimeBased =
        rateSymbol.toLowerCase().contains('h') ||
        rateSymbol.toLowerCase().contains('dia') ||
        rateSymbol.toLowerCase().contains('día') ||
        rateSymbol.toLowerCase().contains('mes') ||
        rateSymbol.toLowerCase().contains('año');

    final item = QuoteItemService(
      id: widget.existingItem?.id ?? const Uuid().v4(),
      quoteId: 'draft',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      quantity: qty,
      costPrice: cost,
      profitMargin: margin,
      unitPrice: salePrice,
      taxRate: ref.read(createQuoteProvider).globalTaxRate,
      totalPrice: salePrice * qty,
      warrantyTime: warrantyTime,
      serviceRateId: _selectedRate ?? '',
      rateSymbol: rateSymbol,
      executionTimeId: isTimeBased ? null : _selectedExecutionTimeId,
    );

    if (widget.existingItem != null) {
      ref.read(createQuoteProvider.notifier).updateService(item);
    } else {
      ref.read(createQuoteProvider.notifier).addService(item);
    }

    if (_addToOwnServices) {
      try {
        await ref
            .read(servicesProvider.notifier)
            .addService(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              price: salePrice,
              serviceRateId: _selectedRate ?? '',
              categoryId: null,
              hasWarranty: _hasWarranty,
            );
      } catch (e) {
        debugPrint('Failed to add to own services: $e');
      }
    }

    if (mounted) {
      context.pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ratesAsync = ref.watch(serviceRatesProvider);
    final rates = ratesAsync.value ?? [];
    // Auto-select default rate on first load — prefer 'serv.'
    if (rates.isNotEmpty && _selectedRate == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final preferred = rates.firstWhere(
            (r) => r.symbol.toLowerCase().contains('serv'),
            orElse: () => rates.first,
          );
          setState(() => _selectedRate = preferred.id);
        }
      });
    }

    final selectedRateSymbol =
        rates.where((r) => r.id == _selectedRate).firstOrNull?.symbol ?? '';

    final isTimeBased =
        selectedRateSymbol.toLowerCase().contains('h') ||
        selectedRateSymbol.toLowerCase().contains('dia') ||
        selectedRateSymbol.toLowerCase().contains('día') ||
        selectedRateSymbol.toLowerCase().contains('mes') ||
        selectedRateSymbol.toLowerCase().contains('año');

    return Scaffold(
      appBar: StandardAppBar(
        title: widget.existingItem != null
            ? 'Modificar servicio temporal'
            : 'Agregar servicio temporal',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomTextField(
              controller: _nameController,
              label: 'Nombre del servicio*',
              hintText: 'Ej: Instalación de cámara de seguridad',
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _descriptionController,
              label: 'Descripción breve',
              maxLines: 4,
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _quantityController,
                    label: 'Cantidad*',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[.,]?\d*'),
                      ),
                    ],
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Requerido';
                      if (double.tryParse(v.replaceAll(',', '.')) == null) {
                        return 'Inválido';
                      }
                      if (double.parse(v.replaceAll(',', '.')) <= 0) {
                        return 'Mayor a 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomDropdown<String>(
                    value: _selectedRate,
                    items: rates.map((r) => r.id).toList(),
                    label: 'Tarifa por',
                    itemLabelBuilder: (String value) {
                      final rate = rates.firstWhere(
                        (r) => r.id == value,
                        orElse: () => const ServiceRate(
                          id: '',
                          name: 'Desconocido',
                          symbol: '',
                        ),
                      );
                      return '${rate.name} (${rate.symbol})';
                    },
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedRate = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Servicio tercerizado',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              value: _isOutsourced,
              onChanged: (v) => setState(() => _isOutsourced = v),
              activeThumbColor: colors.onPrimary,
              activeTrackColor: colors.primary,
            ),
            if (_isOutsourced) ...[
              const SizedBox(height: 16),
              CustomTextField(
                controller: _costController,
                label: 'Precio costo*',
                prefixText: '\$ ',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [CurrencyInputFormatter()],
                helperText: 'Sin impuesto',
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (CurrencyFormatter.parse(v) == null) return 'Inválido';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            Text(
              'Precio de venta',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: _isOutsourced
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isOutsourced) ...[
                  CustomStepper(
                    controller: _marginController,
                    label: 'Porcentaje',
                    prefixText: '%',
                    onIncrement: () {
                      final current =
                          double.tryParse(
                            _marginController.text.replaceAll(',', '.'),
                          ) ??
                          0;
                      _marginController.text = (current + 1)
                          .toStringAsFixed(2)
                          .replaceAll('.', ',');
                    },
                    onDecrement: () {
                      final current =
                          double.tryParse(
                            _marginController.text.replaceAll(',', '.'),
                          ) ??
                          0;
                      if (current >= 1) {
                        _marginController.text = (current - 1)
                            .toStringAsFixed(2)
                            .replaceAll('.', ',');
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: CustomTextField(
                    controller: _salePriceController,
                    label: 'Precio*',
                    prefixText: '\$ ',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [CurrencyInputFormatter()],
                    helperText: 'Sin impuesto',
                    onChanged: (_) => _calculateMarginFromSalePrice(),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Requerido' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'No ofrezco garantía para este servicio',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              value: !_hasWarranty,
              onChanged: (v) => setState(() => _hasWarranty = !v),
              activeThumbColor: colors.onPrimary,
              activeTrackColor: colors.primary,
            ),
            if (_hasWarranty) ...[
              const SizedBox(height: 8),
              Text(
                'Garantía',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _warrantyQtyController,
                      label: 'Cantidad*',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requerido' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomDropdown<String>(
                      value: _warrantyPeriod,
                      items: const ['Días', 'Meses', 'Años'],
                      label: 'Período',
                      itemLabelBuilder: (String value) => value,
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _warrantyPeriod = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            if (!isTimeBased) ...[
              const SizedBox(height: 8),
              Text(
                'Tiempo de ejecución',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 16),
              ref
                  .watch(deliveryTimesForExecutionProvider)
                  .when(
                    data: (executionTimes) {
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
              const SizedBox(height: 16),
            ],
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Incluir en servicios propios',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('(deberás completar otros datos luego).'),
              value: _addToOwnServices,
              onChanged: (v) => setState(() => _addToOwnServices = v),
              activeThumbColor: colors.onPrimary,
              activeTrackColor: colors.primary,
            ),
            const SizedBox(height: 32),
            Padding(
              padding: EdgeInsets.only(
                top: 16.0,
                bottom: MediaQuery.of(context).padding.bottom > 0
                    ? MediaQuery.of(context).padding.bottom
                    : 40.0,
              ),
              child: FormBottomBar(
                onCancel: () => context.pop(),
                onSave: _saveService,
                saveLabel:
                    'Confirmar (${_quantityController.text} $selectedRateSymbol)',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
