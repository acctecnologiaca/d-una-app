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
import '../../../../../features/portfolio/presentation/providers/lookup_providers.dart';
import '../../../../../features/portfolio/data/models/delivery_time_model.dart';
import '../../../data/models/quote_item_product.dart';
import '../providers/create_quote_provider.dart';
import '../../../../../features/portfolio/data/models/product_model.dart';
import '../../../../../features/portfolio/presentation/providers/products_provider.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../features/settings/presentation/widgets/add_edit_brand_sheet.dart';

class AddTemporalProductScreen extends ConsumerStatefulWidget {
  final QuoteItemProduct? existingItem;

  const AddTemporalProductScreen({super.key, this.existingItem});

  @override
  ConsumerState<AddTemporalProductScreen> createState() =>
      _AddTemporalProductScreenState();
}

class _AddTemporalProductScreenState
    extends ConsumerState<AddTemporalProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();

  // Combos / Text
  String _selectedBrand = 'SIN MARCA';
  final _quantityController = TextEditingController(text: '1');
  String _selectedMeasure = 'Unidades';

  // Prices
  final _costController = TextEditingController();
  final _marginController = TextEditingController();
  final _salePriceController = TextEditingController();

  // Warranty
  bool _noWarranty = false;
  final _warrantyQtyController = TextEditingController(text: '30');
  String _warrantyPeriod = 'Días';

  // Inventory
  bool _addToInventory = false;

  // Delivery Time
  String? _selectedDeliveryTimeId;
  late final String _pricingMethod;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingItem;
    if (existing != null) {
      _nameController.text = existing.name;
      _modelController.text = existing.model ?? '';
      _selectedBrand = existing.brand ?? 'SIN MARCA';
      _quantityController.text =
          existing.quantity.truncateToDouble() == existing.quantity
          ? existing.quantity.toInt().toString()
          : existing.quantity.toString();
      _selectedMeasure = existing.uom;
      _costController.text = CurrencyFormatter.formatNumber(existing.costPrice);
      _marginController.text = (existing.profitMargin * 100)
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      _salePriceController.text = CurrencyFormatter.formatNumber(
        existing.unitPrice,
      );
      if (existing.warrantyTime == null) {
        _noWarranty = true;
      } else {
        final parts = existing.warrantyTime!.split(' ');
        if (parts.length == 2) {
          _warrantyQtyController.text = parts[0];
          _warrantyPeriod = parts[1];
        }
      }
      _selectedDeliveryTimeId = existing.deliveryTimeId;
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
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _quantityController.dispose();
    _costController.dispose();
    _marginController.dispose();
    _salePriceController.dispose();
    _warrantyQtyController.dispose();
    super.dispose();
  }

  bool _isCalculating = false;

  void _calculateSalePriceFromMargin() {
    if (_isCalculating) return;
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
  }

  void _calculateMarginFromSalePrice() {
    if (_isCalculating) return;
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
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final quoteState = ref.read(createQuoteProvider);
    final cost = CurrencyFormatter.parse(_costController.text) ?? 0;
    final qty =
        double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 1;
    final marginPercent =
        double.tryParse(_marginController.text.replaceAll(',', '.')) ?? 0;
    final margin = marginPercent / 100;

    final taxRate = quoteState.globalTaxRate / 100;
    double unitPrice;
    if (_pricingMethod == 'margin') {
      final factor = 1 - margin;
      unitPrice = factor > 0 ? cost / factor : cost;
    } else {
      unitPrice = cost * (1 + margin);
    }
    final taxAmount = unitPrice * taxRate;
    final totalPrice = (unitPrice + taxAmount) * qty;

    final warrantyTime = _noWarranty
        ? null
        : '${_warrantyQtyController.text} $_warrantyPeriod';

    final product = QuoteItemProduct(
      id: widget.existingItem?.id ?? const Uuid().v4(),
      quoteId: 'draft',
      name: _nameController.text.trim(),
      brand: _selectedBrand.trim().isNotEmpty && _selectedBrand != 'SIN MARCA'
          ? _selectedBrand.trim()
          : null,
      model: _modelController.text.trim().isNotEmpty
          ? _modelController.text.trim()
          : null,
      uom:
          ref
              .read(uomsProvider)
              .value
              ?.where((u) => u.name == _selectedMeasure)
              .firstOrNull
              ?.symbol ??
          _selectedMeasure,
      quantity: qty,
      costPrice: cost,
      profitMargin: margin,
      unitPrice: unitPrice,
      taxRate: taxRate,
      taxAmount: taxAmount,
      totalPrice: totalPrice,
      warrantyTime: warrantyTime,
      deliveryTimeId: _selectedDeliveryTimeId,
      isTemporal: true,
    );

    if (widget.existingItem != null) {
      ref.read(createQuoteProvider.notifier).updateProduct(product);
    } else {
      ref.read(createQuoteProvider.notifier).addProduct(product);
    }

    if (_addToInventory) {
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          final selectedUom = ref
              .read(uomsProvider)
              .value
              ?.where((u) => u.name == _selectedMeasure)
              .firstOrNull;
          final draftProduct = Product(
            id: const Uuid().v4(),
            userId: userId,
            name: _nameController.text.trim(),
            model: _modelController.text.trim(),
            uomId: selectedUom?.id,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await ref.read(productsProvider.notifier).createProduct(draftProduct);
        }
      } catch (e) {
        debugPrint('Failed to add to inventory: $e');
      }
    }

    if (mounted) {
      context.pop(true);
    }
  }

  Future<void> _showAddBrandDialog() async {
    final newBrand = await AddEditBrandSheet.show(context);
    if (newBrand != null && mounted) {
      setState(() {
        _selectedBrand = newBrand.name;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brandsAsync = ref.watch(brandsProvider);
    final brands = brandsAsync.valueOrNull ?? [];
    final brandNames = brands.map((b) => b.name).toList();

    // Buscar si ya existe una marca que signifique "Sin Marca" en la DB (ignora mayúsculas)
    final existingSinMarca = brandNames.firstWhere(
      (n) => n.trim().toUpperCase() == 'SIN MARCA',
      orElse: () => '',
    );

    if (existingSinMarca.isEmpty) {
      if (!brandNames.contains('SIN MARCA')) {
        brandNames.insert(0, 'SIN MARCA');
      }
    } else {
      // Si existe (ej "Sin Marca") y tenemos seleccionado el genérico "SIN MARCA", sincronizamos
      if (_selectedBrand == 'SIN MARCA') {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedBrand != existingSinMarca) {
            setState(() => _selectedBrand = existingSinMarca);
          }
        });
      }
    }
    final brandItems = brandNames;
    final uomsAsync = ref.watch(uomsProvider);
    final uoms = uomsAsync.value ?? [];
    final uomNames = uoms.map((u) => u.name).toList();
    // Set a valid default once the list first loads — prefer 'Unidad'
    if (uomNames.isNotEmpty && !uomNames.contains(_selectedMeasure)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final preferred = uomNames.firstWhere(
            (n) => n.toLowerCase().contains('unidad'),
            orElse: () => uomNames.first,
          );
          setState(() => _selectedMeasure = preferred);
        }
      });
    }
    final selectedUomSymbol =
        uoms.where((u) => u.name == _selectedMeasure).firstOrNull?.symbol ??
        _selectedMeasure;

    return Scaffold(
      appBar: StandardAppBar(
        title: widget.existingItem != null
            ? 'Modificar producto temporal'
            : 'Agregar producto temporal',
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CustomTextField(
              controller: _nameController,
              label: 'Nombre del producto*',
              hintText: 'Ej: Cámara Web 4K',
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _modelController,
              label: 'Modelo/Nro. parte',
            ),
            const SizedBox(height: 24),
            CustomDropdown<String>(
              value: brandItems.contains(_selectedBrand)
                  ? _selectedBrand
                  : null,
              items: brandItems,
              label: 'Marca',
              itemLabelBuilder: (String value) => value.toTitleCase,
              showAddOption: true,
              addOptionValue: '___ADD___',
              addOptionLabel: 'Agregar',
              onAddPressed: _showAddBrandDialog,
              onChanged: (newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedBrand = newValue;
                  });
                }
              },
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
                    onChanged: (_) => setState(() {}),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Requerido';
                      }
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
                const SizedBox(width: 24),
                Expanded(
                  child: CustomDropdown<String>(
                    value: uomNames.contains(_selectedMeasure)
                        ? _selectedMeasure
                        : null,
                    items: uomNames,
                    label: 'Medida',
                    itemLabelBuilder: (String value) {
                      final match = uoms
                          .where((u) => u.name == value)
                          .firstOrNull;
                      return match != null
                          ? '${match.name.toTitleCase} (${match.symbol})'
                          : value;
                    },
                    onChanged: (newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedMeasure = newValue;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _costController,
              label: 'Precio costo unitario*',
              prefixText: '\$ ',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [CurrencyInputFormatter()],
              helperText: 'Sin impuesto',
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Requerido';
                }
                if (CurrencyFormatter.parse(v) == null) {
                  return 'Inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text(
              'Precio de venta unitario',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // const Spacer(),
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
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

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
            const SizedBox(height: 8),
            Text(
              'Tiempo de entrega',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            ref
                .watch(deliveryTimesForDeliveryProvider)
                .when(
                  data: (deliveryTimes) {
                    if (_selectedDeliveryTimeId == null &&
                        deliveryTimes.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) {
                          setState(() {
                            _selectedDeliveryTimeId = deliveryTimes.first.id;
                          });
                        }
                      });
                    }

                    return CustomDropdown<String>(
                      value: _selectedDeliveryTimeId,
                      items: deliveryTimes.map((e) => e.id).toList(),
                      label: 'Seleccionar tiempo',
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
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Incluir en el inventario propio',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('(deberás completar otros datos luego).'),
              value: _addToInventory,
              onChanged: (v) => setState(() => _addToInventory = v),
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
                onSave: _saveProduct,
                saveLabel:
                    'Confirmar (${_quantityController.text} $selectedUomSymbol)',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
