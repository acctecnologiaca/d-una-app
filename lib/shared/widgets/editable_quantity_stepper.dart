import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EditableQuantityStepper extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String? label;

  const EditableQuantityStepper({
    super.key,
    required this.value,
    this.min = 0,
    this.max = double.infinity,
    required this.onChanged,
    this.label,
  });

  @override
  State<EditableQuantityStepper> createState() =>
      _EditableQuantityStepperState();
}

class _EditableQuantityStepperState extends State<EditableQuantityStepper> {
  late TextEditingController _controller;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: _formatValue(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void didUpdateWidget(EditableQuantityStepper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update the controller if the value changed externally AND we are not currently editing
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      _controller.text = _formatValue(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  String _formatValue(double value) {
    if (value == double.infinity || value >= 999999.0) return '∞';
    return value.truncateToDouble() == value
        ? value.toInt().toString()
        : value.toStringAsFixed(1);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      _submitValue();
    }
  }

  void _submitValue() {
    final text = _controller.text.replaceAll(',', '.');
    double? newValue = double.tryParse(text);

    if (newValue == null) {
      newValue = widget.value;
    } else {
      newValue = newValue.clamp(widget.min, widget.max);
    }

    _controller.text = _formatValue(newValue);
    widget.onChanged(newValue);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
        ],
        IconButton(
          onPressed: widget.value > widget.min
              ? () {
                  final newValue = (widget.value - 1).clamp(
                    widget.min,
                    widget.max,
                  );
                  widget.onChanged(newValue);
                  _controller.text = _formatValue(newValue);
                }
              : null,
          icon: const Icon(Icons.remove),
          iconSize: 20,
          visualDensity: VisualDensity.compact,
          color: colors.primary,
        ),
        IntrinsicWidth(
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 40),
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d*')),
              ],
              decoration: const InputDecoration(
                isCollapsed: true,
                isDense: true,
                border: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
              ),
              onSubmitted: (_) => _submitValue(),
              onTapOutside: (_) => _submitValue(),
            ),
          ),
        ),
        IconButton(
          onPressed: widget.value < widget.max
              ? () {
                  final newValue = (widget.value + 1).clamp(
                    widget.min,
                    widget.max,
                  );
                  widget.onChanged(newValue);
                  _controller.text = _formatValue(newValue);
                }
              : null,
          icon: const Icon(Icons.add),
          iconSize: 20,
          visualDensity: VisualDensity.compact,
          color: colors.primary,
        ),
      ],
    );
  }
}
