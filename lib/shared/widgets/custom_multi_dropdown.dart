import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import 'custom_extended_fab.dart';

class CustomMultiDropdown<T extends Object> extends StatefulWidget {
  final List<T> selectedValues;
  final List<T> items;
  final String label;
  final String? hintText;
  final ValueChanged<List<T>>? onChanged;
  final String Function(T) itemLabelBuilder;
  final String Function(T)? itemSubtitleBuilder;
  final String? Function(List<T>?)? validator;
  final bool enabled;
  final bool isRequired;
  final int? maxSelections;
  final VoidCallback? onAddOption;
  final String? addOptionLabel;

  const CustomMultiDropdown({
    super.key,
    required this.selectedValues,
    required this.items,
    required this.label,
    this.hintText,
    this.onChanged,
    required this.itemLabelBuilder,
    this.itemSubtitleBuilder,
    this.validator,
    this.enabled = true,
    this.isRequired = true,
    this.maxSelections,
    this.onAddOption,
    this.addOptionLabel,
  });

  @override
  State<CustomMultiDropdown<T>> createState() => _CustomMultiDropdownState<T>();
}

class _CustomMultiDropdownState<T extends Object>
    extends State<CustomMultiDropdown<T>> {
  String get _effectiveLabel {
    if (!widget.isRequired) {
      return widget.label.endsWith('*')
          ? widget.label.substring(0, widget.label.length - 1).trim()
          : widget.label;
    }
    return widget.label.endsWith('*') ? widget.label : '${widget.label}*';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return FormField<List<T>>(
      key: ValueKey(
        '${widget.selectedValues.length}_${widget.selectedValues.hashCode}_${widget.enabled}',
      ),
      initialValue: widget.selectedValues,
      validator: widget.validator,
      builder: (FormFieldState<List<T>> state) {
        final hasValues = widget.selectedValues.isNotEmpty;

        String displayText = '';
        if (hasValues) {
          if (widget.selectedValues.length == 1) {
            displayText = widget.itemLabelBuilder(widget.selectedValues.first);
          } else if (widget.selectedValues.length == 2) {
            displayText =
                '${widget.itemLabelBuilder(widget.selectedValues[0])}, ${widget.itemLabelBuilder(widget.selectedValues[1])}';
          } else {
            displayText =
                '${widget.itemLabelBuilder(widget.selectedValues[0])}, ${widget.itemLabelBuilder(widget.selectedValues[1])} (+${widget.selectedValues.length - 2})';
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: widget.enabled
                  ? () async {
                      final selected =
                          await SearchableMultiSelectionSheet.show<T>(
                        context: context,
                        title: widget.label,
                        items: widget.items,
                        initialSelectedValues: widget.selectedValues,
                        itemLabelBuilder: widget.itemLabelBuilder,
                        itemSubtitleBuilder: widget.itemSubtitleBuilder,
                        maxSelections: widget.maxSelections,
                        onAddOption: widget.onAddOption,
                        addOptionLabel: widget.addOptionLabel,
                      );

                      if (selected != null) {
                        state.didChange(selected);
                        widget.onChanged?.call(selected);
                      }
                    }
                  : null,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: _effectiveLabel,
                  errorText: state.errorText,
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey.shade400),
                  ),
                  disabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  filled: !widget.enabled,
                  fillColor: widget.enabled
                      ? Colors.transparent
                      : colors.surfaceContainerHighest,
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (hasValues && widget.enabled)
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined, size: 20),
                          splashRadius: 16,
                          onPressed: () {
                            state.didChange([]);
                            widget.onChanged?.call([]);
                          },
                        ),
                      const Icon(Icons.arrow_drop_down),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                isEmpty: !hasValues,
                child: Text(
                  displayText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: widget.enabled
                        ? colors.onSurface
                        : colors.onSurface.withValues(alpha: 0.38),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class SearchableMultiSelectionSheet<T extends Object> extends StatefulWidget {
  final String title;
  final List<T> items;
  final List<T> initialSelectedValues;
  final String Function(T) itemLabelBuilder;
  final String Function(T)? itemSubtitleBuilder;
  final int? maxSelections;
  final VoidCallback? onAddOption;
  final String? addOptionLabel;

  const SearchableMultiSelectionSheet._({
    required this.title,
    required this.items,
    required this.initialSelectedValues,
    required this.itemLabelBuilder,
    this.itemSubtitleBuilder,
    this.maxSelections,
    this.onAddOption,
    this.addOptionLabel,
  });

  static Future<List<T>?> show<T extends Object>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required List<T> initialSelectedValues,
    required String Function(T) itemLabelBuilder,
    String Function(T)? itemSubtitleBuilder,
    int? maxSelections,
    VoidCallback? onAddOption,
    String? addOptionLabel,
  }) {
    return showModalBottomSheet<List<T>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SearchableMultiSelectionSheet<T>._(
        title: title,
        items: items,
        initialSelectedValues: initialSelectedValues,
        itemLabelBuilder: itemLabelBuilder,
        itemSubtitleBuilder: itemSubtitleBuilder,
        maxSelections: maxSelections,
        onAddOption: onAddOption,
        addOptionLabel: addOptionLabel,
      ),
    );
  }

  @override
  State<SearchableMultiSelectionSheet<T>> createState() =>
      _SearchableMultiSelectionSheetState<T>();
}

