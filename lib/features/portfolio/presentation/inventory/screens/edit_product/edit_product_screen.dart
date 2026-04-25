import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/shared/widgets/custom_dialog.dart';

import '../../../../../../../shared/widgets/barcode_scanner_screen.dart';
import '../../../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../../../shared/widgets/form_bottom_bar.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/brand_model.dart';
import '../../../../data/models/uom_model.dart';
import '../../../../domain/utils/product_validators.dart';
import '../../../providers/products_provider.dart';
import '../../../providers/lookup_providers.dart';
import '../../../../../settings/presentation/widgets/add_edit_brand_sheet.dart';
import '../../../../../settings/presentation/widgets/add_edit_uom_sheet.dart';
import '../../../../../settings/presentation/widgets/add_edit_category_sheet.dart';

class EditProductScreen extends ConsumerStatefulWidget {
  final Product product;

  const EditProductScreen({super.key, required this.product});

  @override
  ConsumerState<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends ConsumerState<EditProductScreen> {
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _modelController;
  late TextEditingController _specsController;

  // Selected Values
  Brand? _selectedBrand;
  Category? _selectedCategory;
  Uom? _selectedUom;
  File? _newImageFile;

  // Initial Values for Dirty Check
  late String _initialName;
  late String _initialModel;
  late String _initialSpecs;
  late Brand? _initialBrand;
  late Category? _initialCategory;
  late Uom? _initialUom;

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    _nameController = TextEditingController(text: widget.product.name);
    _modelController = TextEditingController(text: widget.product.model);
    _specsController = TextEditingController(text: widget.product.specs);

    _selectedBrand = widget.product.brand;
    _selectedCategory = widget.product.category;
    _selectedUom = widget.product.uomModel;

    // Capture initial state
    _initialName = widget.product.name;
    _initialModel = widget.product.model ?? '';
    _initialSpecs = widget.product.specs ?? '';
    _initialBrand = widget.product.brand;
    _initialCategory = widget.product.category;
    _initialUom = widget.product.uomModel;

    // Listeners for dirty check
    _nameController.addListener(_onFormChanged);
    _modelController.addListener(_onFormChanged);
    _specsController.addListener(_onFormChanged);
  }

  bool get _isDirty {
    return _nameController.text != _initialName ||
        _modelController.text != _initialModel ||
        _specsController.text != _initialSpecs ||
        _selectedBrand != _initialBrand ||
        _selectedCategory != _initialCategory ||
        _selectedUom != _initialUom ||
        _newImageFile != null;
  }

  void _onFormChanged() {
    setState(() {});
  }

