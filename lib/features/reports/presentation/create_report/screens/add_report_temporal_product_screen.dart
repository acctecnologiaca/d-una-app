import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../../../../features/portfolio/domain/utils/product_validators.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../../../../shared/widgets/form_bottom_bar.dart';
import '../../../../../shared/widgets/custom_stepper.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../portfolio/presentation/providers/lookup_providers.dart';
import '../../../../portfolio/data/models/product_model.dart';
import '../../../../portfolio/data/models/uom_model.dart';
import '../../../../portfolio/presentation/providers/products_provider.dart';
import '../../../../settings/presentation/widgets/add_edit_brand_sheet.dart';
import '../../../../settings/presentation/widgets/add_edit_uom_sheet.dart';
import '../providers/create_report_provider.dart';
import '../../../data/models/service_report_item_product.dart';

class AddReportTemporalProductScreen extends ConsumerStatefulWidget {
  final ServiceReportItemProduct? existingItem;

  const AddReportTemporalProductScreen({super.key, this.existingItem});

  @override
  ConsumerState<AddReportTemporalProductScreen> createState() =>
      _AddReportTemporalProductScreenState();
}

class _AddReportTemporalProductScreenState
    extends ConsumerState<AddReportTemporalProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _modelController = TextEditingController();

  // Combos / Text
  String _selectedBrand = 'SIN MARCA';
  String? _selectedBrandId;
  final _quantityController = TextEditingController(text: '1');
  String _selectedMeasure = 'ud.';
  String? _selectedUomId;
  String? _selectedUomIconName;

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
  bool _alreadyInInventory = false;

  // Tracking original values for change detection
  String _originalName = '';
  String _originalModel = '';
  String _originalBrand = 'SIN MARCA';
  String _originalQty = '1';
  String _originalMeasure = 'ud.';
  String _originalCost = '';
  String _originalMargin = '';
  String _originalSalePrice = '';
  String _originalWarrantyQty = '30';
  String _originalWarrantyPeriod = 'Días';
  bool _originalNoWarranty = false;

  bool _hasChanges() {
    return _nameController.text.trim() != _originalName ||
        _modelController.text.trim() != _originalModel ||
        _selectedBrand != _originalBrand ||
        _quantityController.text.trim() != _originalQty ||
        _selectedMeasure != _originalMeasure ||
        _costController.text.trim() != _originalCost ||
        _marginController.text.trim() != _originalMargin ||
        _salePriceController.text.trim() != _originalSalePrice ||
        _warrantyQtyController.text.trim() != _originalWarrantyQty ||
        _warrantyPeriod != _originalWarrantyPeriod ||
        _noWarranty != _originalNoWarranty;
  }

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
      _selectedUomIconName = existing.uomIconName;
      _costController.text = CurrencyFormatter.formatNumber(existing.costPrice);
      _marginController.text = existing.profitMargin
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      _salePriceController.text = CurrencyFormatter.formatNumber(
        existing.unitPrice,
      );
      if (existing.warrantyTime == null) {
        _noWarranty = true;
      } else {
        _warrantyQtyController.text = existing.warrantyTime.toString();
        _warrantyPeriod = switch (existing.warrantyUnit) {
          'days' => 'Días',
          'months' => 'Meses',
          'years' => 'Años',
          _ => 'Días',
        };
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final brands = ref.read(brandsProvider).value ?? [];
          final uoms = ref.read(uomsProvider).value ?? [];

          setState(() {
            _selectedBrandId =
                brands.where((b) => b.name == _selectedBrand).firstOrNull?.id;
            final matchedUom =
                uoms.where((u) => u.symbol == _selectedMeasure).firstOrNull;
            _selectedUomId = matchedUom?.id;
            _selectedUomIconName = matchedUom?.iconName ?? existing.uomIconName;
          });
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final brands = ref.read(brandsProvider).value ?? [];
          final uoms = ref.read(uomsProvider).value ?? [];

          setState(() {
            _selectedBrandId =
                brands.where((b) => b.name == 'SIN MARCA').firstOrNull?.id;
            final matchedUom =
                uoms.where((u) => u.symbol == 'ud.').firstOrNull ??
                (uoms.isNotEmpty ? uoms.first : null);
            _selectedUomId = matchedUom?.id;
            _selectedMeasure = matchedUom?.symbol ?? 'ud.';
            _selectedUomIconName = matchedUom?.iconName;
          });
          final state = ref.read(createReportProvider);
          _marginController.text =
              state.globalMargin.toStringAsFixed(2).replaceAll('.', ',');
        }
      });
    }

    _costController.addListener(_calculateSalePriceFromMargin);
    _marginController.addListener(_calculateSalePriceFromMargin);

    _originalName = _nameController.text.trim();
    _originalModel = _modelController.text.trim();
    _originalBrand = _selectedBrand;
    _originalQty = _quantityController.text.trim();
    _originalMeasure = _selectedMeasure;
    _originalCost = _costController.text.trim();
    _originalMargin = _marginController.text.trim();
    _originalSalePrice = _salePriceController.text.trim();
    _originalWarrantyQty = _warrantyQtyController.text.trim();
    _originalWarrantyPeriod = _warrantyPeriod;
    _originalNoWarranty = _noWarranty;

    _nameController.addListener(_checkInventoryDuplicate);
    _modelController.addListener(_checkInventoryDuplicate);

    _quantityController.addListener(() => setState(() {}));
    _warrantyQtyController.addListener(() => setState(() {}));
    _salePriceController.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInventoryDuplicate();
    });
  }

  @override
  void dispose() {
    _marginController.removeListener(_calculateSalePriceFromMargin);
    _costController.removeListener(_calculateSalePriceFromMargin);
    _nameController.removeListener(_checkInventoryDuplicate);
    _modelController.removeListener(_checkInventoryDuplicate);
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
      final salePrice = cost * (1 + margin);
      _salePriceController.text = CurrencyFormatter.formatNumber(salePrice);
    } else {
      _salePriceController.text = '';
    }

    _isCalculating = false;
    setState(() {});
  }

  void _calculateMarginFromSalePrice() {
    if (_isCalculating) return;
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

  Future<void> _showAddUomDialog() async {
    final newUom = await showModalBottomSheet<Uom>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => const AddEditUomSheet(),
    );

    if (newUom != null && mounted) {
      setState(() {
        _selectedMeasure = newUom.symbol;
        _selectedUomId = newUom.id;
        _selectedUomIconName = newUom.iconName;
      });
      ref.invalidate(uomsProvider);
    }
  }

  Future<void> _showAddBrandDialog() async {
    final newBrand = await AddEditBrandSheet.show(context);
    if (newBrand != null && mounted) {
      setState(() {
        _selectedBrand = newBrand.name;
        _selectedBrandId = newBrand.id;
      });
    }
  }

  void _checkInventoryDuplicate() {
    final products = ref.read(productsProvider).value ?? [];

    final currentModel = _modelController.text.trim().isEmpty
        ? 'NO APLICA'
        : _modelController.text.trim();
    final currentName = _nameController.text.trim();

    String? brandId = _selectedBrandId;
    String? uomId = _selectedUomId;

    if (brandId == null) {
      final brands = ref.read(brandsProvider).value ?? [];
      brandId = brands.where((b) => b.name == _selectedBrand).firstOrNull?.id;
    }
    if (uomId == null) {
      final uoms = ref.read(uomsProvider).value ?? [];
      uomId = uoms.where((u) => u.symbol == _selectedMeasure).firstOrNull?.id;
    }

    final duplicate = ProductValidators.findDuplicate(
      products: products,
      brandId: brandId,
      model: currentModel,
      uomId: uomId,
      name: currentName,
    );

    if (mounted) {
      setState(() {
        _alreadyInInventory = duplicate != null;

        if (widget.existingItem != null) {
          _addToInventory = _alreadyInInventory;
        }
      });
    }
  }

  void _showDuplicateDialog({
    required String productName,
    String? productBrand,
    String? productModel,
    required String source,
    required String searchTerm,
  }) {
    final colors = Theme.of(context).colorScheme;
    CustomDialog.show(
      context: context,
      dialog: CustomDialog.confirmation(
        icon: Icons.info_outline,
        title: 'Producto encontrado',
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Se encontró un producto similar en $source:'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (productBrand != null && productBrand.isNotEmpty)
                    Text(
                      productBrand,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  Text(
                    productName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (productModel != null &&
                      productModel.isNotEmpty &&
                      productModel != 'NO APLICA')
                    Text(
                      productModel.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Agrégalo desde el buscador para mantener el control '
              'de inventario y precios.',
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Corregir datos'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.pop();
              context.push(
                '/reports/create/select-product/search',
              );
            },
            child: const Text('Ir al buscador'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showSimilarModelDialog({
    required Product similarProduct,
  }) async {
    final colors = Theme.of(context).colorScheme;
    final res = await CustomDialog.show<bool>(
      context: context,
      dialog: CustomDialog.confirmation(
        icon: Icons.info_outline,
        title: 'Modelo similar detectado',
        contentWidget: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Se encontró un producto con un modelo muy similar en tu inventario:',
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (similarProduct.brand?.name != null &&
                      similarProduct.brand!.name.isNotEmpty)
                    Text(
                      similarProduct.brand!.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  Text(
                    similarProduct.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  if (similarProduct.model != null &&
                      similarProduct.model!.isNotEmpty)
                    Text(
                      similarProduct.model!.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '¿Deseas continuar guardando este nuevo producto o prefieres corregirlo?',
              style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Corregir datos'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
    return res ?? false;
  }

  bool _identityChangedFrom(
    ServiceReportItemProduct existing,
    String currentName,
    String currentModel,
    String currentBrand,
  ) {
    if (currentModel != 'NO APLICA') {
      final modelChanged =
          existing.model?.normalizeFingerprint !=
          currentModel.normalizeFingerprint;
      final brandChanged = (existing.brand ?? 'SIN MARCA') != currentBrand;
      return modelChanged || brandChanged;
    } else {
      final nameChanged =
          existing.name.normalizeFingerprint !=
          currentName.normalizeFingerprint;
      final brandChanged = (existing.brand ?? 'SIN MARCA') != currentBrand;
      return nameChanged || brandChanged;
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final reportState = ref.read(createReportProvider);
    final cost = CurrencyFormatter.parse(_costController.text) ?? 0;
    final qty =
        double.tryParse(_quantityController.text.replaceAll(',', '.')) ?? 1;
    final marginPercent =
        double.tryParse(_marginController.text.replaceAll(',', '.')) ?? 0;
    final margin = marginPercent / 100;

    final taxRateFactor = reportState.globalTaxRate / 100;
    final unitPrice = cost * (1 + margin);
    final taxAmount = (unitPrice * qty) * taxRateFactor;
    final totalPrice = unitPrice * qty;

    final int? warrantyTime =
        _noWarranty ? null : int.tryParse(_warrantyQtyController.text);
    final String? warrantyUnit = _noWarranty
        ? null
        : switch (_warrantyPeriod) {
            'Días' => 'days',
            'Meses' => 'months',
            'Años' => 'years',
            _ => 'days',
          };

    final currentModel = _modelController.text.trim().isEmpty
        ? 'NO APLICA'
        : _modelController.text.trim();
    final currentName = _nameController.text.trim();

    // Check duplicate in own inventory
    final products = ref.read(productsProvider).value ?? [];
    String? brandId = _selectedBrandId;
    String? uomId = _selectedUomId;

    if (brandId == null) {
      final brands = ref.read(brandsProvider).value ?? [];
      brandId = brands.where((b) => b.name == _selectedBrand).firstOrNull?.id;
    }
    if (uomId == null) {
      final uoms = ref.read(uomsProvider).value ?? [];
      uomId = uoms.where((u) => u.symbol == _selectedMeasure).firstOrNull?.id;
    }

    final ownDuplicate = ProductValidators.findDuplicate(
      products: products,
      brandId: brandId,
      model: currentModel,
      uomId: uomId,
      name: currentName,
    );

    if (ownDuplicate != null) {
      bool identityChanged = true;
      if (widget.existingItem != null) {
        identityChanged = _identityChangedFrom(
          widget.existingItem!,
          currentName,
          currentModel,
          _selectedBrand,
        );
      }

      if (identityChanged) {
        if (mounted) {
          _showDuplicateDialog(
            productName: ownDuplicate.name,
            productBrand: ownDuplicate.brand?.name,
            productModel: ownDuplicate.model,
            source: 'tu inventario propio',
            searchTerm: currentModel != 'NO APLICA'
                ? currentModel
                : currentName,
          );
        }
        return;
      }
    }

    // Check similar match (>= 80% fuzzy match on model)
    if (currentModel != 'NO APLICA') {
      final similarProduct = ProductValidators.findSimilarMatch(
        products,
        currentModel,
      );

      if (similarProduct != null &&
          similarProduct.id != widget.existingItem?.productId) {
        if (mounted) {
          final shouldContinue = await _showSimilarModelDialog(
            similarProduct: similarProduct,
          );
          if (!shouldContinue) {
            return;
          }
        }
      }
    }

    // Save to inventory if requested and not present
    if (_addToInventory && !_alreadyInInventory) {
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          final productToSave = Product(
            id: const Uuid().v4(),
            userId: userId,
            name: currentName,
            brandId: brandId,
            model: currentModel == 'NO APLICA' ? null : currentModel,
            uomId: uomId,
            averageCost: cost,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          await ref
              .read(productsProvider.notifier)
              .createProduct(productToSave);
        }
      } catch (e) {
        debugPrint('Failed to add to inventory: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Se agregó al reporte, pero no se pudo guardar en tu inventario por un problema de conexión.',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    final product = ServiceReportItemProduct(
      id: widget.existingItem?.id ?? const Uuid().v4(),
      reportId: reportState.report?.id ?? '',
      productId: null,
      name: currentName,
      brand: _selectedBrand.trim().isNotEmpty && _selectedBrand != 'SIN MARCA'
          ? _selectedBrand.trim()
          : null,
      model: currentModel == 'NO APLICA' ? null : currentModel,
      uom: _selectedMeasure,
      uomIconName: _selectedUomIconName ?? 'package_2',
      quantity: qty,
      costPrice: cost,
      profitMargin: marginPercent,
      unitPrice: unitPrice,
      taxRate: reportState.globalTaxRate,
      taxAmount: taxAmount,
      totalPrice: totalPrice,
      warrantyTime: warrantyTime,
      warrantyUnit: warrantyUnit,
      sourceType: ReportProductSourceType.temporal,
      groupIndex:
          widget.existingItem?.groupIndex ?? reportState.nextGroupIndex,
    );

    if (mounted) {
      context.pop(product);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final brandsAsync = ref.watch(brandsProvider);
    final brands = brandsAsync.valueOrNull ?? [];
    final brandNames = brands.map((b) => b.name).toList();

    final existingSinMarca = brandNames.firstWhere(
      (n) => n.trim().toUpperCase() == 'SIN MARCA',
      orElse: () => '',
    );

    if (existingSinMarca.isEmpty) {
      if (!brandNames.contains('SIN MARCA')) {
        brandNames.insert(0, 'SIN MARCA');
      }
    } else {
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
    final uomSymbols = uoms.map((u) => u.symbol).toList();
    if (uomSymbols.isNotEmpty && !uomSymbols.contains(_selectedMeasure)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final preferred = uoms
              .firstWhere(
                (u) => u.name.toLowerCase().contains('unidad'),
                orElse: () => uoms.first,
              )
              .symbol;
          setState(() => _selectedMeasure = preferred);
        }
      });
    }

    final cost = CurrencyFormatter.parse(_costController.text) ?? 0;
    final salePrice =
        CurrencyFormatter.parse(_salePriceController.text) ?? 0;
    final profitAmount = (salePrice > cost) ? (salePrice - cost) : 0.0;

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
            Text(
              'Usa este apartado solo para incluir productos o repuestos que no existan en tu inventario.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _nameController,
              label: 'Nombre del producto*',
              hintText: 'Ej: Cámara Web 4K',
              onChanged: (_) => _checkInventoryDuplicate(),
              validator: (v) => v == null || v.isEmpty ? 'Requerido' : null,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: _modelController,
              label: 'Modelo/Nro. parte',
              onChanged: (_) => _checkInventoryDuplicate(),
            ),
            const SizedBox(height: 24),
            CustomDropdown<String>(
              value: brandItems.contains(_selectedBrand)
                  ? _selectedBrand
                  : null,
              items: brandItems,
              label: 'Marca',
              itemLabelBuilder: (String value) => value.toTitleCase,
              searchable: true,
              showAddOption: true,
              addOptionValue: '___ADD___',
              addOptionLabel: 'Agregar marca',
              onAddPressed: _showAddBrandDialog,
              onChanged: (newValue) {
                if (newValue != null) {
                  final brand =
                      brands.where((b) => b.name == newValue).firstOrNull;
                  setState(() {
                    _selectedBrand = newValue;
                    _selectedBrandId = brand?.id;
                  });
                  _checkInventoryDuplicate();
                }
              },
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
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: CustomDropdown<Uom>(
                    value: uoms.any((u) => u.symbol == _selectedMeasure)
                        ? uoms.firstWhere(
                            (u) => u.symbol == _selectedMeasure,
                          )
                        : (uoms.isNotEmpty ? uoms.last : null),
                    items: uoms,
                    label: 'Medida',
                    searchable: true,
                    itemLabelBuilder: (u) =>
                        '${u.name.toTitleCase} (${u.symbol})',
                    onChanged: (newValue) {
                      if (newValue != null && newValue.id != '___ADD___') {
                        setState(() {
                          _selectedMeasure = newValue.symbol;
                          _selectedUomId = newValue.id;
                          _selectedUomIconName = newValue.iconName;
                        });
                        _checkInventoryDuplicate();
                      }
                    },
                    showAddOption: true,
                    addOptionLabel: 'Agregar unidad',
                    addOptionValue: const Uom(
                      id: '___ADD___',
                      name: '___ADD___',
                      symbol: '',
                    ),
                    onAddPressed: _showAddUomDialog,
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
                const SizedBox(width: 8),
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

            // Big Price Display
            Center(
              child: Column(
                children: [
                  Text(
                    'Precio de venta',
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    CurrencyFormatter.format(salePrice),
                    style: textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface.withAlpha(128),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colors.outlineVariant),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ganancia: ',
                          style: textTheme.labelLarge?.copyWith(
                            color: colors.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${CurrencyFormatter.format(profitAmount)}/$_selectedMeasure',
                          style: textTheme.bodyLarge?.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
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
              subtitle: Text(
                (_alreadyInInventory && widget.existingItem != null)
                    ? 'Este producto ya fue incluído en tu inventario.'
                    : 'Luego podrás gestionar su stock y compras.',
                style: TextStyle(
                  color: _alreadyInInventory ? colors.primary : colors.outline,
                  fontWeight: _alreadyInInventory ? FontWeight.bold : null,
                  fontSize: 12,
                ),
              ),
              value: _addToInventory,
              onChanged: (_alreadyInInventory && widget.existingItem != null)
                  ? null
                  : (v) => setState(() => _addToInventory = v),
              activeThumbColor:
                  (_alreadyInInventory && widget.existingItem != null)
                      ? colors.outline.withValues(alpha: 0.5)
                      : colors.onPrimary,
              activeTrackColor:
                  (_alreadyInInventory && widget.existingItem != null)
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
                onCancel: () => context.pop(),
                onSave:
                    (_hasChanges() && _nameController.text.trim().isNotEmpty)
                        ? _saveProduct
                        : null,
                saveLabel:
                    'Confirmar (${_quantityController.text} $_selectedMeasure)',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
