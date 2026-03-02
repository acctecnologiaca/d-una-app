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

  /// When true, renders an Autocomplete field that lets the user type to filter.
  final bool searchable;

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
  }

  @override
  void didUpdateWidget(covariant CustomDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchable && widget.value != oldWidget.value) {
      final newText = widget.value != null
          ? widget.itemLabelBuilder(widget.value as T)
          : '';
      // Only sync if the external value actually changed.
      _textController.text = newText;
    }
  }

  @override
  void dispose() {
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

    return DropdownButtonFormField<T>(
      initialValue: widget.value,
      isExpanded: true,
      itemHeight: null,
      decoration: _decoration(),
      icon: const Icon(Icons.arrow_drop_down),
      selectedItemBuilder: (BuildContext context) {
        final List<Widget> selectedItems = [];
        if (widget.showAddOption && widget.addOptionValue != null) {
          selectedItems.add(const SizedBox());
        }
        selectedItems.addAll(
          widget.items.map<Widget>((T item) {
            return Text(
              widget.itemLabelBuilder(item),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colors.onSurface),
            );
          }),
        );
        return selectedItems;
      },
      items: [
        if (widget.showAddOption && widget.addOptionValue != null) ...[
          DropdownMenuItem<T>(
            value: widget.addOptionValue,
            child: Row(
              children: [
                Icon(Icons.add, color: colors.onSurface),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.addOptionLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ...widget.items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              widget.itemLabelBuilder(item),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          );
        }),
      ],
      validator: widget.validator,
      onChanged: widget.onChanged == null
          ? null
          : (val) {
              if (widget.showAddOption && val == widget.addOptionValue) {
                widget.onAddPressed?.call();
              } else {
                widget.onChanged?.call(val);
              }
            },
    );
  }

  // ── Searchable (Autocomplete) ────────────────────────────────────────────────

  Widget _buildSearchable(BuildContext context) {
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
              enabled: widget.onChanged != null,
              errorText: state.errorText,
              enableFilter: true,
              enableSearch: true,
              requestFocusOnTap: true,
              textStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
              menuHeight: 240,
              expandedInsets: EdgeInsets.zero,
              menuStyle: MenuStyle(
                backgroundColor: WidgetStatePropertyAll(
                  Theme.of(context).colorScheme.surface,
                ),
                elevation: const WidgetStatePropertyAll(4),
                shape: WidgetStatePropertyAll(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              dropdownMenuEntries: widget.items.map((item) {
                return DropdownMenuEntry<T>(
                  value: item,
                  label: widget.itemLabelBuilder(item),
                );
              }).toList(),
              onSelected: (T? selection) {
                state.didChange(selection);
                widget.onChanged?.call(selection);
              },
              trailingIcon: widget.showAddOption && widget.onAddPressed != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: widget.addOptionLabel,
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            // Delay ensures any internal focus overlays are fully cleared before navigation
                            Future.delayed(
                              const Duration(milliseconds: 100),
                              () {
                                widget.onAddPressed?.call();
                              },
                            );
                          },
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    )
                  : const Icon(Icons.arrow_drop_down),
              selectedTrailingIcon:
                  widget.showAddOption && widget.onAddPressed != null
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.add),
                          tooltip: widget.addOptionLabel,
                          onPressed: () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            Future.delayed(
                              const Duration(milliseconds: 100),
                              () {
                                widget.onAddPressed?.call();
                              },
                            );
                          },
                        ),
                        const Icon(Icons.arrow_drop_down),
                      ],
                    )
                  : const Icon(Icons.arrow_drop_up),
              inputDecorationTheme: InputDecorationTheme(
                isDense: true,
                constraints: const BoxConstraints(maxHeight: 56),
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
                filled: false,
                fillColor: Colors.transparent,
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _decoration({bool isSearchable = false}) {
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
      filled: false,
      fillColor: Colors.transparent,
      suffixIcon:
          isSearchable && widget.showAddOption && widget.onAddPressed != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  tooltip: widget.addOptionLabel,
                  onPressed: () {
                    FocusManager.instance.primaryFocus?.unfocus();
                    widget.onAddPressed?.call();
                  },
                ),
                const Icon(Icons.arrow_drop_down),
                const SizedBox(width: 8),
              ],
            )
          : const Icon(Icons.arrow_drop_down),
    );
  }
}
