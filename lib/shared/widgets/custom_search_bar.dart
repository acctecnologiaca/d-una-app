import 'package:flutter/material.dart';

class CustomSearchBar extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;
  final FocusNode? focusNode;
  final bool readOnly;
  final VoidCallback? onTap;
  final bool showFilterIcon;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.focusNode,
    this.readOnly = false,
    this.onTap,
    this.showFilterIcon = false,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  late TextEditingController _controller;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _controller.addListener(_updateClearButtonVisibility);
    _hasText = _controller.text.isNotEmpty;
  }

  @override
  void didUpdateWidget(CustomSearchBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      if (oldWidget.controller == null) {
        // Disposing internal controller if switching to external
        _controller.removeListener(_updateClearButtonVisibility);
        _controller.dispose();
      }
      _controller = widget.controller ?? TextEditingController();
      _controller.addListener(_updateClearButtonVisibility);
      _hasText = _controller.text.isNotEmpty;
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      // Only dispose if we created it
      _controller.dispose();
    } else {
      _controller.removeListener(_updateClearButtonVisibility);
    }
    super.dispose();
  }

  void _updateClearButtonVisibility() {
    final hasText = _controller.text.isNotEmpty;
    if (_hasText != hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Determine Suffix Icon
    Widget? suffixIcon;

    if (!widget.readOnly && _hasText) {
      // Show Clear Button
      suffixIcon = IconButton(
        icon: const Icon(Icons.cancel_outlined),
        onPressed: () {
          _controller.clear();
          widget.onChanged?.call('');
          // Also trigger onSubmitted with empty if needed? usually not on clear.
        },
        padding: const EdgeInsets.only(right: 16.0, left: 8.0),
      );
    } else if (widget.onFilterTap != null || widget.showFilterIcon) {
      // Show Filter Icon
      if (widget.onFilterTap != null) {
        suffixIcon = IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: widget.onFilterTap,
          padding: const EdgeInsets.only(right: 16.0, left: 8.0),
        );
      } else {
        suffixIcon = const Padding(
          padding: EdgeInsets.only(right: 16.0, left: 8.0),
          child: Icon(Icons.filter_list),
        );
      }
    }

    return TextField(
      controller: _controller,
      focusNode: widget.focusNode,
      readOnly: widget.readOnly,
      onTap: widget.onTap,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      decoration: InputDecoration(
        hintText: widget.hintText,
        prefixIcon: widget.readOnly
            ? const Padding(
                padding: EdgeInsets.only(left: 16.0, right: 8.0),
                child: Icon(Icons.search),
              )
            : null,
        suffixIcon: suffixIcon,
        filled: widget.readOnly,
        fillColor: colors.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      ),
    );
  }
}
