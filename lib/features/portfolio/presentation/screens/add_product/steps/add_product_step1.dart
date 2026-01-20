import 'package:flutter/material.dart';
import '../../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../../shared/widgets/wizard_bottom_bar.dart';
import '../../../../../../shared/widgets/barcode_scanner_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

class AddProductStep1 extends StatefulWidget {
  final TextEditingController modelController;
  final String? selectedBrand;
  final ValueChanged<String?> onBrandChanged;
  final VoidCallback onNext;
  final VoidCallback onCancel;
  final FocusNode? focusNode;

  const AddProductStep1({
    super.key,
    required this.modelController,
    required this.selectedBrand,
    required this.onBrandChanged,
    required this.onNext,
    required this.onCancel,
    this.focusNode,
  });

  @override
  State<AddProductStep1> createState() => _AddProductStep1State();
}

class _AddProductStep1State extends State<AddProductStep1> {
  final List<String> _brands = [
    'Hikvision',
    'Tp-Link',
    'Tubrica',
    'HiLook',
    'ZKTeco',
    'HP',
  ];

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight - 64, // Adjust for padding
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '¿Cuál es el modelo y la marca del producto?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w400,
                      fontSize: 24,
                      color: colors.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'En caso de que el producto no lo traiga marcado, deja el campo en blanco.',
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  CustomTextField(
                    label: 'Modelo/Nro. parte',
                    controller: widget.modelController,
                    focusNode: widget.focusNode,
                    suffixIcon: IconButton(
                      icon: const Icon(Symbols.barcode_scanner),
                      tooltip: 'Escanear código',
                      onPressed: () async {
                        final scannedCode = await Navigator.of(context)
                            .push<String>(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const BarcodeScannerScreen(),
                              ),
                            );
                        if (scannedCode != null) {
                          setState(() {
                            widget.modelController.text = scannedCode;
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Brand Label
                  Text(
                    '¿Qué marca tiene?',
                    style: TextStyle(fontSize: 16, color: colors.onSurface),
                  ),
                  const SizedBox(height: 16),

                  CustomDropdown<String>(
                    label: 'Marca',
                    value: widget.selectedBrand,
                    items: _brands,
                    onChanged: widget.onBrandChanged,
                    itemLabelBuilder: (item) => item,
                    showAddOption: true,
                    addOptionValue: '___ADD___', // Sentinel value
                    onAddPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Agregar nueva marca: Pendiente de implementación',
                          ),
                        ),
                      );
                    },
                    addOptionLabel: 'Agregar',
                  ),
                  const SizedBox(height: 32),
                  const Spacer(),

                  WizardButtonBar(
                    onCancel: widget.onCancel,
                    onNext: widget.selectedBrand != null ? widget.onNext : null,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