  Future<void> _pickImage() async {
    final theme = Theme.of(context);
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final cropper = ImageCropper();
      final croppedFile = await cropper.cropImage(
        sourcePath: pickedFile.path,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Editar Imagen',
            toolbarColor: theme.colorScheme.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Editar Imagen',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        setState(() {
          _newImageFile = File(croppedFile.path);
        });
      }
    }
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
        _selectedUom = newUom;
      });
      ref.invalidate(uomsProvider);
    }
  }

  Future<void> _validateAndSave() async {
    final products = ref.read(productsProvider).value ?? [];
    final currentModel = _modelController.text.trim();

    // 1. Check for Exact Match (excluding current product)
    final exactMatch = ProductValidators.findExactMatch(products, currentModel);

    if (exactMatch != null && exactMatch.id != widget.product.id) {
      // ... Validation Logic (Update to use brand.name if needed) ...
      // Keeping validation logic mostly same but assuming validators handle Brand object or need update.
      // Actually ProductValidators helper might accept list of products.

      if (!mounted) return;
      CustomDialog.show(
        context: context,
        dialog: CustomDialog.confirmation(
          title: 'Producto Duplicado',
          icon: Symbols.error,
          contentText:
              'Ya existe otro equipo con el modelo "$currentModel" en el inventario.\n\n'
              'Marca existente: ${exactMatch.brand?.name ?? "Desconocida"}',
          actions: [
            FilledButton(
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop();
                FocusScope.of(context).requestFocus(FocusNode());
              },
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Check for Similar Match (excluding current product)
    final similarMatch = ProductValidators.findSimilarMatch(
      products,
      currentModel,
    );

    if (similarMatch != null && similarMatch.id != widget.product.id) {
      if (!mounted) return;
      final shouldProceed = await CustomDialog.show<bool>(
        context: context,
        dialog: CustomDialog.confirmation(
          title: 'Modelo Similar Detectado',
          icon: Symbols.info,
          contentText:
              'Ya existe un modelo similar en el inventario:\n\n'
              'Modelo: ${similarMatch.model}\n'
              'Marca: ${similarMatch.brand?.name ?? "Desconocida"}\n\n'
              '¿Estás seguro de continuar?',
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(false),
              child: const Text('Corregir'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(context, rootNavigator: true).pop(true),
              child: const Text('Continuar'),
            ),
          ],
        ),
      );

      if (shouldProceed != true) return;
    }

    // Proceed to save
    _saveChanges();
  }

  // ...

  Future<void> _saveChanges() async {
    if (!_isDirty) return;

    final updatedProduct = widget.product.copyWith(
      name: _nameController.text,
      model: _modelController.text.trim().isEmpty
          ? 'NO APLICA'
          : _modelController.text.trim(),
      specs: _specsController.text,
      brandId: _selectedBrand?.id,
      brand: _selectedBrand,
      categoryId: _selectedCategory?.id,
      category: _selectedCategory,
      uomId: _selectedUom?.id,
      uom: _selectedUom?.symbol,
      uomModel: _selectedUom,
      updatedAt: DateTime.now(),
    );

    try {
      Uint8List? imageBytes;
      String? imageExtension;

      if (_newImageFile != null) {
        imageBytes = await _newImageFile!.readAsBytes();
        imageExtension = _newImageFile!.path.split('.').last;
      }

      await ref
          .read(productsProvider.notifier)
          .updateProduct(
            updatedProduct,
            imageBytes: imageBytes,
            imageExtension: imageExtension,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto actualizado exitosamente')),
        );
        context.pop(); // Go back to details
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al actualizar: $e')));
      }
    }
  }

  Future<bool?> _showDiscardDialog() async {
    final colors = Theme.of(context).colorScheme;
    return CustomDialog.show<bool>(
      context: context,
      dialog: CustomDialog.destructive(
        title: '¿Descartar cambios?',
        contentText:
            'Si sales ahora, perderás toda la información que has ingresado.',
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            onPressed: () =>
                Navigator.of(context, rootNavigator: true).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
  }

  Future<void> _onCancelWithConfirmation() async {
    if (!_isDirty) {
      context.pop();
      return;
    }

    final confirmed = await _showDiscardDialog();
    if (confirmed == true && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final categoriesAsync = ref.watch(categoriesProvider);
    final categoriesList = categoriesAsync.valueOrNull ?? [];

    final brandsAsync = ref.watch(brandsProvider);
    final brandsList = brandsAsync.valueOrNull ?? [];

    final uomsAsync = ref.watch(uomsProvider);
    final uomsList = uomsAsync.valueOrNull ?? [];

    // Ensure selected category is in the list
    if (_selectedCategory != null &&
        !categoriesList.contains(_selectedCategory)) {
      categoriesList.add(_selectedCategory!);
    }

    // Ensure selected brand is in the list (if it has an ID)
    // Brands might be compared by value if Equatable is set up correctly
    if (_selectedBrand != null &&
        !brandsList.any((b) => b.id == _selectedBrand!.id)) {
      // If it's a custom brand not in the list yet?
      // For now, assume fetched list covers it or we add it to list
      brandsList.add(_selectedBrand!);
    }

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final confirmed = await _showDiscardDialog();
        if (confirmed == true && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Modificar producto'),
          centerTitle: false,
          backgroundColor: colors.surface,
          foregroundColor: colors.onSurface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onCancelWithConfirmation,
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ... Image Picker ...
              // Reuse existing code, just skipping for brevity in replacement if allowed,
              // but ReplaceContent needs exact match or replaced block.
              // I will replace lower part of build method.
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.surfaceContainerHighest,
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _newImageFile != null
                          ? Image.file(_newImageFile!, fit: BoxFit.cover)
                          : (widget.product.imageUrl != null &&
                                widget.product.imageUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: widget.product.imageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                              errorWidget: (context, url, error) => const Icon(
                                Icons.image_not_supported_outlined,
                              ),
                            )
                          : Icon(
                              Icons.inventory_2_outlined,
                              size: 50,
                              color: colors.onSurfaceVariant,
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          backgroundColor: colors.surfaceContainerHighest,
                          radius: 18,
                          child: Icon(
                            Icons.edit,
                            size: 18,
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form Fields
              CustomDropdown<Category>(
                label: 'Categoría',
                value: _selectedCategory,
                items: categoriesList,
                searchable: true,
                onChanged: (val) {
                  setState(() => _selectedCategory = val);
                },
                itemLabelBuilder: (item) => item.name,
                showAddOption: true,
                addOptionLabel: 'Agregar categoría',
                addOptionValue: const Category(
                  id: 'ADD_NEW',
                  name: 'Agregar',
                  type: 'other',
                ),
                onAddPressed: () async {
                  final newCategory = await AddEditCategorySheet.show(context);
                  if (newCategory != null && mounted) {
                    setState(() {
                      _selectedCategory = newCategory;
                    });
                    ref.invalidate(categoriesProvider);
                  }
                },
              ),
              const SizedBox(height: 24),

              CustomTextField(
                label: 'Modelo/Nro. parte',
                controller: _modelController,
                suffixIcon: IconButton(
                  icon: const Icon(Symbols.barcode_scanner),
                  tooltip: 'Escanear código',
                  onPressed: () async {
                    final scannedCode = await Navigator.of(context)
                        .push<String>(
                          MaterialPageRoute(
                            builder: (context) => const BarcodeScannerScreen(),
                          ),
                        );
                    if (scannedCode != null) {
                      _modelController.text =
                          scannedCode; // Will trigger listener
                    }
                  },
                ),
              ),
              const SizedBox(height: 24),

              CustomDropdown<Brand>(
                label: 'Marca',
                value: _selectedBrand,
                items: brandsList,
                searchable: true,
                onChanged: (val) {
                  setState(() => _selectedBrand = val);
                },
                itemLabelBuilder: (item) => item.name,
                showAddOption: true,
                addOptionValue: const Brand(id: 'new', name: '___ADD___'),
                onAddPressed: () async {
                  final newBrand = await AddEditBrandSheet.show(context);
                  if (newBrand != null && mounted) {
                    setState(() => _selectedBrand = newBrand);
                  }
                },
                addOptionLabel: 'Agregar marca',
              ),
              const SizedBox(height: 24),

              CustomTextField(
                label: 'Nombre del producto*',
                controller: _nameController,
              ),
              const SizedBox(height: 24),

              CustomTextField(
                label: 'Características',
                controller: _specsController,
                maxLines: 6,
                minLines: 4,
                hintText: '- Resolución de 4K...\n- Interfaz Ethernet...',
              ),
              const SizedBox(height: 24),

              CustomDropdown<Uom>(
                label: 'Unidad de medida',
                value: _selectedUom,
                items: uomsList,
                searchable: true,
                onChanged: (val) {
                  if (val != null && val.id != '___ADD___') {
                    setState(() => _selectedUom = val);
                  }
                },
                itemLabelBuilder: (item) => '${item.name} (${item.symbol})',
                showAddOption: true,
                addOptionLabel: 'Agregar unidad de medida',
                addOptionValue: const Uom(
                  id: '___ADD___',
                  name: '___ADD___',
                  symbol: '',
                ),
                onAddPressed: _showAddUomDialog,
              ),

              const SizedBox(height: 48),

              // Action Buttons
              FormBottomBar(
                onCancel: _onCancelWithConfirmation,
                onSave: _validateAndSave,
                isSaveEnabled: _isDirty,
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
