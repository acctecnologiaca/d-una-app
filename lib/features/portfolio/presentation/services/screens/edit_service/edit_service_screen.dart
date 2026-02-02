import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../../../shared/widgets/form_bottom_bar.dart';
import '../../../../data/models/service_model.dart';
import '../../../../data/models/service_rate_model.dart';
import '../../../../data/models/category_model.dart';
import '../../../providers/lookup_providers.dart';
import '../../../providers/services_provider.dart';

class EditServiceScreen extends ConsumerStatefulWidget {
  final ServiceModel service;

  const EditServiceScreen({super.key, required this.service});

  @override
  ConsumerState<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends ConsumerState<EditServiceScreen> {
  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _warrantyTimeController;

  // State
  Category? _selectedCategory;
  bool _isPriceFixed = true;
  ServiceRate? _selectedRateUnit;
  bool _hasWarranty = false;
  String? _selectedWarrantyPeriod;

  // Initial State for Dirty Check
  late String _initialName;
  late String _initialDescription;
  late String _initialPrice;
  late String _initialWarrantyTime;
  late Category? _initialCategory;
  late bool _initialIsPriceFixed;
  late ServiceRate? _initialRateUnit;
  late bool _initialHasWarranty;
  late String? _initialWarrantyPeriod;

  final List<String> _warrantyPeriods = ['Días', 'Meses', 'Años'];

  @override
  void initState() {
    super.initState();
    _initializeValues();
  }

  void _initializeValues() {
    final s = widget.service;
    _nameController = TextEditingController(text: s.name);
    _descriptionController = TextEditingController(text: s.description);
    _priceController = TextEditingController(
      text: s.price > 0 ? s.price.toStringAsFixed(2) : '',
    );
    // If price is 0, it might be variable or just 0. The mock has "Tipo de precio".
    // We assume if price > 0 it's fixed, otherwise variable?
    // Or we use a flag if we had one. The AddService logic had _isPriceFixed.
    // The ServiceModel stores price. If price is 0, is it variable?
    // Let's assume if price > 0 or we have a flag. ServiceModel doesn't seem to have isFixed flag.
    // We will infer: if price > 0 then Fixed.
    // Actually, AddServiceScreen stores 0.0 if not fixed.
    _isPriceFixed =
        s.price >
        0; // Simple inference, might need refinement if 0.0 is a valid fixed price.
    // But for Edit, let's start with this.

    _selectedCategory = s.category;
    _selectedRateUnit = s.serviceRate; // Or find by ID if null
    _hasWarranty = s.hasWarranty;
    _warrantyTimeController = TextEditingController(
      text: s.warrantyTime?.toString() ?? '',
    );
    _selectedWarrantyPeriod = s.warrantyUnit;

    // Capture initial state
    _initialName = s.name;
    _initialDescription = s.description ?? '';
    _initialPrice = s.price > 0 ? s.price.toStringAsFixed(2) : '';
    _initialCategory = s.category;
    _initialIsPriceFixed = _isPriceFixed;
    _initialRateUnit = s.serviceRate;
    _initialHasWarranty = _hasWarranty;
    _initialWarrantyTime = s.warrantyTime?.toString() ?? '';
    _initialWarrantyPeriod = s.warrantyUnit;

    // Listeners
    _nameController.addListener(_onFormChanged);
    _descriptionController.addListener(_onFormChanged);
    _priceController.addListener(_onFormChanged);
    _warrantyTimeController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _warrantyTimeController.dispose();
    super.dispose();
  }

  void _onFormChanged() {
    setState(() {});
  }

  bool get _isDirty {
    return _nameController.text != _initialName ||
        _descriptionController.text != _initialDescription ||
        _priceController.text != _initialPrice ||
        _selectedCategory != _initialCategory ||
        _isPriceFixed != _initialIsPriceFixed ||
        _selectedRateUnit != _initialRateUnit ||
        _hasWarranty != _initialHasWarranty ||
        _warrantyTimeController.text != _initialWarrantyTime ||
        _selectedWarrantyPeriod != _initialWarrantyPeriod;
  }

  Future<void> _submitUpdates() async {
    if (!_isDirty) return;

    final priceVal =
        double.tryParse(_priceController.text.replaceAll(',', '.')) ?? 0.0;

    final updatedService = widget.service.copyWith(
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      categoryId: _selectedCategory?.id,
      // category object update handled by passing ID? copyWith might usually take objects too if we want to keep UI in sync immediately
      category: _selectedCategory,
      price: _isPriceFixed ? priceVal : 0.0,
      serviceRateId: _selectedRateUnit?.id,
      serviceRate: _selectedRateUnit,
      hasWarranty: _hasWarranty,
      warrantyTime: _hasWarranty
          ? int.tryParse(_warrantyTimeController.text)
          : null,
      warrantyUnit: _hasWarranty ? _selectedWarrantyPeriod : null,
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(servicesProvider.notifier).updateService(updatedService);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Servicio actualizado exitosamente')),
        );
        ref.invalidate(servicesProvider);
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar servicio: $e')),
        );
      }
    }
  }

  // --- Add/Fetch Helpers Reused from AddServiceScreen ---
  Future<void> _addNewCategory(String name) async {
    try {
      final newCategory = await ref
          .read(lookupRepositoryProvider)
          .addCategory(name);
      ref.invalidate(categoriesProvider);
      setState(() {
        _selectedCategory = newCategory;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showAddCategoryDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar nueva categoría'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Nombre de la categoría',
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                _addNewCategory(textController.text.trim());
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  // Same for Rate?
  // ...

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Providers
    final categoriesAsync = ref.watch(categoriesProvider);
    final categoriesList = (categoriesAsync.valueOrNull ?? []).toList();
    if (_selectedCategory != null &&
        !categoriesList.contains(_selectedCategory)) {
      categoriesList.add(_selectedCategory!);
    }

    final ratesAsync = ref.watch(serviceRatesProvider);
    final ratesList = (ratesAsync.valueOrNull ?? []).toList();
    if (_selectedRateUnit != null && !ratesList.contains(_selectedRateUnit)) {
      ratesList.add(_selectedRateUnit!); // ensure selected is present
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Modificar servicio'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Category
                  CustomDropdown<Category>(
                    label: 'Categoría',
                    value: _selectedCategory,
                    items: categoriesList,
                    itemLabelBuilder: (c) => c.name,
                    onChanged: (val) => setState(() => _selectedCategory = val),
                    showAddOption: true,
                    addOptionLabel: 'Agregar',
                    onAddPressed: _showAddCategoryDialog,
                  ),
                  const SizedBox(height: 24),

                  // Name
                  CustomTextField(
                    label: 'Nombre del servicio',
                    controller: _nameController,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 24),

                  // Description
                  CustomTextField(
                    label: 'Descripción',
                    controller: _descriptionController,
                    maxLines: 4,
                    minLines: 4, // Make it look like a box
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: 24),

                  // Price Type & Price using logic
                  // Mock: "Tipo de precio*" -> Fijo dropdown
                  CustomDropdown<bool>(
                    label: 'Tipo de precio',
                    value: _isPriceFixed,
                    items: const [true, false],
                    itemLabelBuilder: (val) => val ? 'Fijo' : 'Variable',
                    onChanged: (val) {
                      if (val != null) setState(() => _isPriceFixed = val);
                    },
                  ),
                  const SizedBox(height: 24),

                  if (_isPriceFixed) ...[
                    CustomTextField(
                      label: 'Precio',
                      controller: _priceController,
                      prefixText: '\$ ',
                      hintText: '0.00',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Sin impuesto',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Rate Unit
                  CustomDropdown<ServiceRate>(
                    label: 'Tarifa por',
                    value: _selectedRateUnit,
                    items: ratesList,
                    itemLabelBuilder: (r) => '${r.name} (${r.symbol})',
                    onChanged: (val) => setState(() => _selectedRateUnit = val),
                    // Add option if needed, for brevity maybe skip unless requested
                  ),
                  const SizedBox(height: 24),

                  // Warranty Toggle
                  // Mock: "No ofrezco garantía para este servicio" [Switch]
                  // If switch is ON -> HasWarranty = FALSE (?)
                  // If switch is OFF -> HasWarranty = TRUE (?)
                  // Wait, usually "Enable" switches are positive.
                  // If text is "No ofrezco...", then ON means "I DO NOT offer".
                  // Let's assume standard behavior: Switch OFF = I offer warranty? Or Switch ON = I agree with statement?
                  // Let's look at the screenshot again if possible. It's greyed out (left).
                  // And fields "Cantidad" and "Período" ARE VISIBLE.
                  // This strongly implies:
                  // Switch OFF (Left) -> Statement "No ofrezco..." is FALSE -> I DO offer warranty -> Fields Shown.
                  // Switch ON (Right) -> Statement "No ofrezco..." is TRUE -> I DO NOT offer warranty -> Fields Hidden.
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'No ofrezco garantía para este servicio',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold, // Mock looks bold-ish
                            color: colors.onSurface,
                          ),
                        ),
                      ),
                      Switch(
                        value:
                            !_hasWarranty, // If hasWarranty is true, switch (No offer) is false.
                        onChanged: (val) {
                          // val is "No offer".
                          // If val is true (No offer), hasWarranty = false.
                          // If val is false (Yes offer), hasWarranty = true.
                          setState(() => _hasWarranty = !val);
                        },
                      ),
                    ],
                  ),

                  if (_hasWarranty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: CustomTextField(
                            label: 'Cantidad*',
                            controller: _warrantyTimeController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: CustomDropdown<String>(
                            label: 'Período',
                            value: _selectedWarrantyPeriod,
                            items: _warrantyPeriods,
                            itemLabelBuilder: (val) => val,
                            onChanged: (val) =>
                                setState(() => _selectedWarrantyPeriod = val),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 48),
                  FormBottomBar(
                    onCancel: () => context.pop(),
                    onSave: _submitUpdates,
                    isSaveEnabled:
                        _isDirty &&
                        _nameController
                            .text
                            .isNotEmpty, // simplified validation
                    saveLabel: 'Guardar',
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          /*
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            child: FormBottomBar(
              onCancel: () => context.pop(),
              onSave: _submitUpdates,
              isSaveEnabled:
                  _isDirty &&
                  _nameController.text.isNotEmpty, // simplified validation
              saveLabel: 'Guardar',
            ),
          ),
          const SizedBox(height: 12),*/
        ],
      ),
    );
  }
}
