import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final String? helperText;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int maxLines;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;
  final TextCapitalization textCapitalization;
  final bool enabled;
  final int? minLines;
  final FocusNode? focusNode;

  const CustomTextField({
    super.key,
    required this.label,
    this.hintText,
    this.helperText,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.maxLines = 1,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
    this.textCapitalization = TextCapitalization.none,
    this.enabled = true,
    this.minLines,
    this.focusNode,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late TextEditingController _controller;
  bool _showClearButton = false;

  @override
  void initState() {
    super.initState();
    // Use provided controller or create a local one if none provided
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_updateClearButtonVisibility);
    // Initial check
    _updateClearButtonVisibility();
  }

  @override
  void didUpdateWidget(covariant CustomTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_updateClearButtonVisibility);
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_updateClearButtonVisibility);
      _updateClearButtonVisibility();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_updateClearButtonVisibility);
    // If we created a local controller, we should dispose it.
    // But typically parents provide it. If we created it here (widget.controller == null), we dispose it.
    if (widget.controller == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _updateClearButtonVisibility() {
    final shouldShow =
        _controller.text.isNotEmpty && !widget.readOnly && widget.enabled;
    if (mounted && _showClearButton != shouldShow) {
      setState(() {
        _showClearButton = shouldShow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine suffix icon: User provided > Clear Button > Null
    Widget? activeSuffixIcon = widget.suffixIcon;
    if (activeSuffixIcon == null && _showClearButton && !widget.obscureText) {
      activeSuffixIcon = IconButton(
        icon: const Icon(Icons.cancel_outlined, color: Colors.grey),
        onPressed: () {
          _controller.clear();
          widget.onChanged?.call('');
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _controller,
          focusNode: widget.focusNode,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          validator: widget.validator,
          onChanged: widget.onChanged,
          readOnly: widget.readOnly,
          enabled: widget.enabled,
          onTap: widget.onTap,
          textCapitalization: widget.textCapitalization,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hintText,
            helperText: widget.helperText,
            helperMaxLines: 2,
            suffixIcon: activeSuffixIcon,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            filled: true,
            fillColor: widget.enabled ? Colors.white : Colors.grey.shade200,
          ),
        ),
      ],
    );
  }
}
