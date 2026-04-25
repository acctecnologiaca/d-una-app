import 'package:d_una_app/core/utils/string_extensions.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
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
import '../../../../../features/settings/presentation/widgets/add_edit_service_rate_sheet.dart';
import '../../../../../features/settings/presentation/widgets/add_edit_delivery_time_sheet.dart';
import '../../../../../shared/widgets/custom_dialog.dart';

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
  final _warrantyQtyController = TextEditingController(text: '7');
  String _warrantyPeriod = 'Días';

  // Execution Time
  String? _selectedExecutionTimeId;
  late final String _pricingMethod;

  bool _isOutsourced = false; // Based on screenshot
  bool _addToOwnServices = false;

  bool _isCalculating = false;

  // Seguimiento de valores originales para habilitar el botón "Confirmar"
  String _originalName = '';
  String _originalDescription = '';
  String _originalQty = '1';
  String? _originalRate;
  String _originalCost = '';
  String _originalMargin = '';
  String _originalSalePrice = '';
  bool _originalHasWarranty = true;
  String _originalWarrantyQty = '7';
  String _originalWarrantyPeriod = 'Días';
  String? _originalExecutionTimeId;
  bool _originalIsOutsourced = false;
  bool _originalAddToOwnServices = false;

  bool _alreadyInPortfolio = false;

  void _captureInitialValues() {
    _originalName = _nameController.text.trim();
    _originalDescription = _descriptionController.text.trim();
    _originalQty = _quantityController.text.trim();
    _originalRate = _selectedRate;
    _originalCost = _costController.text.trim();
    _originalMargin = _marginController.text.trim();
    _originalSalePrice = _salePriceController.text.trim();
    _originalHasWarranty = _hasWarranty;
    _originalWarrantyQty = _warrantyQtyController.text.trim();
    _originalWarrantyPeriod = _warrantyPeriod;
    _originalExecutionTimeId = _selectedExecutionTimeId;
    _originalIsOutsourced = _isOutsourced;
    _originalAddToOwnServices = _addToOwnServices;
    setState(() {}); // Refrescar para deshabilitar botón si es necesario
  }

  bool _hasChanges() {
    return _nameController.text.trim() != _originalName ||
        _descriptionController.text.trim() != _originalDescription ||
        _quantityController.text.trim() != _originalQty ||
        _selectedRate != _originalRate ||
        _costController.text.trim() != _originalCost ||
        _marginController.text.trim() != _originalMargin ||
        _salePriceController.text.trim() != _originalSalePrice ||
        _hasWarranty != _originalHasWarranty ||
        _warrantyQtyController.text.trim() != _originalWarrantyQty ||
        _warrantyPeriod != _originalWarrantyPeriod ||
        _selectedExecutionTimeId != _originalExecutionTimeId ||
        _isOutsourced != _originalIsOutsourced ||
        _addToOwnServices != _originalAddToOwnServices;
  }

  bool identityChangedFromService(
    QuoteItemService existing,
    String currentName,
    String currentRateId,
  ) {
    final nameChanged =
        existing.name.normalizeFingerprint != currentName.normalizeFingerprint;
    final rateChanged = (existing.serviceRateId ?? '') != currentRateId;
    return nameChanged || rateChanged;
  }

  void _checkPortfolioDuplicate() {
    final services = ref.read(servicesProvider).value ?? [];
    final currentName = _nameController.text.trim();
    if (currentName.isEmpty) {
      setState(() => _alreadyInPortfolio = false);
      return;
    }

    final duplicate = services.any((s) {
      final nameMatches =
          s.name.normalizeFingerprint == currentName.normalizeFingerprint;
      final rateMatches = s.serviceRateId == _selectedRate;
      return nameMatches && rateMatches;
    });

    setState(() {
      _alreadyInPortfolio = duplicate;
      // Solo forzar y bloquear si estamos EDITANDO un ítem que ya existe en la cotización
      if (duplicate && widget.existingItem != null) {
        _addToOwnServices = true;
      }
    });
  }

  void _showDuplicateDialog() {
    CustomDialog.show(
      context: context,
      dialog: CustomDialog.confirmation(
        title: 'Servicio duplicado',
        contentText:
            'Ya tienes un servicio con este mismo nombre y tarifa en tu portafolio. '
            'Usa el servicio existente para mantener la consistencia de tus precios.',
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

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
      _marginController.text = (existing.profitMargin * 100)
          .toStringAsFixed(2)
          .replaceAll('.', ',');

      if (existing.costPrice > 0) {
        _isOutsourced = true;
        _costController.text = CurrencyFormatter.formatNumber(
          existing.costPrice,
        );
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

    _pricingMethod = ref.read(createQuoteProvider).pricingMethod;

    _costController.addListener(_calculateSalePriceFromMargin);
    _marginController.addListener(_calculateSalePriceFromMargin);

    // Listeners para refrescar el estado del botón "Confirmar"
    _nameController.addListener(() {
      _checkPortfolioDuplicate();
      setState(() {});
    });
    _descriptionController.addListener(() => setState(() {}));
    _quantityController.addListener(() => setState(() {}));
    _salePriceController.addListener(() => setState(() {}));
    _warrantyQtyController.addListener(() => setState(() {}));

    // Captura inicial retrasada para esperar valores por defecto
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Si es nuevo, forzar margen global antes de capturar
        if (widget.existingItem == null) {
          final state = ref.read(createQuoteProvider);
          _marginController.text = state.globalMargin
              .toStringAsFixed(2)
              .replaceAll('.', ',');
        }

        // Intentar seleccionar tarifa por defecto si no existe
        final rates = ref.read(serviceRatesProvider).value ?? [];
        if (rates.isNotEmpty && _selectedRate == null) {
          final preferred = rates.firstWhere(
            (r) => r.symbol.toLowerCase().contains('serv'),
            orElse: () => rates.first,
          );
          _selectedRate = preferred.id;
          if (widget.existingItem == null) {
            _originalRate = _selectedRate;
          }
        }

        _checkPortfolioDuplicate();
        _captureInitialValues();
      }
    });
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
      double salePrice;
      if (_pricingMethod == 'margin') {
        // Margin: price = cost / (1 - margin)
        final factor = 1 - margin;
        salePrice = factor > 0 ? cost / factor : cost;
      } else {
        // Markup: price = cost * (1 + margin)
        salePrice = cost * (1 + margin);
      }
      _salePriceController.text = CurrencyFormatter.formatNumber(salePrice);
    } else {
      _salePriceController.text = '';
    }

    _isCalculating = false;
    setState(() {});
  }

  void _calculateMarginFromSalePrice() {
    if (_isCalculating || !_isOutsourced) return;
    _isCalculating = true;

    final cost = CurrencyFormatter.parse(_costController.text) ?? 0;
    final salePrice = CurrencyFormatter.parse(_salePriceController.text) ?? 0;

    if (cost > 0 && salePrice > 0) {
      double margin;
      if (_pricingMethod == 'margin') {
        // Margin: margin = (1 - cost/price)
        margin = 1 - (cost / salePrice);
      } else {
        // Markup: margin = (price - cost) / cost
        margin = (salePrice - cost) / cost;
      }
      _marginController.text = (margin * 100)
          .toStringAsFixed(2)
          .replaceAll('.', ',');
    } else {
      _marginController.text = '';
    }

    _isCalculating = false;
    setState(() {});
  }

  Future<void> _showAddRateDialog() async {
    final newRate = await showModalBottomSheet<ServiceRate>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => const AddEditServiceRateSheet(),
    );

    if (newRate != null && mounted) {
      setState(() {
        _selectedRate = newRate.id;
      });
      ref.invalidate(serviceRatesProvider);
    }
  }

  Future<void> _showAddExecutionTimeDialog() async {
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

  Future<void> _saveService() async {
    if (!_formKey.currentState!.validate()) return;

    // Validación de duplicados (GENERAL para proteger la cotización)
    if (widget.existingItem == null) {
      // Nuevo servicio
      if (_alreadyInPortfolio) {
        _showDuplicateDialog();
        return;
      }
    } else {
      // Edición de servicio existente
      if (identityChangedFromService(
        widget.existingItem!,
        _nameController.text.trim(),
        _selectedRate ?? '',
      )) {
        if (_alreadyInPortfolio) {
          _showDuplicateDialog();
          return;
        }
      }
    }

    final cost = _isOutsourced
        ? (CurrencyFormatter.parse(_costController.text) ?? 0)
        : 0.0;
    final qty =
        double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 1;
    final marginPercent =
        double.tryParse(_marginController.text.replaceAll(',', '.')) ?? 0;
    final margin = marginPercent / 100;

    double unitPrice;
    if (_isOutsourced) {
      if (_pricingMethod == 'margin') {
        final factor = 1 - margin;
        unitPrice = factor > 0 ? cost / factor : cost;
      } else {
        unitPrice = cost * (1 + margin);
      }
    } else {
      unitPrice = CurrencyFormatter.parse(_salePriceController.text) ?? 0;
    }

    final salePrice = unitPrice;

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

    final rateIconName = ref
        .read(serviceRatesProvider)
        .value
        ?.where((r) => r.id == _selectedRate)
        .firstOrNull
        ?.iconName;

    // Check if rate is time based
    final nameLower =
        (ref
                    .read(serviceRatesProvider)
                    .value
                    ?.where((r) => r.id == _selectedRate)
                    .firstOrNull
                    ?.name ??
                '')
            .toLowerCase();
    final symbolLower = rateSymbol.toLowerCase();

    final isTimeBased =
        symbolLower == 'h' ||
        symbolLower == 'hr' ||
        symbolLower == 'hrs' ||
        nameLower.contains('segundo') ||
        nameLower.contains('minuto') ||
        nameLower.contains('hora') ||
        nameLower.contains('dia') ||
        nameLower.contains('día') ||
        nameLower.contains('mes') ||
        nameLower.contains('año');

    final taxRate = ref.read(createQuoteProvider).globalTaxRate / 100;
    final taxAmount = salePrice * taxRate;
    final unitPriceIncludingTax = salePrice + taxAmount;

    final item = QuoteItemService(
      id: widget.existingItem?.id ?? const Uuid().v4(),
      quoteId: 'draft',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      quantity: qty,
      costPrice: cost,
      profitMargin: margin,
      unitPrice: salePrice,
      taxRate: taxRate * 100, // Storing as percentage like other items
      taxAmount: taxAmount,
      totalPrice: unitPriceIncludingTax * qty,
      warrantyTime: warrantyTime,
      serviceRateId: _selectedRate ?? '',
      rateSymbol: rateSymbol,
      rateIconName: rateIconName,
      executionTimeId: isTimeBased ? null : _selectedExecutionTimeId,
    );

    if (widget.existingItem != null) {
      ref.read(createQuoteProvider.notifier).updateService(item);
    } else {
      ref.read(createQuoteProvider.notifier).addService(item);
    }

    if (_addToOwnServices && !_alreadyInPortfolio) {
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
              warrantyTime: _hasWarranty
                  ? int.tryParse(_warrantyQtyController.text)
                  : null,
              warrantyUnit: _hasWarranty ? _warrantyPeriod : null,
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
    ref.listen(servicesProvider, (prev, next) {
      if (next is AsyncData) {
        _checkPortfolioDuplicate();
      }
    });

    final colors = Theme.of(context).colorScheme;
    final ratesAsync = ref.watch(serviceRatesProvider);
    final rates = ratesAsync.value ?? [];

    final selectedRateSymbol =
        rates.where((r) => r.id == _selectedRate).firstOrNull?.symbol ?? '';

    final selectedRate = rates.where((r) => r.id == _selectedRate).firstOrNull;
    final nameLower = (selectedRate?.name ?? '').toLowerCase();
    final symbolLower = (selectedRate?.symbol ?? '').toLowerCase();

    final isTimeBased =
        symbolLower == 'h' ||
        symbolLower == 'hr' ||
        symbolLower == 'hrs' ||
        nameLower.contains('segundo') ||
        nameLower.contains('minuto') ||
        nameLower.contains('hora') ||
        nameLower.contains('dia') ||
        nameLower.contains('día') ||
        nameLower.contains('mes') ||
        nameLower.contains('año');

    return PopScope(
      canPop: !_hasChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        final shouldPop = await CustomDialog.show<bool>(
          context: context,
          dialog: CustomDialog.destructive(
            title: '¿Descartar cambios?',
            contentText:
                'Hay cambios sin guardar en este servicio. ¿Estás seguro de que deseas salir y perder el progreso?',
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Continuar editando'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError,
                ),
                child: const Text('Descartar'),
              ),
            ],
          ),
        );

        if ((shouldPop ?? false) && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
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
              Text(
                'Usa este apartado solo para incluir servicios que no existan en tu portafolio aún.',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 24),
              CustomTextField(
                controller: _nameController,
                label: 'Nombre del servicio*',
                helperText: 'Ej: Servicio de mantenimiento preventivo',
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
                    flex: 1,
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
                    flex: 2,
                    child: CustomDropdown<ServiceRate>(
                      value: rates.any((r) => r.id == _selectedRate)
                          ? rates.firstWhere((r) => r.id == _selectedRate)
                          : (rates.isNotEmpty ? rates.first : null),
                      items: rates,
                      label: 'Tarifa por',
                      searchable: true,
                      itemLabelBuilder: (r) =>
                          '${r.name.toTitleCase} (${r.symbol})',
                      onChanged: (newValue) {
                        if (newValue != null && newValue.id != '___ADD___') {
                          setState(() {
                            _selectedRate = newValue.id;
                          });
                          _checkPortfolioDuplicate();
                        }
                      },
                      showAddOption: true,
                      addOptionLabel: 'Agregar tarifa',
                      addOptionValue: const ServiceRate(
                        id: '___ADD___',
                        name: '___ADD___',
                        symbol: '',
                      ),
                      onAddPressed: _showAddRateDialog,
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
                subtitle: Text(
                  'Otra persona lo haría por ti y te cobraría.',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
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
                                if (widget.existingItem == null) {
                                  _originalExecutionTimeId =
                                      _selectedExecutionTimeId;
                                }
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
                          onAddPressed: _showAddExecutionTimeDialog,
                        );
                      },
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => FriendlyErrorWidget(error: err),
                    ),
                const SizedBox(height: 16),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Incluir en servicios propios',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  (_alreadyInPortfolio && widget.existingItem != null)
                      ? 'Este servicio ya fue incluído en tu portafolio.'
                      : 'Luego deberás completar otros datos.',
                  style: TextStyle(
                    color: _alreadyInPortfolio
                        ? colors.primary
                        : colors.outline,
                    fontWeight: _alreadyInPortfolio ? FontWeight.bold : null,
                    fontSize: 12,
                  ),
                ),
                value: _addToOwnServices,
                onChanged: (_alreadyInPortfolio && widget.existingItem != null)
                    ? null
                    : (v) => setState(() => _addToOwnServices = v),
                activeThumbColor:
                    (_alreadyInPortfolio && widget.existingItem != null)
                    ? colors.outline.withValues(
                        alpha: 0.5,
                      ) // Color gris si está bloqueado
                    : colors.onPrimary,
                activeTrackColor:
                    (_alreadyInPortfolio && widget.existingItem != null)
                    ? colors.outline.withValues(
                        alpha: 0.2,
                      ) // Track gris si está bloqueado
                    : colors.primary,
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
                  onCancel: () => Navigator.maybePop(context),
                  onSave:
                      (_hasChanges() && _nameController.text.trim().isNotEmpty)
                      ? _saveService
                      : null,
                  saveLabel:
                      'Confirmar (${_quantityController.text} $selectedRateSymbol)',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