class _SearchableMultiSelectionSheetState<T extends Object>
    extends State<SearchableMultiSelectionSheet<T>> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late Set<T> _selectedSet;

  @override
  void initState() {
    super.initState();
    _selectedSet = Set<T>.from(widget.initialSelectedValues);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final filteredItems = widget.items.where((item) {
      if (_searchQuery.isEmpty) return true;
      final label = widget.itemLabelBuilder(item).toLowerCase();
      final subtitle =
          widget.itemSubtitleBuilder?.call(item).toLowerCase() ?? '';
      return label.contains(_searchQuery.toLowerCase()) ||
          subtitle.contains(_searchQuery.toLowerCase());
    }).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Stack(
          children: [
            Column(
              children: [
                // Handle bar (Matching FilterBottomSheet)
                _buildHandle(),

                // Header (Matching FilterBottomSheet)
                _buildHeader(context),

                // Search Bar (Matching FilterBottomSheet)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar ${widget.title}...',
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.outline),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                if (widget.onAddOption != null)
                  InkWell(
                    onTap: widget.onAddOption,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add,
                            color: colors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.addOptionLabel ?? 'Agregar opción',
                            style: TextStyle(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Options List with CheckboxListTile and trailing affinity
                Expanded(
                  child: filteredItems.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Text(
                              _searchQuery.isNotEmpty
                                  ? 'No se encontraron resultados para "$_searchQuery"'
                                  : 'No hay opciones disponibles',
                              style: TextStyle(color: colors.onSurfaceVariant),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: filteredItems.length,
                          itemBuilder: (context, index) {
                            final item = filteredItems[index];
                            final isSelected = _selectedSet.contains(item);
                            final label = widget.itemLabelBuilder(item);
                            final subtitle =
                                widget.itemSubtitleBuilder?.call(item);
                            final initial = label.isNotEmpty
                                ? label[0].toUpperCase()
                                : '?';

                            return CheckboxListTile(
                              value: isSelected,
                              activeColor: colors.primary,
                              controlAffinity:
                                  ListTileControlAffinity.trailing,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              secondary: CircleAvatar(
                                backgroundColor: isSelected
                                    ? colors.primaryContainer
                                    : colors.secondaryContainer,
                                child: Text(
                                  initial,
                                  style: TextStyle(
                                    color: isSelected
                                        ? colors.onPrimaryContainer
                                        : colors.onSecondaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                label,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w400,
                                  color: colors.onSurface,
                                ),
                              ),
                              subtitle: subtitle != null && subtitle.isNotEmpty
                                  ? Text(
                                      subtitle,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: colors.onSurfaceVariant,
                                      ),
                                    )
                                  : null,
                              onChanged: (bool? checked) {
                                if (checked == true) {
                                  if (widget.maxSelections != null &&
                                      _selectedSet.length >=
                                          widget.maxSelections!) {
                                    AppToast.warning(
                                      context,
                                      message:
                                          'Máximo ${widget.maxSelections} seleccionados',
                                    );
                                    return;
                                  }
                                  setState(() {
                                    _selectedSet.add(item);
                                  });
                                } else {
                                  setState(() {
                                    _selectedSet.remove(item);
                                  });
                                }
                              },
                            );
                          },
                        ),
                ),
                const SizedBox(height: 80),
              ],
            ),

            // Floating Bottom Action Button (CustomExtendedFab matching FilterBottomSheet)
            Positioned(
              bottom: 40,
              right: 16,
              child: CustomExtendedFab(
                onPressed: () {
                  Navigator.pop(context, _selectedSet.toList());
                },
                label: 'Aplicar (${_selectedSet.length})',
                icon: Icons.check,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHandle() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 16),
        height: 4,
        width: 32,
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.title,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
