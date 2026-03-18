import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomActionSheet extends StatelessWidget {
  final String title;
  final Widget? content; // Optional content below title (e.g. ServiceItemCard)
  final bool showDivider; // Optional flag to hide the divider below content
  final List<Widget> actions; // List of BottomSheetActionItems or other widgets
  final bool isContentScrollable;

  const CustomActionSheet({
    super.key,
    required this.title,
    this.content,
    this.showDivider = true,
    required this.actions,
    this.isContentScrollable = false,
  });

  static void show({
    required BuildContext context,
    required String title,
    Widget? content,
    bool showDivider = true,
    required List<Widget> actions,
    bool isContentScrollable = false,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => CustomActionSheet(
        title: title,
        content: content,
        showDivider: showDivider,
        actions: actions,
        isContentScrollable: isContentScrollable,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 16),
                height: 4,
                width: 32,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title Row
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 16.0, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Optional Content
            if (content != null) ...[
              if (isContentScrollable)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: content!,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: content!,
                ),
              if (showDivider) ...[
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
              ] else ...[
                const SizedBox(height: 16),
              ],
            ],

            // Actions
            ...actions,

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
