import 'package:flutter/material.dart';

/// Item data model for [LinkedDocumentCard].
class LinkedDocumentItem {
  final String id;
  final String title;
  final String? companyName;
  final String? subtitle;
  final String statusLabel;
  final String? statusIconPath;
  final IconData? statusIconData;
  final Color? statusColor;
  final bool isCancelled;
  final VoidCallback onTap;

  const LinkedDocumentItem({
    required this.id,
    required this.title,
    this.companyName,
    this.subtitle,
    required this.statusLabel,
    this.statusIconPath,
    this.statusIconData,
    this.statusColor,
    this.isCancelled = false,
    required this.onTap,
  });
}

/// Official card for linked / relational documents in Summary Tabs.
///
/// Follows the Master UX rule:
/// - In cross-relationships (Sale <-> Purchase / Client <-> Supplier), pass `companyName`
///   to display "$title ($companyName)".
/// - In homogeneous relationships (same Client or same Supplier), omit `companyName`
///   to display solely "$title".
class LinkedDocumentCard extends StatelessWidget {
  final List<LinkedDocumentItem> items;

  const LinkedDocumentCard({
    super.key,
    required this.items,
  });

  /// Factory constructor for a single linked document item.
  factory LinkedDocumentCard.single({
    Key? key,
    required String id,
    required String title,
    String? companyName,
    String? subtitle,
    required String statusLabel,
    String? statusIconPath,
    IconData? statusIconData,
    Color? statusColor,
    bool isCancelled = false,
    required VoidCallback onTap,
  }) {
    return LinkedDocumentCard(
      key: key,
      items: [
        LinkedDocumentItem(
          id: id,
          title: title,
          companyName: companyName,
          subtitle: subtitle,
          statusLabel: statusLabel,
          statusIconPath: statusIconPath,
          statusIconData: statusIconData,
          statusColor: statusColor,
          isCancelled: isCancelled,
          onTap: onTap,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.outlineVariant),
      ),
      color: colors.surface,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (context, index) => Divider(
          height: 1,
          color: colors.outlineVariant.withValues(alpha: 0.5),
        ),
        itemBuilder: (context, index) {
          final item = items[index];
          final hasCompany = item.companyName != null && item.companyName!.trim().isNotEmpty;
          final displayText = hasCompany
              ? '${item.title} (${item.companyName!.trim()})'
              : item.title;

          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            title: Text(
              displayText,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: item.isCancelled
                    ? colors.onSurfaceVariant.withValues(alpha: 0.7)
                    : colors.onSurface,
                decoration: item.isCancelled ? TextDecoration.lineThrough : null,
              ),
            ),
            subtitle: item.subtitle != null && item.subtitle!.isNotEmpty
                ? Text(
                    item.subtitle!,
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurfaceVariant,
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: item.statusLabel,
                  child: _buildStatusIcon(context, item, colors),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: colors.onSurfaceVariant,
                ),
              ],
            ),
            onTap: item.onTap,
          );
        },
      ),
    );
  }

  Widget _buildStatusIcon(
    BuildContext context,
    LinkedDocumentItem item,
    ColorScheme colors,
  ) {
    if (item.statusIconPath != null && item.statusIconPath!.isNotEmpty) {
      return Image.asset(
        item.statusIconPath!,
        width: 18,
        height: 18,
        errorBuilder: (context, error, stackTrace) {
          return Icon(
            item.statusIconData ?? Icons.help_outline,
            size: 18,
            color: item.statusColor ?? colors.onSurfaceVariant,
          );
        },
      );
    }

    if (item.statusIconData != null) {
      return Icon(
        item.statusIconData,
        size: 18,
        color: item.statusColor ?? colors.primary,
      );
    }

    return Icon(
      Icons.description_outlined,
      size: 18,
      color: colors.onSurfaceVariant,
    );
  }
}
