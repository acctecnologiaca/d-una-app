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
import '../../../data/models/quote_item_product.dart';
import '../providers/create_quote_provider.dart';
import '../../../../../features/portfolio/data/models/product_model.dart';
import '../../../../../features/portfolio/presentation/providers/products_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddTemporalProductScreen extends ConsumerStatefulWidget {
  const AddTemporalProductScreen({super.key});

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
  String _selectedBrand = 'Genérico';
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final state = ref.read(createQuoteProvider);
      _marginController.text = state.globalMargin
          .toStringAsFixed(2)
          .replaceAll('.', ',');
    });

    _costController.addListener(_calculateSalePriceFromMargin);
    _marginController.addListener(_calculateSalePriceFromMargin);
    _salePriceController.addListener(_calculateMarginFromSalePrice);
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

    final cost =
        double.tryParse(_costController.text.replaceAll(',', '.')) ?? 0;
    final marginPercent =
        double.tryParse(_marginController.text.replaceAll(',', '.')) ?? 0;

    if (cost > 0) {
      final margin = marginPercent / 100;
      final salePrice = cost * (1 + margin);
      _salePriceController.text = salePrice
          .toStringAsFixed(2)
          .replaceAll('.', ',');
    } else {
      _salePriceController.text = '';
    }

    _isCalculating = false;
  }

  void _calculateMarginFromSalePrice() {
    if (_isCalculating) return;
    _isCalculating = true;

    final cost =
        double.tryParse(_costController.text.replaceAll(',', '.')) ?? 0;
    final salePrice =
        double.tryParse(_salePriceController.text.replaceAll(',', '.')) ?? 0;

    if (cost > 0 && salePrice > cost) {
      final margin = ((salePrice / cost) - 1) * 100;
      _marginController.text = margin.toStringAsFixed(2).replaceAll('.', ',');
    } else {
      _marginController.text = '';
    }

    _isCalculating = false;
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final quoteState = ref.read(createQuoteProvider);
    final cost =
        double.tryParse(_costController.text.replaceAll(',', '.')) ?? 0;
    final qty =
        double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 1;
    final marginPercent =
        double.tryParse(_marginController.text.replaceAll(',', '.')) ?? 0;
    final margin = marginPercent / 100;

    final taxRate = quoteState.globalTaxRate;
    final unitPrice = cost * (1 + margin);
    final taxAmount = unitPrice * taxRate;
    final totalPrice = (unitPrice + taxAmount) * qty;

    final warrantyTime = _noWarranty
        ? null
        : '${_warrantyQtyController.text} $_warrantyPeriod';

    final product = QuoteItemProduct(
      id: const Uuid().v4(),
      quoteId: 'draft',
      name: _nameController.text.trim(),
      brand: _selectedBrand.trim().isNotEmpty && _selectedBrand != 'Genérico'
          ? _selectedBrand.trim()
          : null,
      model: _modelController.text.trim().isNotEmpty
          ? _modelController.text.trim()
          : null,
      uom: _selectedMeasure,
      quantity: qty,
      costPrice: cost,
      profitMargin: margin,
      unitPrice: unitPrice,
      taxRate: taxRate,
      taxAmount: taxAmount,
      totalPrice: totalPrice,
      warrantyTime: warrantyTime,
    );

    ref.read(createQuoteProvider.notifier).addProduct(product);

    if (_addToInventory) {
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          final draftProduct = Product(
            id: const Uuid().v4(),
            userId: userId,
            name: _nameController.text.trim(),
            model: _modelController.text.trim(),
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brandsAsync = ref.watch(brandsProvider);
    final brands = brandsAsync.value ?? [];
    final brandItems = ['Genérico', ...brands.map((b) => b.name)];

    return Scaffold(
      appBar: const StandardAppBar(title: 'Agregar producto temporal'),
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
              value: _selectedBrand,
              items: brandItems,
              label: 'Marca',
              itemLabelBuilder: (String value) => value,
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
                    value: _selectedMeasure,
                    items: const ['Unidades', 'Cajas', 'Kg', 'Metros'],
                    label: 'Medida',
                    itemLabelBuilder: (String value) => value,
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
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
              ],
              helperText: 'Sin impuesto',
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'Requerido';
                }
                if (double.tryParse(v.replaceAll(',', '.')) == null) {
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
                const Spacer(),
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
                const SizedBox(width: 16),
                SizedBox(
                  width: 160,
                  child: CustomTextField(
                    controller: _salePriceController,
                    label: 'Monto*',
                    prefixText: '\$ ',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[.,]?\d*'),
                      ),
                    ],
                    helperText: 'Sin impuesto',
                  ),
                ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Garantía',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Este producto no tiene garantía',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              value: _noWarranty,
              onChanged: (v) => setState(() => _noWarranty = v),
              activeThumbColor: colors.primary,
            ),
            if (!_noWarranty) ...[
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
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Incluir en el inventario propio',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('(deberás completar otros datos luego).'),
              value: _addToInventory,
              onChanged: (v) => setState(() => _addToInventory = v),
              activeThumbColor: colors.primary,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16.0, 0, 16.0, 40.0),
          child: FormBottomBar(
            onCancel: () => context.pop(),
            onSave: _saveProduct,
            saveLabel: 'Confirmar (${_quantityController.text})',
          ),
        ),
      ),
    );
  }
}
