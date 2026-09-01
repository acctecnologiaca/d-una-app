import 'package:flutter/material.dart';
import '../../../domain/models/service_report_model.dart';

class InterventionTypeChips extends StatelessWidget {
  final InterventionType selectedType;
  final ValueChanged<InterventionType> onSelected;
  final EdgeInsetsGeometry? padding;

  const InterventionTypeChips({
    super.key,
    required this.selectedType,
    required this.onSelected,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
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
                    color: isSelected
                        ? colors.onSecondaryContainer
                        : colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 6),
                  Text(type.label),
                ],
              ),
              selected: isSelected,
              onSelected: (_) => onSelected(type),
              selectedColor: colors.secondaryContainer,
              labelStyle: TextStyle(
                color: isSelected
                    ? colors.onSecondaryContainer
                    : colors.onSurface,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              backgroundColor: colors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: isSelected
                    ? const BorderSide(color: Colors.transparent)
                    : BorderSide(
                        color: colors.outline.withValues(alpha: 0.3),
                      ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }
}
