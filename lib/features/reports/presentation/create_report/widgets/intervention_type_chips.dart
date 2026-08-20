import 'package:flutter/material.dart';
import '../../../domain/models/service_report_model.dart';

class InterventionTypeChips extends StatelessWidget {
  final InterventionType selectedType;
  final ValueChanged<InterventionType> onSelected;

  const InterventionTypeChips({
    super.key,
    required this.selectedType,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: InterventionType.values.map((type) {
          final isSelected = type == selectedType;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    type.icon,
                    size: 16,
                    color: isSelected ? colors.onPrimary : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(type.label),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(type),
              selectedColor: colors.primary,
              labelStyle: TextStyle(
                color: isSelected ? colors.onPrimary : colors.onSurface,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
              backgroundColor:
                  colors.surfaceContainerHighest.withValues(alpha: 0.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? colors.primary : colors.outlineVariant,
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}
