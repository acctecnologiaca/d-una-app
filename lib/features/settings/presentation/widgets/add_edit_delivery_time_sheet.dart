import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/custom_action_sheet.dart';
import 'package:d_una_app/shared/widgets/custom_text_field.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/custom_button.dart';
import 'package:d_una_app/features/portfolio/data/models/delivery_time_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';

class AddEditDeliveryTimeSheet extends ConsumerStatefulWidget {
  final DeliveryTime? deliveryTime;

  const AddEditDeliveryTimeSheet({super.key, this.deliveryTime});

  @override
  ConsumerState<AddEditDeliveryTimeSheet> createState() =>
      _AddEditDeliveryTimeSheetState();
}

class _AddEditDeliveryTimeSheetState
    extends ConsumerState<AddEditDeliveryTimeSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _minController;
  late TextEditingController _maxController;

  String _selectedType = 'delivery';
  String _selectedUnit = 'days';
  bool _isIndefinite = false;
  bool _isLoading = false;
  bool _hasChanged = false;

  final _typeOptions = const [
    {'value': 'delivery', 'label': 'Solo entrega (Productos)'},
    {'value': 'execution', 'label': 'Solo ejecución (Servicios)'},
    {'value': 'both', 'label': 'Ambos (Entrega y ejecución)'},
  ];

  final _unitOptions = const [
    {'value': 'hours', 'label': 'Horas'},
    {'value': 'days', 'label': 'Días'},
    {'value': 'weeks', 'label': 'Semanas'},
    {'value': 'months', 'label': 'Meses'},
  ];

  @override
  void initState() {
    super.initState();
    final isEditing = widget.deliveryTime != null;
    final dt = widget.deliveryTime;

    _nameController = TextEditingController(text: dt?.name ?? '');
    _minController = TextEditingController(
      text: dt?.minValue?.toString() ?? '',
    );
    _maxController = TextEditingController(
      text: dt?.maxValue?.toString() ?? '',
    );

    if (isEditing) {
      _selectedType = dt!.type;
      _selectedUnit = dt.unit;
      _isIndefinite = dt.minValue == null && dt.maxValue == null;
    }

    _nameController.addListener(_updateHasChanged);
    _minController.addListener(_updateHasChanged);
    _maxController.addListener(_updateHasChanged);
  }

  void _updateHasChanged() {
    if (widget.deliveryTime == null) return;

    final currentName = _nameController.text.trim();
    final currentMin = _minController.text.trim();
    final currentMax = _maxController.text.trim();

    final prevName = widget.deliveryTime!.name;
    final prevMin = widget.deliveryTime!.minValue?.toString() ?? '';
    final prevMax = widget.deliveryTime!.maxValue?.toString() ?? '';

    final prevType = widget.deliveryTime!.type;
    final prevUnit = widget.deliveryTime!.unit;
    final prevIsIndefinite =
        widget.deliveryTime!.minValue == null &&
        widget.deliveryTime!.maxValue == null;

    final isChanged =
        currentName != prevName ||
        currentMin != prevMin ||
        currentMax != prevMax ||
        _selectedType != prevType ||
        _selectedUnit != prevUnit ||
        _isIndefinite != prevIsIndefinite;

    if (_hasChanged != isChanged) {
      setState(() => _hasChanged = isChanged);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (!_isIndefinite) {
      final minVal = int.tryParse(_minController.text);
      final maxVal = int.tryParse(_maxController.text);

      if (minVal == null || maxVal == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Debes ingresar valores válidos de tiempo.'),
          ),
        );
        return;
      }
      if (minVal > maxVal) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('El valor mínimo no puede ser mayor al máximo.'),
          ),
        );
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(lookupRepositoryProvider);
      final isEditing = widget.deliveryTime != null;

      final minV = _isIndefinite ? null : int.parse(_minController.text);
      final maxV = _isIndefinite ? null : int.parse(_maxController.text);

      if (isEditing) {
        await repo.updateDeliveryTime(
          id: widget.deliveryTime!.id,
          name: _nameController.text.trim(),
          type: _selectedType,
          unit: _isIndefinite ? 'days' : _selectedUnit,
          minValue: minV,
          maxValue: maxV,
        );
      } else {
        await repo.addDeliveryTime(
          name: _nameController.text.trim(),
          type: _selectedType,
          unit: _isIndefinite ? 'days' : _selectedUnit,
          minValue: minV,
          maxValue: maxV,
          orderIdx: 100, // Put user created ones at the bottom by default
        );
      }

      ref.invalidate(deliveryTimesProvider);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              isEditing ? 'Tiempo actualizado' : 'Tiempo agregado exitosamente',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Error al guardar: $e',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final isEditing = widget.deliveryTime != null;

    final actions = [
      const SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          mainAxisAlignment: isEditing
              ? MainAxisAlignment.spaceBetween
              : MainAxisAlignment.end,
          children: [
            if (isEditing)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                onPressed: () async {
                  final scaffoldMessenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  final errorColor = Theme.of(context).colorScheme.onError;

                  navigator.pop(); // Close sheet

                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Eliminar tiempo'),
                      content: Text(
                        '¿Estás seguro de que deseas eliminar el tiempo "${widget.deliveryTime!.name}"?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.error,
                          ),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    try {
                      await ref
                          .read(lookupRepositoryProvider)
                          .deleteDeliveryTime(widget.deliveryTime!.id);
                      ref.invalidate(deliveryTimesProvider);
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(behavior: SnackBarBehavior.floating, content: Text('Tiempo eliminado')),
                      );
                    } catch (e) {
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: Text(
                            'Error: $e',
                            style: TextStyle(color: errorColor),
                          ),
                        ),
                      );
                    }
                  }
                },
              ),
            if (isEditing) const Spacer(),
            CustomButton(
              text: 'Confirmar',
              isFullWidth: false,
              isLoading: _isLoading,
              onPressed: (!isEditing || _hasChanged) ? _save : null,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
    ];

    return CustomActionSheet(
      title: isEditing ? 'Modificar tiempo' : 'Agregar tiempo',
      showDivider: false,
      isContentScrollable: true,
      actions: actions,
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              CustomDropdown<String>(
                label: 'Aplica para',
                items: _typeOptions.map((e) => e['value']!).toList(),
                value: _selectedType,
                itemLabelBuilder: (val) {
                  return _typeOptions.firstWhere(
                    (e) => e['value'] == val,
                  )['label']!;
                },
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _selectedType = val);
                    _updateHasChanged();
                  }
                },
              ),
              const SizedBox(height: 16),
              CustomTextField(
                label: 'Nombre a mostrar',
                hintText: 'Ej. 1 a 2 semanas, Bajo pedido...',
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Campo requerido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Checkbox(
                    value: _isIndefinite,
                    onChanged: (val) {
                      setState(() {
                        _isIndefinite = val ?? false;
                      });
                      _updateHasChanged();
                    },
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() => _isIndefinite = !_isIndefinite);
                        _updateHasChanged();
                      },
                      child: Text(
                        'Es un tiempo indefinido (sin rango numérico claro, ej. Bajo Pedido)',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              ),
              if (!_isIndefinite) ...[
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Valores estructurados',
                  style: textTheme.titleSmall?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                CustomDropdown<String>(
                  label: 'Unidad de tiempo',
                  items: _unitOptions.map((e) => e['value']!).toList(),
                  value: _selectedUnit,
                  itemLabelBuilder: (val) {
                    return _unitOptions.firstWhere(
                      (e) => e['value'] == val,
                    )['label']!;
                  },
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedUnit = val);
                      _updateHasChanged();
                    }
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CustomTextField(
                        label: 'Mínimo',
                        controller: _minController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: CustomTextField(
                        label: 'Máximo',
                        controller: _maxController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Requerido';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
