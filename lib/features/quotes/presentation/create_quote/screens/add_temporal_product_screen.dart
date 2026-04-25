import 'package:d_una_app/core/utils/string_extensions.dart';
import 'package:d_una_app/features/portfolio/domain/utils/product_validators.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/product_search_provider.dart';
import 'package:d_una_app/shared/widgets/friendly_error_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../shared/widgets/custom_dialog.dart';
import '../../../../../shared/widgets/form_bottom_bar.dart';
import '../../../../../shared/widgets/custom_stepper.dart';
import '../../../../../features/portfolio/presentation/providers/lookup_providers.dart';
import '../../../../../features/portfolio/data/models/delivery_time_model.dart';
import '../../../data/models/quote_item_product.dart';
import '../providers/create_quote_provider.dart';
import '../providers/quote_product_selection_provider.dart';
import '../../../../../features/portfolio/data/models/product_model.dart';
import '../../../../../features/portfolio/presentation/providers/products_provider.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../features/portfolio/data/models/uom_model.dart';
import '../../../../../features/settings/presentation/widgets/add_edit_brand_sheet.dart';
import '../../../../../features/settings/presentation/widgets/add_edit_uom_sheet.dart';

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
  final _externalProviderController = TextEditingController();
  final _externalProviderFocusNode = FocusNode();
  String? _externalProviderName;

  // Combos / Text
  String _selectedBrand = 'SIN MARCA';
  String? _selectedBrandId;
  final _quantityController = TextEditingController(text: '1');
  String _selectedMeasure = 'ud.';
  String? _selectedUomId;

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

  // Delivery Time
  String? _selectedDeliveryTimeId;
  late final String _pricingMethod;

  // Seguimiento de valores originales para habilitar el botón "Confirmar"
  String _originalName = '';
  String _originalModel = '';
  String _originalBrand = 'SIN MARCA';
  String _originalQty = '1';
  String _originalMeasure = 'ud.';
  String _originalCost = '';
  String _originalMargin = '';
  String _originalExternalProvider = '';
  String _originalWarrantyQty = '30';
  String _originalWarrantyPeriod = 'Días';
  bool _originalNoWarranty = false;
  String? _originalDeliveryTimeId;
  String _originalSalePrice = '';

  bool _hasChanges() {
    return _nameController.text.trim() != _originalName ||
        _modelController.text.trim() != _originalModel ||
        _selectedBrand != _originalBrand ||
        _quantityController.text.trim() != _originalQty ||
        _selectedMeasure != _originalMeasure ||
        _costController.text.trim() != _originalCost ||
        _marginController.text.trim() != _originalMargin ||
        _salePriceController.text.trim() != _originalSalePrice ||
        (_externalProviderName ?? '') != _originalExternalProvider ||
        _warrantyQtyController.text.trim() != _originalWarrantyQty ||
        _warrantyPeriod != _originalWarrantyPeriod ||
        _noWarranty != _originalNoWarranty ||
        _selectedDeliveryTimeId != _originalDeliveryTimeId;
  }

  @override
  void initState() {
    super.initState();
    _pricingMethod = ref.read(createQuoteProvider).pricingMethod;
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
      _externalProviderName = existing.externalProviderName;
      _externalProviderController.text = existing.externalProviderName ?? '';

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final brands = ref.read(brandsProvider).value ?? [];
          final uoms = ref.read(uomsProvider).value ?? [];

          setState(() {
            _selectedBrandId = brands
                .where((b) => b.name == _selectedBrand)
                .firstOrNull
                ?.id;
            _selectedUomId = uoms
                .where((u) => u.symbol == _selectedMeasure)
                .firstOrNull
                ?.id;
          });
        }
      });
    } else {
      // Para ítems nuevos, inicializar con los IDs por defecto si es posible
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final brands = ref.read(brandsProvider).value ?? [];
          final uoms = ref.read(uomsProvider).value ?? [];

          setState(() {
            _selectedBrandId = brands
                .where((b) => b.name == 'SIN MARCA')
                .firstOrNull
                ?.id;
            _selectedUomId = uoms
                .where((u) => u.symbol == 'ud.')
                .firstOrNull
                ?.id;
          });
          final state = ref.read(createQuoteProvider);
          _marginController.text = state.globalMargin
              .toStringAsFixed(2)
              .replaceAll('.', ',');
        }
      });
    }

    _costController.addListener(_calculateSalePriceFromMargin);
    _marginController.addListener(_calculateSalePriceFromMargin);

    // Capturar valores iniciales para detección de cambios DESPUÉS de cargar el ítem existente
    _originalName = _nameController.text.trim();
    _originalModel = _modelController.text.trim();
    _originalBrand = _selectedBrand;
    _originalQty = _quantityController.text.trim();
    _originalMeasure = _selectedMeasure;
    _originalCost = _costController.text.trim();
    _originalMargin = _marginController.text.trim();
    _originalSalePrice = _salePriceController.text.trim();
    _originalExternalProvider = _externalProviderName ?? '';
    _originalWarrantyQty = _warrantyQtyController.text.trim();
    _originalWarrantyPeriod = _warrantyPeriod;
    _originalNoWarranty = _noWarranty;
    _originalDeliveryTimeId = _selectedDeliveryTimeId;

    // Listeners for duplicate detection
    _nameController.addListener(_checkInventoryDuplicate);
    _modelController.addListener(_checkInventoryDuplicate);

    // Listeners para refrescar el estado del botón "Confirmar" ante cualquier cambio
    _quantityController.addListener(() => setState(() {}));
    _warrantyQtyController.addListener(() => setState(() {}));
    _externalProviderController.addListener(() => setState(() {}));
    _salePriceController.addListener(() => setState(() {}));

    // Initial check
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInventoryDuplicate();
    });
  }

  @override
  void dispose() {
    _marginController.removeListener(_calculateSalePriceFromMargin);
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
      });
      ref.invalidate(uomsProvider);
    }
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

    final taxRateFactor = quoteState.globalTaxRate / 100;
    double unitPrice;
    if (_pricingMethod == 'margin') {
      final factor = 1 - margin;
      unitPrice = factor > 0 ? cost / factor : cost;
    } else {
      unitPrice = cost * (1 + margin);
    }
    final taxAmount = unitPrice * taxRateFactor;
    final totalPrice = (unitPrice + taxAmount) * qty;

    final warrantyTime = _noWarranty
        ? null
        : '${_warrantyQtyController.text} $_warrantyPeriod';

    final currentModel = _modelController.text.trim().isEmpty
        ? 'NO APLICA'
        : _modelController.text.trim();
    final currentName = _nameController.text.trim();

    // --- Step 1: Check duplicate in OWN inventory (local, instant) ---
    final products = ref.read(productsProvider).value ?? [];
    final ownDuplicate = ProductValidators.findDuplicate(
      products: products,
      brandId: _selectedBrandId,
      model: currentModel,
      uomId: _selectedUomId,
      name: currentName,
    );

    if (ownDuplicate != null) {
      bool identityChanged = true;
      if (widget.existingItem != null) {
        identityChanged = identityChangedFrom(
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

    // --- Step 2: Check duplicate in SUPPLIER catalog (RPC, async) ---
    final searchTerm = currentModel != 'NO APLICA' ? currentModel : currentName;
    final supplierDuplicate = await _checkSupplierDuplicate(
      searchTerm: searchTerm,
      currentModel: currentModel,
      currentName: currentName,
      currentBrand: _selectedBrand,
      currentUom: _selectedMeasure,
    );
    if (supplierDuplicate != null) {
      bool identityChanged = true;
      if (widget.existingItem != null) {
        identityChanged = identityChangedFrom(
          widget.existingItem!,
          currentName,
          currentModel,
          _selectedBrand,
        );
      }

      if (identityChanged) {
        if (mounted) {
          _showDuplicateDialog(
            productName: supplierDuplicate['name']!,
            productBrand: supplierDuplicate['brand'],
            productModel: supplierDuplicate['model'],
            source: 'el catálogo de proveedores',
            searchTerm: searchTerm,
          );
        }
        return;
      }
    }

    // --- Step 3: If _addToInventory and NOT already there, create in DB ---
    if (_addToInventory && !_alreadyInInventory) {
      try {
        final userId = Supabase.instance.client.auth.currentUser?.id;
        if (userId != null) {
          final productToSave = Product(
            id: const Uuid().v4(),
            userId: userId,
            name: currentName,
            brandId: _selectedBrandId,
            model: currentModel == 'NO APLICA' ? null : currentModel,
            uomId: _selectedUomId,
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
                'Se agregó a la cotización, pero no se pudo guardar en tu inventario por un problema de conexión.',
              ),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    // --- Step 4: Create QuoteItemProduct as PURE temporal ---
    final product = QuoteItemProduct(
      id: widget.existingItem?.id ?? const Uuid().v4(),
      quoteId: 'draft',
      productId: null,
      name: currentName,
      brand: _selectedBrand.trim().isNotEmpty && _selectedBrand != 'SIN MARCA'
          ? _selectedBrand.trim()
          : null,
      model: currentModel,
      uom: _selectedMeasure,
      uomIconName: 'package_2',
      quantity: qty,
      availableStock: qty,
      costPrice: cost,
      profitMargin: margin,
      unitPrice: unitPrice,
      taxRate: quoteState.globalTaxRate,
      taxAmount: taxAmount,
      totalPrice: totalPrice,
      warrantyTime: warrantyTime,
      deliveryTimeId: _selectedDeliveryTimeId,
      externalProviderName: _externalProviderName,
      isTemporal: true,
    );

    if (widget.existingItem != null) {
      ref.read(createQuoteProvider.notifier).updateProduct(product);
    } else {
      ref.read(createQuoteProvider.notifier).addProduct(product);
    }

    if (mounted) {
      context.pop(true);
    }
  }

  /// Checks if the current product identity (Name, Brand, Model, UOM)
  /// matches any product already in the user's inventory.
  void _checkInventoryDuplicate() {
    final products = ref.read(productsProvider).value ?? [];

    final currentModel = _modelController.text.trim().isEmpty
        ? 'NO APLICA'
        : _modelController.text.trim();
    final currentName = _nameController.text.trim();

    // --- Resolución de IDs en caliente si faltan ---
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

        // SOLO bloqueamos y forzamos el switch si estamos en MODO EDICIÓN
        if (widget.existingItem != null) {
          if (_alreadyInInventory) {
            _addToInventory = true;
          } else {
            _addToInventory = false;
          }
        }
      });
    }
  }

  /// Checks if a product with the same model/name exists in the supplier catalog.
  Future<Map<String, String>?> _checkSupplierDuplicate({
    required String searchTerm,
    required String currentModel,
    required String currentName,
    required String currentBrand,
    required String currentUom,
  }) async {
    try {
      final repository = ref.read(quoteProductSelectionRepositoryProvider);
      final results = await repository.getQuoteProducts(
        ProductSearchParams(query: searchTerm),
      );

      // --- BLOQUE DE DEBUG RESTAURADO ---
      debugPrint('=== DEBUG BUSQUEDA PROVEEDORES ===');
      debugPrint('Buscando con término: "$searchTerm"');
      debugPrint('Resultados encontrados: ${results.length}');

      for (var i = 0; i < results.length; i++) {
        final p = results[i];
        debugPrint('Producto [$i]:');
        debugPrint('  - Nombre: "${p.name}"');
        debugPrint(
          '  - Marca:  "${p.brand}" (Huella: ${p.brand.normalizeFingerprint})',
        );
        debugPrint(
          '  - Modelo: "${p.model}" (Huella: ${p.model.normalizeFingerprint})',
        );
        debugPrint(
          '  - UOM:    "${p.uom}" (Huella: ${p.uom.normalizeFingerprint})',
        );
        debugPrint('  - UOM:    "$currentUom"');
      }
      debugPrint('==================================');

      final match = results.where((p) {
        final brandMatch =
            p.brand.normalizeFingerprint == currentBrand.normalizeFingerprint;

        // Usamos normalizeFingerprint en UOM para ser tolerantes a puntos/espacios
        final uomMatch = p.uom == currentUom;

        final modelMatch = currentModel != 'NO APLICA'
            ? p.model.normalizeFingerprint == currentModel.normalizeFingerprint
            : true;

        final nameMatch =
            p.name.normalizeFingerprint == currentName.normalizeFingerprint;

        if (currentModel != 'NO APLICA') {
          return modelMatch && brandMatch && uomMatch;
        } else {
          // Para genéricos, los 3 pilares deben coincidir
          return nameMatch && brandMatch && uomMatch;
        }
      }).firstOrNull;

      if (match != null) {
        return {'name': match.name, 'brand': match.brand, 'model': match.model};
      }
    } catch (e) {
      debugPrint('Error checking supplier duplicates: $e');
    }
    return null;
  }

  /// Shows a dialog informing the user that the product already exists.
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
                '/quotes/create/select-product/search',
                extra: searchTerm,
              );
            },
            child: const Text('Ir al buscador'),
          ),
        ],
      ),
    );
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
    final uomSymbols = uoms.map((u) => u.symbol).toList();
    if (uomSymbols.isNotEmpty && !uomSymbols.contains(_selectedMeasure)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final preferred = uoms
              .firstWhere(
                (u) => u.name.toLowerCase().contains('unidad'),
                orElse: () => uoms.first,
              )
              .symbol; // <--- Ahora guardamos el símbolo
          setState(() => _selectedMeasure = preferred);
        }
      });
    }
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
              'Usa este apartado solo para incluir productos que no existan en tu inventario o en el inventario de proveedores afiliados.',
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
                  final brand = brands.firstWhere((b) => b.name == newValue);
                  setState(() {
                    _selectedBrand = newValue;
                    _selectedBrandId = brand.id;
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
                        ? uoms.firstWhere((u) => u.symbol == _selectedMeasure)
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
            Text(
              'Proveedor Externo',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 56, // Match CustomTextField height roughly
              child: RawAutocomplete<String>(
                textEditingController: _externalProviderController,
                focusNode: _externalProviderFocusNode,
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  final suppliers =
                      ref.read(unaffiliatedSuppliersProvider).value ?? [];
                  final lowercaseQuery = textEditingValue.text.toLowerCase();

                  final matches = suppliers
                      .where((supplier) {
                        final nameMatch = supplier.name.toLowerCase().contains(
                          lowercaseQuery,
                        );
                        final legalNameMatch =
                            supplier.legalName?.toLowerCase().contains(
                              lowercaseQuery,
                            ) ??
                            false;
                        return nameMatch || legalNameMatch;
                      })
                      .map((s) {
                        final namePart = s.name.toLowerCase();
                        final legalPart = s.legalName?.toLowerCase() ?? '';

                        if (legalPart.contains(lowercaseQuery) &&
                            !namePart.contains(lowercaseQuery)) {
                          return s.legalName!;
                        }
                        return s.name;
                      });

                  return matches;
                },
                onSelected: (String selection) {
                  _externalProviderController.text = selection;
                  setState(() {
                    _externalProviderName = selection;
                  });
                },
                fieldViewBuilder:
                    (context, controller, focusNode, onFieldSubmitted) {
                      return CustomTextField(
                        controller: controller,
                        focusNode: focusNode,
                        label: 'Nombre del proveedor (opcional)',
                        onChanged: (value) {
                          setState(() {
                            _externalProviderName = value;
                          });
                        },
                      );
                    },
                optionsViewBuilder: (context, onSelected, options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      borderRadius: BorderRadius.circular(8),
                      color: colors.surfaceContainerHighest,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: 200,
                          minWidth: MediaQuery.of(context).size.width - 32,
                        ),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return InkWell(
                              onTap: () => onSelected(option),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(
                                  option,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
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
                    : 'Luego deberás completar otros datos.',
                style: TextStyle(
                  color: _alreadyInInventory ? colors.primary : colors.outline,
                  fontWeight: _alreadyInInventory ? FontWeight.bold : null,
                  fontSize: 12,
                ),
              ),
              value: _addToInventory,
              // SOLO deshabilitamos visualmente si hay duplicado Y estamos en MODO EDICIÓN
              onChanged: (_alreadyInInventory && widget.existingItem != null)
                  ? null
                  : (v) => setState(() => _addToInventory = v),
              activeThumbColor:
                  (_alreadyInInventory && widget.existingItem != null)
                  ? colors.outline.withValues(
                      alpha: 0.5,
                    ) // Color gris si está bloqueado
                  : colors.onPrimary,
              activeTrackColor:
                  (_alreadyInInventory && widget.existingItem != null)
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

  /// Compares current form values with an existing item's identity.
  bool identityChangedFrom(
    QuoteItemProduct existing,
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
      final brandChanged = existing.brand != currentBrand;
      return nameChanged || brandChanged;
    }
  }
}
