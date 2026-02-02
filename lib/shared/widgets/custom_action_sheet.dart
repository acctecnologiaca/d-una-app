import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CustomActionSheet extends StatelessWidget {
  final String title;
  final Widget? content; // Optional content below title (e.g. ServiceItemCard)
  final List<Widget> actions; // List of BottomSheetActionItems or other widgets

  const CustomActionSheet({
    super.key,
    required this.title,
    this.content,
    required this.actions,
  });

  static void show({
    required BuildContext context,
    required String title,
    Widget? content,
    required List<Widget> actions,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) =>
          CustomActionSheet(title: title, content: content, actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
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
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: content!,
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
          ],

          // Actions
          ...actions,

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
