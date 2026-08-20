import 'package:flutter/material.dart';
import 'searchable_selection_sheet.dart';

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
  final String? helperText;
  final TextStyle? helperStyle;

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
    this.helperText,
    this.helperStyle,
    this.searchable = false,
    this.enabled = true,
  });

  @override
  State<CustomDropdown<T>> createState() => _CustomDropdownState<T>();
}

class _CustomDropdownState<T extends Object> extends State<CustomDropdown<T>> {
  int _resetCounter = 0;

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
      key: ValueKey(
        '${widget.value.hashCode}_${widget.items.length}_$_resetCounter',
      ),
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
                setState(() {
                  _resetCounter++;
                });
                widget.onAddPressed?.call();
              } else {
                widget.onChanged?.call(newValue);
              }
            }
          : null,
    );
  }

  // ── Searchable (Modal Bottom Sheet) ──────────────────────────────────────────

  Widget _buildSearchable(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return FormField<T>(
      key: ValueKey('${widget.value.hashCode}_${widget.enabled}'),
      initialValue: widget.value,
      validator: widget.validator,
      builder: (FormFieldState<T> state) {
        final hasValue = widget.value != null;
        final displayText =
            hasValue ? widget.itemLabelBuilder(widget.value as T) : '';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(8.0),
              onTap: widget.enabled
                  ? () async {
                      final selected =
                          await SearchableSelectionSheet.show<T>(
                        context: context,
                        title: widget.label,
                        items: widget.items,
                        selectedValue: widget.value,
                        itemLabelBuilder: widget.itemLabelBuilder,
                        showAddOption: widget.showAddOption,
                        addOptionLabel: widget.addOptionLabel,
                        onAddPressed: widget.onAddPressed,
                      );

                      if (selected != null) {
                        state.didChange(selected);
                        widget.onChanged?.call(selected);
                      }
                    }
                  : null,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: '${widget.label}*',
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
                      if (hasValue && widget.enabled)
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined, size: 20),
                          splashRadius: 16,
                          onPressed: () {
                            state.didChange(null);
                            widget.onChanged?.call(null);
                          },
                        ),
                      const Icon(Icons.arrow_drop_down),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                isEmpty: !hasValue,
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
            if (widget.helperText != null && state.errorText == null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, left: 12.0),
                child: Text(
                  widget.helperText!,
                  style: textTheme.bodySmall?.copyWith(
                    color: colors.onSurfaceVariant,
                  ).merge(widget.helperStyle),
                ),
              ),
          ],
        );
      },
    );
  }

  InputDecoration _decoration() {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
      labelText: '${widget.label}*',
      helperText: widget.helperText,
      helperStyle: widget.helperStyle,
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
