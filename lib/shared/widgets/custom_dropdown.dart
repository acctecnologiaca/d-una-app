import 'package:flutter/material.dart';

class CustomDropdown<T> extends StatelessWidget {
  final T? value;
  final List<T> items;
  final String label;
  final ValueChanged<T?> onChanged;
  final String Function(T) itemLabelBuilder;
  final bool showAddOption;
  final T? addOptionValue;
  final VoidCallback? onAddPressed;
  final String addOptionLabel;

  final String? Function(T?)? validator;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.label,
    required this.onChanged,
    required this.itemLabelBuilder,
    this.showAddOption = false,
    this.onAddPressed,
    this.addOptionLabel = 'Agregar',
    this.addOptionValue,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true, // Matches CustomStringDropdown
      itemHeight: null,
      decoration: InputDecoration(
        labelText: '$label*',
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        filled: true,
        fillColor: colors.surface,
      ),
      icon: const Icon(Icons.arrow_drop_down),
      selectedItemBuilder: (BuildContext context) {
        final List<Widget> selectedItems = [];

        if (showAddOption && addOptionValue != null) {
          // Add dummy widget for the Add option (which now includes divider)
          selectedItems.add(const SizedBox());
        }

        selectedItems.addAll(
          items.map<Widget>((T item) {
            return Text(
              itemLabelBuilder(item),
              overflow: TextOverflow.ellipsis, // Keep single line in input
              style: TextStyle(color: colors.onSurface),
            );
          }),
        );

        return selectedItems;
      },
      items: [
        if (showAddOption && addOptionValue != null) ...[
          DropdownMenuItem<T>(
            value: addOptionValue,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.add, color: colors.onSurface),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        addOptionLabel,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                //const Divider(),
              ],
            ),
          ),
        ],
        ...items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              itemLabelBuilder(item),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          );
        }),
      ],
      validator: validator,
      onChanged: (val) {
        if (showAddOption && val == addOptionValue) {
          onAddPressed?.call();
        } else {
          onChanged(val);
        }
      },
    );
  }
}
