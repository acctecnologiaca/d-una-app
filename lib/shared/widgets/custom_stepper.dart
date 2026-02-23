import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomStepper extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String prefixText;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  const CustomStepper({
    super.key,
    required this.controller,
    required this.label,
    this.prefixText = '',
    required this.onIncrement,
    required this.onDecrement,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: onDecrement,
          icon: const Icon(Icons.remove),
          color: colors.onSurface,
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: label,
              floatingLabelBehavior: FloatingLabelBehavior.always,
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade400),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              filled: true,
              fillColor: colors.surfaceContainerLow,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (prefixText.isNotEmpty) ...[
                  Text(
                    prefixText,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Expanded(
                  child: TextFormField(
                    controller: controller,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*[.,]?\d*'),
                      ),
                    ],
                    onChanged: onChanged,
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    validator: validator,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onIncrement,
          icon: const Icon(Icons.add),
          color: colors.onSurface,
        ),
      ],
    );
  }
}
