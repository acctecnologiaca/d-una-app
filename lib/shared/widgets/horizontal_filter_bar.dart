import 'package:flutter/material.dart';

class FilterChipData {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const FilterChipData({
    required this.label,
    required this.isActive,
    required this.onTap,
  });
}

class HorizontalFilterBar extends StatelessWidget {
  final List<FilterChipData> filters;
  final VoidCallback? onResetFilters;
  final EdgeInsetsGeometry? padding;

  const HorizontalFilterBar({
    super.key,
    required this.filters,
    this.onResetFilters,
    this.padding,
  });

  /// Standardized label formatting:
  /// - Empty: defaultLabel
  /// - 1 selected: Value (or label from map)
  /// - >1 selected: FirstValue (or label) + " + (N-1)"
  static String formatLabel({
    required String defaultLabel,
    required List<String> selectedValues,
    Map<String, String>? valueToLabelMap,
  }) {
    if (selectedValues.isEmpty) return defaultLabel;

    final firstValue = selectedValues.first;
    final firstLabel = valueToLabelMap != null
        ? (valueToLabelMap[firstValue] ?? firstValue)
        : firstValue;

    if (selectedValues.length == 1) {
      return firstLabel;
    } else {
      return '$firstLabel + ${selectedValues.length - 1}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    if (filters.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding:
          padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children:
            filters.map((filter) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ActionChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (filter.isActive) ...[
                        Icon(
                          Icons.check,
                          size: 18,
                          color: colors.onSecondaryContainer,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        filter.label,
                        style: TextStyle(
                          color: filter.isActive
                              ? colors.onSecondaryContainer
                              : colors.onSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 20,
                        color: filter.isActive
                            ? colors.onSecondaryContainer
                            : colors.onSurface,
                      ),
                    ],
                  ),
                  backgroundColor: filter.isActive
                      ? colors.secondaryContainer
                      : colors.surface,
                  side: filter.isActive
                      ? const BorderSide(color: Colors.transparent)
                      : BorderSide(
                          color: colors.outline.withValues(alpha: 0.3),
                        ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  onPressed: filter.onTap,
                ),
              );
            }).toList()..addAll([
              if (filters.any((f) => f.isActive) && onResetFilters != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4.0),
                  child: TextButton(
                    onPressed: onResetFilters,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      minimumSize: const Size(0, 32),
                      visualDensity: VisualDensity.compact,
                    ),
                    child: Text(
                      "Borrar filtros",
                      style: TextStyle(
                        color: colors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
            ]),
      ),
    );
  }
}
