import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../../../shared/widgets/wizard_progress_bar.dart';
import '../../../data/models/service_model.dart';
import '../../../data/models/service_rate_model.dart';
import '../../../data/models/category_model.dart';
import '../../providers/lookup_providers.dart';
import '../../providers/services_provider.dart';
import 'steps/add_service_step1.dart';
import 'steps/add_service_step2.dart';
import 'steps/add_service_step3.dart';
import 'steps/add_service_step4.dart';
import 'steps/add_service_step5.dart';

class AddServiceScreen extends ConsumerStatefulWidget {
  final ServiceModel? serviceToEdit;

  const AddServiceScreen({super.key, this.serviceToEdit});

  @override
  ConsumerState<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends ConsumerState<AddServiceScreen> {
  int _currentStep = 0;
  final int _totalSteps = 5;

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  // Step 2 State
  bool _isPriceFixed = true;
  ServiceRate? _selectedRateUnit;

  // Step 3 State
  Category? _selectedCategory;

  // Step 4 State
  bool _hasWarranty = false;
  late TextEditingController _warrantyTimeController;
  String? _selectedWarrantyPeriod;

  @override
  void initState() {
    super.initState();
    final service = widget.serviceToEdit;

    // Initialize controllers
    _nameController = TextEditingController(text: service?.name);
    _descriptionController = TextEditingController(text: service?.description);
    _priceController = TextEditingController(
      text: service?.price.toString() ?? '',
    );

    // We can't synchronously set _selectedRateUnit object from ID here easily if we don't have the list loaded.
    // However, ServiceModel now has a nullable ServiceRate object.
    _selectedRateUnit = service?.serviceRate;

    _selectedCategory = service?.category;

    // Step 4 Init
    _hasWarranty = service?.hasWarranty ?? false;
    _warrantyTimeController = TextEditingController(
      text: service?.warrantyTime?.toString() ?? '',
    );
    _selectedWarrantyPeriod = service?.warrantyUnit;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _warrantyTimeController.dispose();
    super.dispose();
  }

  void nextStep() {
    if (_currentStep < _totalSteps - 1) {
      // Logic to auto-set 0 if variable
      if (_currentStep == 1 && !_isPriceFixed) {
        _priceController.text = '0';
      }
      setState(() {
        _currentStep++;
      });
    } else {
      // Submit handled by step 5 button
    }
  }

  void prevStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    } else {
      context.pop();
    }
  }

  Future<void> _submitService() async {
    try {
      final newService = ServiceModel(
        id: widget.serviceToEdit?.id ?? '',
        userId: '', // Handled by Repository
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: _isPriceFixed
            ? double.tryParse(_priceController.text) ?? 0.0
            : 0.0,
        serviceRateId: _selectedRateUnit?.id ?? '',
        serviceRate: _selectedRateUnit,
        categoryId: _selectedCategory?.id,
        category: _selectedCategory,
        hasWarranty: _hasWarranty,
        warrantyTime: _hasWarranty
            ? int.tryParse(_warrantyTimeController.text)
            : null,
        warrantyUnit: _selectedWarrantyPeriod,
        createdAt: DateTime.now(), // Repository/DB handles this
        updatedAt: DateTime.now(),
      );

      if (widget.serviceToEdit != null) {
        await ref.read(servicesRepositoryProvider).updateService(newService);
      } else {
        await ref.read(servicesRepositoryProvider).createService(newService);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Servicio guardado exitosamente')),
        );
        ref.invalidate(servicesProvider); // Refresh list
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar servicio: $e')),
        );
      }
    }
  }

  Future<void> _addNewCategory(String name) async {
    try {
      final newCategory = await ref
          .read(lookupRepositoryProvider)
          .addCategory(name);
      ref.invalidate(categoriesProvider); // Refresh the list
      setState(() {
        _selectedCategory = newCategory; // Auto-select new category
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al agregar categoría: $e')),
        );
      }
    }
  }

  Future<void> _addNewRateUnit(String name, String symbol) async {
    try {
      final newRate = await ref
          .read(lookupRepositoryProvider)
          .addServiceRate(name, symbol);
      ref.invalidate(serviceRatesProvider); // Refresh the list
      setState(() {
        _selectedRateUnit = newRate; // Auto-select new unit
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al agregar tarifa: $e')));
      }
    }
  }

  void _showAddDialog({
    required String title,
    required String label,
    required Function(String) onAdd,
  }) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: textController,
          decoration: InputDecoration(labelText: label),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final val = textController.text.trim();
              if (val.isNotEmpty) {
                onAdd(val);
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showAddRateDialog({
    required Function(String name, String symbol) onAdd,
  }) {
    final nameController = TextEditingController();
    final symbolController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar nueva tarifa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre (Ej. Hora)'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: symbolController,
              decoration: const InputDecoration(labelText: 'Símbolo (Ej. h)'),
              textCapitalization: TextCapitalization.none,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final symbol = symbolController.text.trim();
              if (name.isNotEmpty && symbol.isNotEmpty) {
                onAdd(name, symbol);
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Watch providers
    final categoriesAsync = ref.watch(categoriesProvider);
    final ratesAsync = ref.watch(serviceRatesProvider);

    // Prepare lists (handle mismatch if editing)
    final categoriesList = categoriesAsync.valueOrNull ?? [];
    if (_selectedCategory != null &&
        !categoriesList.contains(_selectedCategory)) {
      categoriesList.add(_selectedCategory!);
    }

    final ratesList = ratesAsync.valueOrNull ?? [];
    if (_selectedRateUnit != null &&
        !ratesList.any((e) => e.id == _selectedRateUnit!.id)) {
      // If the exact object isn't in the list but we have one, we can add it or just use it.
      // Since ServiceRate uses Equatable, simple contains might fail if instances differ but props same?
      // Actually Equatable checks props, so contains should work if props match.
      // But if we just loaded it from ServiceModel, it should match ID.
      if (!ratesList.contains(_selectedRateUnit)) {
        ratesList.add(_selectedRateUnit!); // Force add valid selection
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Agregar servicio'),
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
          onPressed: () => prevStep(),
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
          // Step 1
          AddServiceStep1(
            nameController: _nameController,
            descriptionController: _descriptionController,
            onNext: nextStep,
            onCancel: () => context.pop(),
          ),

          // Step 2
          AddServiceStep2(
            priceController: _priceController,
            isPriceFixed: _isPriceFixed,
            onPriceTypeChanged: (isFixed) {
              setState(() {
                _isPriceFixed = isFixed;
              });
            },
            selectedRateUnit: _selectedRateUnit,
            rateUnits: ratesList,
            onRateUnitChanged: (ServiceRate? val) {
              setState(() {
                _selectedRateUnit = val;
              });
            },
            onAddRateUnit: () => _showAddRateDialog(onAdd: _addNewRateUnit),
            onNext: nextStep,
            onBack: prevStep,
            onCancel: () => context.pop(),
          ),

          // Step 3
          AddServiceStep3(
            selectedCategory: _selectedCategory,
            categories: categoriesList,
            onCategoryChanged: (val) {
              setState(() {
                _selectedCategory = val;
              });
            },
            onAddCategory: () => _showAddDialog(
              title: 'Agregar nueva categoría',
              label: 'Nombre de la categoría',
              onAdd: _addNewCategory,
            ),
            onNext: nextStep,
            onBack: prevStep,
            onCancel: () => context.pop(),
          ),

          // Step 4
          AddServiceStep4(
            hasWarranty: _hasWarranty,
            onWarrantyChanged: (val) {
              setState(() {
                _hasWarranty = val;
              });
            },
            timeController: _warrantyTimeController,
            selectedPeriod: _selectedWarrantyPeriod,
            onPeriodChanged: (val) {
              setState(() {
                _selectedWarrantyPeriod = val;
              });
            },
            onNext: nextStep,
            onBack: prevStep,
            onCancel: () => context.pop(),
          ),

          // Step 5
          AddServiceStep5(
            serviceName: _nameController.text,
            category: _selectedCategory?.name ?? '',
            hasWarranty: _hasWarranty,
            warrantyTime: int.tryParse(_warrantyTimeController.text),
            warrantyUnit: _selectedWarrantyPeriod,
            description: _descriptionController.text,
            price: double.tryParse(_priceController.text) ?? 0.0,
            rateUnit: _selectedRateUnit != null
                ? '${_selectedRateUnit!.name} (${_selectedRateUnit!.symbol})'
                : '',
            isPriceFixed: _isPriceFixed,
            onBack: prevStep,
            onCancel: () => context.pop(),
            onSubmit: _submitService,
          ),
        ],
      ),
    );
  }
}
