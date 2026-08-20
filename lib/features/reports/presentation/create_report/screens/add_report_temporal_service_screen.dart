import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../shared/widgets/form_bottom_bar.dart';
import '../../../../../shared/widgets/custom_stepper.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../../../../shared/widgets/friendly_error_widget.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../portfolio/data/models/service_rate_model.dart';
import '../../../../portfolio/data/models/delivery_time_model.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';
import '../../../../portfolio/presentation/providers/services_provider.dart';
import '../../../../settings/presentation/widgets/add_edit_service_rate_sheet.dart';
import '../../../../settings/presentation/widgets/add_edit_delivery_time_sheet.dart';
import '../../../data/models/service_report_item_service.dart';
import '../providers/create_report_provider.dart';

class AddReportTemporalServiceScreen extends ConsumerStatefulWidget {
  final ServiceReportItemService? existingItem;

  const AddReportTemporalServiceScreen({super.key, this.existingItem});

  @override
  ConsumerState<AddReportTemporalServiceScreen> createState() =>
      _AddReportTemporalServiceScreenState();
}

class _AddReportTemporalServiceScreenState
    extends ConsumerState<AddReportTemporalServiceScreen> {
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

  bool _isOutsourced = false;
  bool _addToOwnServices = false;
  bool _alreadyInPortfolio = false;
  bool _isCalculating = false;

  // Seguimiento de valores originales para validación de cambios
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
    setState(() {});
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

  bool _identityChangedFromService(
    ServiceReportItemService existing,
    String currentName,
    String currentRateSymbol,
  ) {
    final nameChanged =
        existing.name.normalizeFingerprint != currentName.normalizeFingerprint;
    final rateChanged = existing.rateSymbol != currentRateSymbol;
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

      final rates = ref.read(serviceRatesProvider).value ?? [];
      final match = rates.firstWhere(
        (r) => r.symbol == existing.rateSymbol,
        orElse: () => rates.isNotEmpty
            ? rates.first
            : ServiceRate(id: '', name: '', symbol: 'ud.'),
      );
      _selectedRate = match.id.isNotEmpty ? match.id : null;
      _salePriceController.text = CurrencyFormatter.formatNumber(
        existing.unitPrice,
      );
      _marginController.text = (existing.profitMargin)
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
        _warrantyQtyController.text = existing.warrantyTime.toString();
        _warrantyPeriod = switch (existing.warrantyUnit) {
          'days' => 'Días',
          'months' => 'Meses',
          'years' => 'Años',
          _ => 'Días',
        };
      } else {
        _hasWarranty = false;
      }
      _selectedExecutionTimeId = existing.executionTimeId;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final state = ref.read(createReportProvider);
        _marginController.text =
            state.globalMargin.toStringAsFixed(2).replaceAll('.', ',');
      });
    }

    _costController.addListener(_calculateSalePriceFromMargin);
    _marginController.addListener(_calculateSalePriceFromMargin);

    _nameController.addListener(() {
      _checkPortfolioDuplicate();
      setState(() {});
    });
    _descriptionController.addListener(() => setState(() {}));
    _quantityController.addListener(() => setState(() {}));
    _salePriceController.addListener(() => setState(() {}));
    _warrantyQtyController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (widget.existingItem == null) {
          final state = ref.read(createReportProvider);
          _marginController.text =
              state.globalMargin.toStringAsFixed(2).replaceAll('.', ',');
        }

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
    _costController.removeListener(_calculateSalePriceFromMargin);
    _marginController.removeListener(_calculateSalePriceFromMargin);
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
    setState(() {});
  }

  void _calculateMarginFromSalePrice() {
    if (_isCalculating || !_isOutsourced) return;
    _isCalculating = true;

    final cost = CurrencyFormatter.parse(_costController.text) ?? 0;
    final salePrice = CurrencyFormatter.parse(_salePriceController.text) ?? 0;

    if (cost > 0 && salePrice > 0) {
      final margin = (salePrice - cost) / cost;
      _marginController.text =
          (margin * 100).toStringAsFixed(2).replaceAll('.', ',');
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

    final reportState = ref.read(createReportProvider);
    final rates = ref.read(serviceRatesProvider).value ?? [];
    final selectedRateModel =
        rates.where((r) => r.id == _selectedRate).firstOrNull;

    final rateSymbol = selectedRateModel?.symbol ?? 'ud.';
    final rateIconName = selectedRateModel?.iconName;

    // Validación de duplicados en portafolio
    if (widget.existingItem == null) {
      if (_alreadyInPortfolio) {
        _showDuplicateDialog();
        return;
      }
    } else {
      if (_identityChangedFromService(
        widget.existingItem!,
        _nameController.text.trim(),
        rateSymbol,
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
      unitPrice = cost * (1 + margin);
    } else {
      unitPrice = CurrencyFormatter.parse(_salePriceController.text) ?? 0;
    }

    final salePrice = unitPrice;

    final int? warrantyTime =
        _hasWarranty ? int.tryParse(_warrantyQtyController.text) : null;
    final String? warrantyUnit = _hasWarranty
        ? switch (_warrantyPeriod) {
            'Días' => 'days',
            'Meses' => 'months',
            'Años' => 'years',
            _ => 'days',
          }
        : null;

    final nameLower = (selectedRateModel?.name ?? '').toLowerCase();
    final symbolLower = rateSymbol.toLowerCase();

    final isTimeBased = symbolLower == 'h' ||
        symbolLower == 'hr' ||
        symbolLower == 'hrs' ||
        nameLower.contains('segundo') ||
        nameLower.contains('minuto') ||
        nameLower.contains('hora') ||
        nameLower.contains('dia') ||
        nameLower.contains('día') ||
        nameLower.contains('mes') ||
        nameLower.contains('año');

    final taxRate = reportState.globalTaxRate / 100;
    final taxAmount = (salePrice * qty) * taxRate;
    final totalPrice = salePrice * qty;

    final executionTimes =
        ref.read(deliveryTimesForExecutionProvider).valueOrNull ?? [];
    final executionTimeLabel = executionTimes
        .where((e) => e.id == _selectedExecutionTimeId)
        .map((e) => e.name)
        .firstOrNull;

    if (_addToOwnServices && !_alreadyInPortfolio) {
      try {
        await ref.read(servicesProvider.notifier).addService(
              name: _nameController.text.trim(),
              description: _descriptionController.text.trim(),
              price: salePrice,
              serviceRateId: _selectedRate ?? '',
              categoryId: null,
              hasWarranty: _hasWarranty,
              warrantyTime: warrantyTime,
              warrantyUnit: warrantyUnit,
            );
      } catch (e) {
        debugPrint('Failed to add to own services: $e');
      }
    }

    final item = ServiceReportItemService(
      id: widget.existingItem?.id ?? const Uuid().v4(),
      reportId: reportState.report?.id ?? '',
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : null,
      quantity: qty,
      costPrice: cost,
      profitMargin: marginPercent,
      unitPrice: salePrice,
      taxRate: reportState.globalTaxRate,
      taxAmount: taxAmount,
      totalPrice: totalPrice,
      warrantyTime: warrantyTime,
      warrantyUnit: warrantyUnit,
      rateSymbol: rateSymbol,
      rateIconName: rateIconName,
      executionTimeId: isTimeBased ? null : _selectedExecutionTimeId,
      executionTimeLabel: executionTimeLabel,
      orderIndex:
          widget.existingItem?.orderIndex ?? reportState.nextGroupIndex,
    );

    if (mounted) {
      context.pop(item);
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

    final selectedRate = rates.where((r) => r.id == _selectedRate).firstOrNull;
    final selectedRateSymbol = selectedRate?.symbol ?? '';
    final nameLower = (selectedRate?.name ?? '').toLowerCase();
    final symbolLower = (selectedRate?.symbol ?? '').toLowerCase();

    final isTimeBased = symbolLower == 'h' ||
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
                        final current = double.tryParse(
                              _marginController.text.replaceAll(',', '.'),
                            ) ??
                            0;
                        _marginController.text = (current + 1)
                            .toStringAsFixed(2)
                            .replaceAll('.', ',');
                      },
                      onDecrement: () {
                        final current = double.tryParse(
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
                ref.watch(deliveryTimesForExecutionProvider).when(
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
                          value: executionTimes.any(
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
                              setState(
                                  () => _selectedExecutionTimeId = val.id);
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
                        ? colors.outline.withValues(alpha: 0.5)
                        : colors.onPrimary,
                activeTrackColor:
                    (_alreadyInPortfolio && widget.existingItem != null)
                        ? colors.outline.withValues(alpha: 0.2)
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
