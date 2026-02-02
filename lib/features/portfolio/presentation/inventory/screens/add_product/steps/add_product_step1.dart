import 'package:flutter/material.dart';
import '../../../../../data/models/brand_model.dart';
import '../../../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../../../shared/widgets/custom_dropdown.dart';
import '../../../../../../../shared/widgets/wizard_bottom_bar.dart';
import '../../../../../../../shared/widgets/barcode_scanner_screen.dart';
import 'package:material_symbols_icons/symbols.dart';

class AddProductStep1 extends StatefulWidget {
  final TextEditingController modelController;
  final Brand? selectedBrand;
  final List<Brand> brands;
  final ValueChanged<Brand?> onBrandChanged;
  final Function(String) onAddBrand;
  final VoidCallback onNext;
  final VoidCallback onCancel;
  final FocusNode? focusNode;

  const AddProductStep1({
    super.key,
    required this.modelController,
    required this.selectedBrand,
    required this.brands,
    required this.onBrandChanged,
    required this.onAddBrand,
    required this.onNext,
    required this.onCancel,
    this.focusNode,
  });

  @override
  State<AddProductStep1> createState() => _AddProductStep1State();
}

class _AddProductStep1State extends State<AddProductStep1> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
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

                CustomDropdown<Brand>(
                  label: 'Marca',
                  value: widget.selectedBrand,
                  items: widget.brands,
                  onChanged: widget.onBrandChanged,
                  itemLabelBuilder: (item) => item.name,
                  showAddOption: true,
                  addOptionValue: const Brand(
                    id: 'new',
                    name: '___ADD___',
                  ), // Dummy
                  onAddPressed: () {
                    _showAddBrandDialog();
                  },
                  addOptionLabel: 'Agregar',
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: WizardButtonBar(
            onCancel: widget.onCancel,
            onNext: widget.selectedBrand != null ? widget.onNext : null,
          ),
        ),
      ],
    );
  }

  void _showAddBrandDialog() {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar nueva marca'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(
            labelText: 'Nombre de la marca',
            hintText: 'Ej. Samsung',
          ),
          textCapitalization: TextCapitalization.words,
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
                widget.onAddBrand(val);
                Navigator.pop(context);
              }
            },
            child: const Text('Agregar'),
          ),
        ],
      ),
    );
  }
}
