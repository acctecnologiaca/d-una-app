import 'package:flutter/material.dart';

class CustomDropdown<T extends Object> extends StatefulWidget {
  final T? value;
  final List<T> items;
  final String label;
  final ValueChanged<T?>? onChanged;
  final String Function(T) itemLabelBuilder;
  final bool showAddOption;
  final T? addOptionValue;
  final VoidCallback? onAddPressed;
  final String addOptionLabel;
  final String? Function(T?)? validator;

  final bool searchable;
  final bool enabled;

  const CustomDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.label,
    this.onChanged,
    required this.itemLabelBuilder,
    this.showAddOption = false,
    this.addOptionValue,
    this.onAddPressed,
    this.addOptionLabel = 'Agregar',
    this.validator,
    this.searchable = false,
    this.enabled = true,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T extends Object> extends State<CustomDropdown<T>> {
  // Used in searchable mode to keep the text field in sync when value changes externally.
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(
      text: widget.value != null
          ? widget.itemLabelBuilder(widget.value as T)
          : '',
    );
    _textController.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(covariant CustomDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchable && widget.value != oldWidget.value) {
      final newText = widget.value != null
          ? widget.itemLabelBuilder(widget.value as T)
          : '';
      // Only sync if the external value actually changed.
      if (_textController.text != newText) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _textController.text = newText;
          }
        });
      }
    }
  }

  void _onTextChanged() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {}); // Rebuild to toggle clear button visibility
      }
    });
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.searchable
        ? _buildSearchable(context)
        : _buildStandard(context);
  }

  // ── Standard (non-searchable) ────────────────────────────────────────────────

  Widget _buildStandard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dropdownItems = <DropdownMenuItem<T>>[];

    if (widget.showAddOption && widget.addOptionValue != null) {
      dropdownItems.add(
        DropdownMenuItem<T>(
          value: widget.addOptionValue as T,
          child: Row(
            children: [
              Icon(Icons.add, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                widget.addOptionLabel,
                style: TextStyle(
                  color: colors.primary,
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    dropdownItems.addAll(
      widget.items.map((item) {
        return DropdownMenuItem<T>(
          value: item,
          child: Text(
            widget.itemLabelBuilder(item),
            softWrap: true,
            overflow: TextOverflow.visible,
          ),
        );
      }),
    );

    return DropdownButtonFormField<T>(
      initialValue: widget.value,
      isExpanded: true,
      itemHeight: null,
      decoration: _decoration().copyWith(
        filled: !widget.enabled,
        fillColor: widget.enabled ? null : colors.surfaceContainerHighest,
      ),
      icon: const Icon(Icons.arrow_drop_down),
      selectedItemBuilder: (BuildContext context) {
        return dropdownItems.map<Widget>((DropdownMenuItem<T> item) {
          if (item.value == widget.addOptionValue) {
            return const SizedBox.shrink();
          }
          return Text(
            widget.itemLabelBuilder(item.value as T),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colors.onSurface),
          );
        }).toList();
      },
      items: dropdownItems,
      validator: widget.validator,
      onChanged: widget.enabled
          ? (T? newValue) {
              if (newValue == widget.addOptionValue && widget.showAddOption) {
                widget.onAddPressed?.call();
              } else {
                widget.onChanged?.call(newValue);
              }
            }
          : null,
    );
  }

  // ── Searchable (Autocomplete) ────────────────────────────────────────────────

  Widget _buildSearchable(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FormField<T>(
      initialValue: widget.value,
      validator: widget.validator,
      builder: (FormFieldState<T> state) {
        return LayoutBuilder(
          builder: (context, constraints) {
            return DropdownMenu<T>(
              width: constraints.maxWidth,
              initialSelection: widget.value,
              controller: _textController,
              label: Text('${widget.label}*'),
              enabled: widget.enabled && widget.onChanged != null,
              errorText: state.errorText,
              enableFilter: true,
              enableSearch:
                  false, // We use custom filter callback instead of native search string jump
              filterCallback:
                  (List<DropdownMenuEntry<T>> entries, String filter) {
                    final filtered = entries.where((entry) {
                      // Always show the Add option
                      if (widget.showAddOption &&
                          entry.value == widget.addOptionValue) {
                        return true;
                      }
                      // Otherwise match text
                      return entry.label.toLowerCase().contains(
                        filter.toLowerCase(),
                      );
                    }).toList();
                    return filtered;
                  },
              requestFocusOnTap: true,
              textStyle: TextStyle(
                fontWeight: FontWeight.w500,
                color: colors.onSurface,
              ),
              menuHeight: 240,
              expandedInsets: EdgeInsets.zero,
              menuStyle: MenuStyle(
                backgroundColor: WidgetStatePropertyAll(colors.surface),
                elevation: const WidgetStatePropertyAll(4),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              dropdownMenuEntries: [
                if (widget.showAddOption && widget.addOptionValue != null)
                  DropdownMenuEntry<T>(
                    value: widget.addOptionValue as T,
                    label: widget.addOptionLabel,
                    labelWidget: Row(
                      children: [
                        Icon(Icons.add, color: colors.onSurface),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.addOptionLabel,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colors.primary,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ...widget.items.map((item) {
                  return DropdownMenuEntry<T>(
                    value: item,
                    label: widget.itemLabelBuilder(item),
                    labelWidget: Text(
                      widget.itemLabelBuilder(item),
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }),
              ],
              onSelected: (T? selection) {
                if (selection == widget.addOptionValue &&
                    widget.showAddOption) {
                  // Restore old text to avoid showing the 'Add' placeholder text
                  _textController.text = widget.value != null
                      ? widget.itemLabelBuilder(widget.value as T)
                      : '';
                  widget.onAddPressed?.call();
                } else {
                  state.didChange(selection);
                  widget.onChanged?.call(selection);
                }
              },
              trailingIcon: _buildSearchableTrailingIcons(state),
              selectedTrailingIcon: _buildSearchableTrailingIcons(
                state,
                isSelected: true,
              ),
              inputDecorationTheme: InputDecorationTheme(
                isDense: true,
                constraints: const BoxConstraints(minHeight: 56, maxHeight: 56),
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
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchableTrailingIcons(
    FormFieldState<T> state, {
    bool isSelected = false,
  }) {
    final arrowIcon = Icon(
      isSelected ? Icons.arrow_drop_up : Icons.arrow_drop_down,
    );

    // If no text is typed/selected, just show the arrow
    if (_textController.text.isEmpty) {
      return arrowIcon;
    }

    // If there is text, show a Clear button + Arrow
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Clear the text UI
            _textController.clear();
            // Clear the form field state
            state.didChange(null);
            // Notify external listeners
            widget.onChanged?.call(null);
            // Rebuild so the "X" disappears
            setState(() {});
          },
          child: const Padding(
            padding: EdgeInsets.all(4.0),
            child: Icon(Icons.cancel_outlined, size: 20),
          ),
        ),
        const SizedBox(width: 4),
        arrowIcon,
      ],
    );
  }

  InputDecoration _decoration() {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: '${widget.label}*',
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade400),
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      filled: !widget.enabled,
      fillColor: widget.enabled
          ? Colors.transparent
          : colors.surfaceContainerHighest,
    );
  }
}
