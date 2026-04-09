import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../../../shared/widgets/wizard_progress_bar.dart';
import 'steps/add_product_step1.dart';
import 'steps/add_product_step2.dart';
import 'steps/add_product_step3.dart';
import 'steps/add_product_step4.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../data/models/product_model.dart';
import '../../../../data/models/category_model.dart';
import '../../../../data/models/brand_model.dart';
import '../../../../data/models/uom_model.dart';
import '../../../../domain/utils/product_validators.dart';
import '../../../providers/products_provider.dart';
import '../../../providers/lookup_providers.dart';
import '../../../../../settings/presentation/widgets/add_edit_category_sheet.dart';

class AddProductScreen extends ConsumerStatefulWidget {
  const AddProductScreen({super.key});

  @override
  ConsumerState<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends ConsumerState<AddProductScreen> {
  int _currentStep = 0;
  final int _totalSteps = 4;

  // Controllers for steps
  // Step 1
  final TextEditingController _modelController = TextEditingController();
  Brand? _selectedBrand;

  // Step 2
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _specsController = TextEditingController();

  // Step 3
  Category? _selectedCategory;
  Uom? _selectedUom;

  // Step 4
  File? _productImage;

  // Validation
  final FocusNode _modelFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _modelFocusNode.addListener(_onModelFocusChange);
  }

  @override
  void dispose() {
    _modelFocusNode.removeListener(_onModelFocusChange);
    _modelFocusNode.dispose();
    _modelController.dispose();
    _nameController.dispose();
    _specsController.dispose();
    super.dispose();
  }

  void _onModelFocusChange() {
    if (!_modelFocusNode.hasFocus) {
      _validateModel();
    }
  }

