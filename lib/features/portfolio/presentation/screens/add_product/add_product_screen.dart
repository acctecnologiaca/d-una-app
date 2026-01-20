import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../../shared/widgets/wizard_progress_bar.dart';
import 'steps/add_product_step1.dart';
import 'steps/add_product_step2.dart';

import 'steps/add_product_step3.dart';
import 'steps/add_product_step4.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product_model.dart';
import '../../../presentation/providers/products_provider.dart';

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
  String? _selectedBrand;

  // Step 2
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _specsController = TextEditingController();

  // Step 3
  String? _selectedCategory;

  // Step 4
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
    final exactMatchProduct = products
        .where((p) => p.model?.toLowerCase() == currentModel.toLowerCase())
        .firstOrNull;

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
                'Marca existente: ${exactMatchProduct.brand}',
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
    // Filter by same brand? User said "decirle cual es y de que marca", implies checking all brands or confirming brand context.
    // "Ya existe un modelo similar... y decirle cual es y de que marca".
    // This implies we check ALL products.

    Product? similarProduct;
    for (final p in products) {
      final similarity = _calculateSimilarity(
        currentModel.toLowerCase(),
        p.model!.toLowerCase(),
      );
      if (similarity >= 0.8) {
        similarProduct = p;
        break; // Stop at first similar found
      }
    }

    if (similarProduct != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Modelo Similar Detectado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (similarProduct!.imageUrl != null)
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
                'Marca: ${similarProduct.brand}\n\n'
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

  /// Calculates similarity between two strings (0.0 to 1.0) using Levenshtein distance.
  double _calculateSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final distance = _levenshteinDistance(s1, s2);
    final maxLength = (s1.length > s2.length) ? s1.length : s2.length;
    return 1.0 - (distance / maxLength);
  }

  int _levenshteinDistance(String s1, String s2) {
    if (s1 == s2) return 0;
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    List<int> v0 = List<int>.generate(s2.length + 1, (i) => i);
    List<int> v1 = List<int>.filled(s2.length + 1, 0);

    for (int i = 0; i < s1.length; i++) {
      v1[0] = i + 1;
      for (int j = 0; j < s2.length; j++) {
        int cost = (s1.codeUnitAt(i) == s2.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }
    return v1[s2.length];
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      context.pop();
    }
  }

  Future<void> _submitProduct() async {
    final product = Product(
      id: '', // Generated by DB
      userId: '', // Handled by Repository
      name: _nameController.text,
      brand: _selectedBrand,
      model: _modelController.text,
      specs: _specsController.text,
      category: _selectedCategory,
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

  Future<void> _handleAiAutofill() async {
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
          .fetchProductDetailsFromAI(brand, model);

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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al consultar IA: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
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
          onPressed: () => context.pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: WizardProgressBar(
            currentStep: _currentStep,
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
            onBrandChanged: (val) {
              setState(() {
                _selectedBrand = val;
              });
            },
            onNext: _nextStep,
            onCancel: () => context.pop(),
          ),
          AddProductStep2(
            nameController: _nameController,
            specsController: _specsController,
            onNext: _nextStep,
            onBack: _prevStep,
            onCancel: () => context.pop(),
            onAiAutofill: _handleAiAutofill,
          ),
          AddProductStep3(
            selectedCategory: _selectedCategory,
            onCategoryChanged: (val) {
              setState(() {
                _selectedCategory = val;
              });
            },
            onNext: _nextStep,
            onBack: _prevStep,
            onCancel: () => context.pop(),
          ),
          AddProductStep4(
            brand: _selectedBrand,
            model: _modelController.text,
            name: _nameController.text,
            specs: _specsController.text,
            category: _selectedCategory,
            image: _productImage,
            onPickImage: (source) => _pickImageFromSource(source),
            onBack: _prevStep,
            onCancel: () => context.pop(),
            onSave: _submitProduct,
          ),
        ],
      ),
    );
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
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
              toolbarColor: Theme.of(context).colorScheme.primary,
              toolbarWidgetColor: Theme.of(context).colorScheme.onPrimary,
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
