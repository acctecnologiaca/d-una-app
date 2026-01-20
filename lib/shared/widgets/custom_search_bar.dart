import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onFilterTap;
  final FocusNode? focusNode;

  const CustomSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Buscar...',
    this.onChanged,
    this.onSubmitted,
    this.onFilterTap,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16.0, right: 8.0),
          child: Icon(Icons.search),
        ),
        suffixIcon: onFilterTap != null
            ? IconButton(
                icon: const Icon(Icons.filter_list),
                onPressed: onFilterTap,
                padding: const EdgeInsets.only(right: 16.0, left: 8.0),
              )
            : null,
        filled: true,
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
