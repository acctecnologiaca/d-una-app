import 'package:flutter/material.dart';
import '../../../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../../../shared/widgets/wizard_bottom_bar.dart';
import '../../../../../data/models/service_rate_model.dart';

class AddServiceStep2 extends StatefulWidget {
  final TextEditingController priceController;
  final bool isPriceFixed;
  final ValueChanged<bool> onPriceTypeChanged;
  final ServiceRate? selectedRateUnit;
  final List<ServiceRate> rateUnits;
  final ValueChanged<ServiceRate?> onRateUnitChanged;
  final VoidCallback onAddRateUnit;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onCancel;

  const AddServiceStep2({
    super.key,
    required this.priceController,
    required this.isPriceFixed,
    required this.onPriceTypeChanged,
    required this.selectedRateUnit,
    required this.rateUnits,
    required this.onRateUnitChanged,
    required this.onAddRateUnit,
    required this.onNext,
    required this.onBack,
    required this.onCancel,
  });

  @override
  State<AddServiceStep2> createState() => _AddServiceStep2State();
}

class _AddServiceStep2State extends State<AddServiceStep2> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title
                  Text(
                    '¿Cuánto y cómo vas a cobrar?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 24,
                      color: colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Price Type Section
                  Text(
                    '¿Cómo es el precio?',
                    style: TextStyle(fontSize: 16, color: colors.onSurface),
                  ),
                  const SizedBox(height: 12),

                  // Toggle Buttons (Styled like Add Client Wizard)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _buildToggleButton(
                          label: 'Fijo',
                          isSelected: widget.isPriceFixed,
                          onTap: () => widget.onPriceTypeChanged(true),
                          isLeft: true,
                        ),
                      ),
                      Expanded(
                        child: _buildToggleButton(
                          label: 'Variable',
                          isSelected: !widget.isPriceFixed,
                          onTap: () => widget.onPriceTypeChanged(false),
                          isLeft: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Price Input (Conditional)
                  if (widget.isPriceFixed) ...[
                    Text(
                      '¿Cuánto cobrarás por este servicio?',
                      style: TextStyle(fontSize: 16, color: colors.onSurface),
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      label: 'Precio*',
                      hintText: '0.00',
                      controller: widget.priceController,
                      prefixText: '\$ ',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (val) {
                        if (!widget.isPriceFixed) return null;
                        if (val == null || val.trim().isEmpty) {
                          return 'Requerido';
                        }
                        if (double.tryParse(val) == null) return 'Inválido';
                        return null;
                      },
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

                  // Rate Type Input
                  Text(
                    '¿Qué tipo de tarifa deseas aplicarle?',
                    style: TextStyle(fontSize: 16, color: colors.onSurface),
                  ),
                  const SizedBox(height: 12),
                  CustomDropdown<ServiceRate>(
                    label: 'Tarifa por',
                    value: widget.selectedRateUnit,
                    items: widget.rateUnits,
                    onChanged: widget.onRateUnitChanged,
                    itemLabelBuilder: (item) =>
                        '${item.name} (${item.symbol})',
                    validator: (val) => val == null ? 'Requerido' : null,
                    showAddOption: true,
                    addOptionLabel: 'Agregar',
                    addOptionValue: const ServiceRate(
                      id: '__add_new__',
                      name: 'Agregar',
                      symbol: '+',
                    ),
                    onAddPressed: widget.onAddRateUnit,
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: WizardButtonBar(
            onCancel: widget.onCancel,
            onBack: widget.onBack,
            onNext: () {
              if (_formKey.currentState!.validate()) {
                widget.onNext();
              }
            },
            labelNext: 'Siguiente',
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isLeft,
  }) {
    final colors = Theme.of(context).colorScheme;
    final backgroundColor = isSelected
        ? colors.secondaryContainer
        : Colors.transparent;
    final textColor = isSelected
        ? colors.onSecondaryContainer
        : colors.onSurface;
    final borderColor = colors.outline.withValues(alpha: 0.5);

    return InkWell(
      onTap: onTap,
      borderRadius: isLeft
          ? const BorderRadius.horizontal(left: Radius.circular(30))
          : const BorderRadius.horizontal(right: Radius.circular(30)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: isLeft
              ? const BorderRadius.horizontal(left: Radius.circular(30))
              : const BorderRadius.horizontal(right: Radius.circular(30)),
          border: Border.all(
            color: isSelected ? colors.secondaryContainer : borderColor,
          ),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Icon(Icons.check, size: 18, color: textColor),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
