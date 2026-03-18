import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StandardAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final Widget? customTitle;
  final String? subtitle;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final Color? backgroundColor;
  final bool isSearchable;
  final Function(String)? onSearchChanged;
  final VoidCallback? onSearchClosed;

  const StandardAppBar({
    super.key,
    required this.title,
    this.customTitle,
    this.subtitle,
    this.actions,
    this.bottom,
    this.centerTitle = false,
    this.backgroundColor,
    this.isSearchable = false,
    this.onSearchChanged,
    this.onSearchClosed,
  });

  @override
  State<StandardAppBar> createState() => _StandardAppBarState();

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

class _StandardAppBarState extends State<StandardAppBar> {
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
    });
  }

  void _stopSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
    });
    if (widget.onSearchChanged != null) {
      widget.onSearchChanged!('');
    }
    if (widget.onSearchClosed != null) {
      widget.onSearchClosed!();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AppBar(
      backgroundColor: _isSearching
          ? colors.surfaceContainerHigh
          : (widget.backgroundColor ?? colors.surface),
      elevation: 0,
      centerTitle: widget.centerTitle,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: colors.onSurface),
        onPressed: () {
          if (_isSearching) {
            _stopSearch();
          } else {
            context.pop();
          }
        },
      ),
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Buscar...',
                border: InputBorder.none,
                fillColor: colors.surfaceContainerHigh,
              ),
              style: textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w400,
                fontSize: 16,
                color: colors.onSurface,
              ),
              onChanged: widget.onSearchChanged,
            )
          : Column(
              crossAxisAlignment: widget.centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                widget.customTitle ??
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: colors.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                if (widget.subtitle != null)
                  Text(
                    widget.subtitle!,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: colors.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
      actions: _isSearching
          ? [
              IconButton(
                icon: Icon(Icons.close, color: colors.onSurface),
                onPressed: _stopSearch,
              ),
            ]
          : [
              if (widget.isSearchable)
                IconButton(
                  icon: Icon(Icons.search, color: colors.onSurface),
                  onPressed: _startSearch,
                ),
              if (widget.actions != null) ...widget.actions!,
            ],
      bottom: widget.bottom,
    );
  }
}

// Removed size method, placed in StatefulWidget