  void _validateModel() {
    final currentModel = _modelController.text.trim();
    if (currentModel.isEmpty) return;

    final products = ref.read(productsProvider).value ?? [];

    // 1. Exact Match: Model ONLY (User request)
    final exactMatchProduct = ProductValidators.findExactMatch(
      products,
      currentModel,
    );

    if (exactMatchProduct != null) {
      // Block user
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Producto Duplicado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (exactMatchProduct.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: CachedNetworkImage(
                      imageUrl: exactMatchProduct.imageUrl!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                ),
              Text(
                'Ya existe un equipo con el modelo "$currentModel" en el inventario.\n\n'
                'Marca existente: ${exactMatchProduct.brand?.name ?? "Desconocida"}',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
                _modelController.clear(); // Clear to prevent advancing
              },
              child: const Text('Entendido'),
            ),
          ],
        ),
      );
      return;
    }

    // 2. Fuzzy Match: 80% Similarity on Model
    final similarProduct = ProductValidators.findSimilarMatch(
      products,
      currentModel,
    );

    if (similarProduct != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Modelo Similar Detectado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (similarProduct.imageUrl != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: CachedNetworkImage(
                      imageUrl: similarProduct.imageUrl!,
                      height: 100,
                      width: 100,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[200],
                        child: const Center(child: CircularProgressIndicator()),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 100,
                        width: 100,
                        color: Colors.grey[200],
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                ),
              Text(
                'Ya existe un modelo similar en el inventario:\n\n'
                'Modelo: ${similarProduct.model}\n'
                'Marca: ${similarProduct.brand?.name ?? "Desconocida"}\n\n'
                '¿Estás seguro de continuar?',
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                context.pop();
                // Focus back to edit
                FocusScope.of(context).requestFocus(_modelFocusNode);
              },
              child: const Text('Corregir'),
            ),
            TextButton(
              onPressed: () {
                context.pop();
                // Allow proceed
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
    }
  }

  void nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      _handleBackNavigation();
    }
  }
 
  Future<bool> _confirmExit() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text(
          'Si sales ahora, perderás toda la información que has ingresado.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Descartar',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }
 
  Future<void> _handleBackNavigation() async {
    if (_currentStep == 0) {
      context.pop();
      return;
    }
 
    final shouldPop = await _confirmExit();
    if (shouldPop && mounted) {
      context.pop();
    }
  }

  Future<void> submitProduct() async {
    final product = Product(
      id: '', // Generated by DB
      userId: '', // Handled by Repository
      name: _nameController.text,
      brandId: _selectedBrand?.id,
      brand: _selectedBrand,
      model: _modelController.text.trim().isEmpty
          ? 'NO APLICA'
          : _modelController.text.trim(),
      specs: _specsController.text,
      categoryId: _selectedCategory?.id,
      category: _selectedCategory,
      uomId: _selectedUom?.id,
      uom: _selectedUom?.symbol,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      Uint8List? imageBytes;
      String? imageExtension;

      if (_productImage != null) {
        imageBytes = await _productImage!.readAsBytes();
        imageExtension = _productImage!.path.split('.').last;
      }

      await ref
          .read(productsProvider.notifier)
          .createProduct(
            product,
            imageBytes: imageBytes,
            imageExtension: imageExtension,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto creado exitosamente')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al crear producto: $e')));
      }
    }
  }

  Future<void> handleAiAutofill() async {
    final brand = _selectedBrand;
    final model = _modelController.text.trim();

    if (brand == null || model.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marca y modelo son requeridos para autocompletar'),
          ),
        );
      }
      return;
    }

    try {
      final data = await ref
          .read(productsRepositoryProvider)
          .fetchProductDetailsFromAI(brand.name, model);

      if (mounted) {
        setState(() {
          if (data['name'] != null) {
            _nameController.text = data['name'];
          }
          if (data['specs'] != null) {
            _specsController.text = data['specs'];
          }
          // Optional: handle category matching if needed
          // if (data['category'] != null) ...
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos autocompletados con IA ✨')),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error al consultar IA';
        if (e.toString().contains('503') ||
            e.toString().toLowerCase().contains('overloaded')) {
          errorMessage =
              'El servicio de IA está congestionado. Intenta de nuevo en unos momentos.';
        } else if (e.toString().contains('429')) {
          errorMessage =
              'Has excedido el límite de consultas. Intenta más tarde.';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMessage)));
      }
    }
  }

  void _showAddCategoryDialog() async {
    final newCategory = await AddEditCategorySheet.show(context);
    if (newCategory != null && mounted) {
      setState(() {
        _selectedCategory = newCategory; // Auto-select new category
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final brandsAsync = ref.watch(brandsProvider);
    final brandsList = brandsAsync.valueOrNull ?? [];

    // Auto-select "SIN MARCA" as default if none selected
    if (_selectedBrand == null && brandsAsync.hasValue) {
      final brands = brandsAsync.value!;
      if (brands.isNotEmpty) {
        final sinMarca = brands.firstWhere(
          (b) => b.name.toUpperCase() == 'SIN MARCA',
          orElse: () => brands.first,
        );
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _selectedBrand == null) {
            setState(() => _selectedBrand = sinMarca);
          }
        });
      }
    }

    final categoriesAsync = ref.watch(categoriesProvider);
    final categoriesList = (categoriesAsync.valueOrNull ?? [])
        .toList(); // Create mutable copy

    final uomsAsync = ref.watch(uomsProvider);
    final uomsList = uomsAsync.valueOrNull ?? [];

    // Ensure selected category is in the list
    if (_selectedCategory != null &&
        !categoriesList.contains(_selectedCategory)) {
      categoriesList.add(_selectedCategory!);
    }

    // Ensure selected uom is in the list
    if (_selectedUom != null && !uomsList.contains(_selectedUom)) {
      uomsList.add(_selectedUom!);
    }

    return PopScope(
      canPop: _currentStep == 0,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _confirmExit();
        if (shouldPop && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Agregar producto'),
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colors.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors.onSurface),
          onPressed: _handleBackNavigation,
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: WizardProgressBar(
            currentStep: _currentStep + 1,
            totalSteps: _totalSteps,
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentStep,
        children: [
          AddProductStep1(
            modelController: _modelController,
            focusNode: _modelFocusNode,
            selectedBrand: _selectedBrand,
            brands: brandsList,
            onBrandChanged: (val) {
              setState(() {
                _selectedBrand = val;
              });
            },
            onNext: nextStep,
            onCancel: _handleBackNavigation,
            onAddBrand: (name) async {
              try {
                final newBrand = await ref
                    .read(lookupRepositoryProvider)
                    .addBrand(name);
                ref.invalidate(brandsProvider);
                setState(() {
                  _selectedBrand = newBrand;
                });
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al agregar marca: $e')),
                );
              }
            },
          ),
          AddProductStep2(
            nameController: _nameController,
            specsController: _specsController,
            onNext: nextStep,
            onBack: prevStep,
            onCancel: _handleBackNavigation,
            onAiAutofill: handleAiAutofill,
            isAiAutofillEnabled: _modelController.text.trim().isNotEmpty,
          ),
          AddProductStep3(
            selectedCategory: _selectedCategory,
            categories: categoriesList,
            onCategoryChanged: (val) {
              setState(() {
                _selectedCategory = val;
              });
            },
            onAddCategory: _showAddCategoryDialog,

            selectedUom: _selectedUom,
            uoms: uomsList,
            onUomChanged: (val) {
              setState(() {
                _selectedUom = val;
              });
            },

            onNext: nextStep,
            onBack: prevStep,
            onCancel: _handleBackNavigation,
          ),
          AddProductStep4(
            brand: _selectedBrand,
            model: _modelController.text.trim().isEmpty
                ? 'NO APLICA'
                : _modelController.text.trim(),
            name: _nameController.text,
            specs: _specsController.text,
            category: _selectedCategory?.name,
            image: _productImage,
            onPickImage: (source) => _pickImageFromSource(source),
            onBack: prevStep,
            onCancel: _handleBackNavigation,
            onSave: submitProduct,
          ),
        ],
      ),
    ),
  );
}

  Future<void> _pickImageFromSource(ImageSource source) async {
    final theme = Theme.of(context);
    final picker = ImagePicker();
    try {
      final XFile? pickedImage = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedImage != null) {
        final croppedFile = await ImageCropper().cropImage(
          sourcePath: pickedImage.path,
          uiSettings: [
            AndroidUiSettings(
              toolbarTitle: 'Recortar',
              toolbarColor: theme.colorScheme.primary,
              toolbarWidgetColor: theme.colorScheme.onPrimary,
              initAspectRatio: CropAspectRatioPreset.square,
              lockAspectRatio: true,
            ),
            IOSUiSettings(title: 'Recortar'),
          ],
        );

        if (croppedFile != null) {
          setState(() {
            _productImage = File(croppedFile.path);
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar imagen: $e')),
        );
      }
    }
  }
}
