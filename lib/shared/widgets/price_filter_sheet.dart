import 'package:flutter/material.dart';
import 'custom_button.dart';

class PriceFilterSheet extends StatefulWidget {
  final double? initialMin;
  final double? initialMax;
  final Function(double?, double?) onApply;

  const PriceFilterSheet({
    super.key,
    this.initialMin,
    this.initialMax,
    required this.onApply,
  });

  @override
  State<PriceFilterSheet> createState() => _PriceFilterSheetState();
}

class _PriceFilterSheetState extends State<PriceFilterSheet> {
  late TextEditingController _minController;
  late TextEditingController _maxController;

  @override
  void initState() {
    super.initState();
    _minController = TextEditingController(
      text: widget.initialMin?.toStringAsFixed(2) ?? '',
    );
    _maxController = TextEditingController(
      text: widget.initialMax?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine bottom padding for keyboard
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  height: 4,
                  width: 32,
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Text(
                        'Precio',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Inputs
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _minController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Mínimo',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        '-',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _maxController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Máximo',
                          prefixText: '\$ ',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Apply Button
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 24.0,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: 150,
                    child: CustomButton(
                      text: 'Aplicar',
                      isFullWidth: false,
                      onPressed: () {
                        final min = double.tryParse(
                          _minController.text.replaceAll(',', '.'),
                        );
                        final max = double.tryParse(
                          _maxController.text.replaceAll(',', '.'),
                        );
                        widget.onApply(min, max);
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
