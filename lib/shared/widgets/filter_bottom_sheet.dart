import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'custom_extended_fab.dart';

class FilterOption {
  final String label;
  final String value;
  final IconData? icon;

  const FilterOption({required this.label, required this.value, this.icon});
}

class FilterBottomSheet extends StatefulWidget {
  final String title;
  final bool isMultiSelect;
  final List<FilterOption> options;
  final Set<String> selectedValues;
  final ValueChanged<Set<String>>? onApply;
  final ValueChanged<String>? onSelect;
  final Widget Function(String value)? leadingBuilder;
  final bool sortOptions;
  final bool showAllOption;
  final bool showLeading;
  final String applyButtonLabel;
  final VoidCallback? onAddOption;
  final String? addOptionLabel;

  const FilterBottomSheet._({
    required this.title,
    required this.isMultiSelect,
    required this.options,
    required this.selectedValues,
    this.onApply,
    this.onSelect,
    this.leadingBuilder,
    this.sortOptions = true,
    this.showAllOption = true,
    this.showLeading = true,
    this.applyButtonLabel = 'Aplicar',
    this.onAddOption,
    this.addOptionLabel,
  });

  static Future<void> showMulti<T>({
    required BuildContext context,
    required String title,
    required List<String> options,
    required Set<String> selectedValues,
    required ValueChanged<Set<String>> onApply,
    String Function(String)? labelBuilder,
    Widget Function(String value)? leadingBuilder,
    bool sortOptions = true,
    bool showAllOption = true,
    bool showLeading = true,
    String applyButtonLabel = 'Aplicar',
    VoidCallback? onAddOption,
    String? addOptionLabel,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FilterBottomSheet._(
        title: title,
        isMultiSelect: true,
        options: options.map((e) {
          final label = labelBuilder != null ? labelBuilder(e) : e;
          return FilterOption(label: label, value: e);
        }).toList(),
        selectedValues: selectedValues,
        onApply: onApply,
        leadingBuilder: leadingBuilder,
        sortOptions: sortOptions,
        showAllOption: showAllOption,
        showLeading: showLeading,
        applyButtonLabel: applyButtonLabel,
        onAddOption: onAddOption,
        addOptionLabel: addOptionLabel,
      ),
    );
  }

  static Future<void> showSingle<T>({
    required BuildContext context,
    required String title,
    required List<FilterOption> options,
    required String? selectedValue,
    required ValueChanged<String> onSelect,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => FilterBottomSheet._(
        title: title,
        isMultiSelect: false,
        options: options,
        selectedValues: selectedValue != null ? {selectedValue} : {},
        onSelect: onSelect,
      ),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late Set<String> _tempSelected;
  String _searchQuery = '';
  late List<FilterOption> _sortedOptions;

  @override
  void initState() {
    super.initState();
    _tempSelected = Set.from(widget.selectedValues);
    if (widget.sortOptions) {
      _sortedOptions = List.from(widget.options)
        ..sort((a, b) => a.label.compareTo(b.label));
    } else {
      _sortedOptions = List.from(widget.options);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isMultiSelect) {
      return _buildMultiSelect(context);
    } else {
      return _buildSingleSelect(context);
    }
  }

  Widget _buildSingleSelect(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHandle(),
          _buildHeader(context),
          const SizedBox(height: 8),
          ...widget.options.map((opt) {
            final isSelected = widget.selectedValues.contains(opt.value);
            return InkWell(
              onTap: () {
                widget.onSelect?.call(opt.value);
                context.pop();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24.0,
                  vertical: 16.0,
                ),
                child: Row(
                  children: [
                    if (opt.icon != null) ...[
                      Icon(opt.icon, color: colors.onSurfaceVariant, size: 24),
                      const SizedBox(width: 16),
                    ],
                    Text(
                      opt.label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w400,
                        color: colors.onSurface,
                      ),
                    ),
                    if (isSelected) ...[
                      const Spacer(),
                      Icon(Icons.check, color: colors.primary),
                    ],
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMultiSelect(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final filteredOptions = _sortedOptions
        .where(
          (opt) => opt.label.toLowerCase().contains(_searchQuery.toLowerCase()),
        )
        .toList();

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
                _buildHandle(),
                _buildHeader(context),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Buscar ${widget.title}...',
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
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
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
                      if (widget.showAllOption)
                        CheckboxListTile(
                          title: const Text('Todas'),
                          value: _tempSelected.isEmpty,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          secondary: Icon(
                            Icons.select_all,
                            color: colors.onSurfaceVariant,
                            size: 24,
                          ),
                          controlAffinity: ListTileControlAffinity.trailing,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _tempSelected.clear();
                              }
                            });
                          },
                        ),
                      ...filteredOptions.map((opt) {
                        final isSelected = _tempSelected.contains(opt.value);
                        return CheckboxListTile(
                          title: Text(opt.label),
                          value: isSelected,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 24,
                          ),
                          secondary: widget.showLeading
                              ? (widget.leadingBuilder != null
                                    ? widget.leadingBuilder!(opt.value)
                                    : CircleAvatar(
                                        backgroundColor:
                                            colors.secondaryContainer,
                                        child: Text(
                                          opt.label.isNotEmpty
                                              ? opt.label[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: colors.onSecondaryContainer,
                                          ),
                                        ),
                                      ))
                              : null,
                          controlAffinity: ListTileControlAffinity.trailing,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _tempSelected.add(opt.value);
                              } else {
                                _tempSelected.remove(opt.value);
                              }
                            });
                          },
                        );
                      }),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              bottom: 40,
              right: 16,
              child: CustomExtendedFab(
                onPressed: () {
                  widget.onApply?.call(_tempSelected);
                  context.pop();
                },
                label: widget.showAllOption
                    ? '${widget.applyButtonLabel} (${_tempSelected.isEmpty ? "Todas" : _tempSelected.length})'
                    : '${widget.applyButtonLabel}${_tempSelected.isNotEmpty ? " (${_tempSelected.length})" : ""}',
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
            onPressed: () => context.pop(),
          ),
          const SizedBox(width: 8),
          Text(
            widget.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
