import 'package:flutter/material.dart';
import 'package:d_una_app/shared/widgets/standard_list_item.dart';

class ExpandableActionCard extends StatefulWidget {
  final Widget? overline;
  final String title;
  final Widget? subtitle;
  final Widget? trailing;
  final List<Widget> actions;
  final Widget? expandedTrailing;
  final EdgeInsetsGeometry padding;
  final bool isExpandable;
  final Color? backgroundColor;

  const ExpandableActionCard({
    super.key,
    this.overline,
    required this.title,
    this.subtitle,
    this.trailing,
    required this.actions,
    this.expandedTrailing,
    this.padding = const EdgeInsets.symmetric(horizontal: 0.0, vertical: 12.0),
    this.isExpandable = true,
    this.backgroundColor,
  });

  @override
  State<ExpandableActionCard> createState() => _ExpandableActionCardState();
}

class _ExpandableActionCardState extends State<ExpandableActionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      color: widget.backgroundColor ?? colors.surfaceContainerLowest,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        child: Column(
          children: [
            StandardListItem(
              padding: widget.padding,
              onTap: widget.isExpandable
                  ? () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    }
                  : null,
              overline: widget.overline,
              title: widget.title,
              subtitle: widget.subtitle,
              trailing: widget.trailing,
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: _isExpanded
                  ? Column(
                      children: [
                        const Divider(height: 1),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0.0,
                            vertical: 4.0,
                          ),
                          child: Row(
                            children: [
                              ...widget.actions,
                              if (widget.expandedTrailing != null) ...[
                                const Spacer(),
                                widget.expandedTrailing!,
                              ],
                            ],
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
