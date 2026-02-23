import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum SortOption {
  frequency,
  recent,
  nameAZ,
  nameZA;

  String get label {
    switch (this) {
      case SortOption.frequency:
        return 'Frecuencia';
      case SortOption.recent:
        return 'Más reciente';
      case SortOption.nameAZ:
        return 'Nombre (A-Z)';
      case SortOption.nameZA:
        return 'Nombre (Z-A)';
    }
  }
}

class GenericSortSelector<T> extends StatelessWidget {
  final T currentSort;
  final List<T> options;
  final ValueChanged<T> onSortChanged;
  final String Function(T) labelBuilder;
  final IconData? Function(T)? iconBuilder;

  const GenericSortSelector({
    super.key,
    required this.currentSort,
    required this.options,
    required this.onSortChanged,
    required this.labelBuilder,
    this.iconBuilder,
  });

  void _showSortOptions(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: colors.surfaceContainer,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
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
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 16.0,
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => context.pop(),
                    ),
                    Expanded(
                      child: Text(
                        'Ordenar por',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              ...options.map(
                (option) => _buildSortOption(context, option, colors),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(BuildContext context, T option, ColorScheme colors) {
    final isSelected = currentSort == option;
    final icon = iconBuilder?.call(option);

    return InkWell(
      onTap: () {
        onSortChanged(option);
        context.pop();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: isSelected ? colors.primary : colors.onSurface,
                size: 20,
              ),
              const SizedBox(width: 16),
            ],
            Expanded(
              child: Text(
                labelBuilder(option),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w400,
                  color: isSelected ? colors.primary : colors.onSurface,
                ),
              ),
            ),
            if (isSelected) Icon(Icons.check, color: colors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _showSortOptions(context),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            labelBuilder(currentSort),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, size: 18, color: colors.onSurface),
        ],
      ),
    );
  }
}

class SortSelector extends StatelessWidget {
  final SortOption currentSort;
  final Function(SortOption) onSortChanged;

  const SortSelector({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GenericSortSelector<SortOption>(
      currentSort: currentSort,
      options: SortOption.values,
      onSortChanged: onSortChanged,
      labelBuilder: (option) => option.label,
      iconBuilder: (option) {
        if (option == SortOption.frequency) return Icons.trending_up;
        if (option == SortOption.recent) return Icons.arrow_downward;
        if (option == SortOption.nameAZ) return Icons.arrow_upward;
        return Icons.arrow_downward; // nameZA
      },
    );
  }
}
