import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/service_report_model.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/standard_list_item.dart';

class ServiceReportCard extends StatelessWidget {
  final ServiceReportSummary report;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const ServiceReportCard({
    super.key,
    required this.report,
    this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primaryContainer.withValues(alpha: 0.3)
            : null,
      ),
      child: StandardListItem(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        onTap: onTap,
        onLongPress: onLongPress,
        overline: Text(
          '${report.reportNumber} (${dateFormat.format(report.date)})',
        ),
        title: report.clientName,
        subtitle: report.reportTag != null && report.reportTag!.trim().isNotEmpty
            ? Row(
                children: [
                  const Icon(Icons.label_outline, size: 16),
                  const SizedBox(width: 4),
                  Text(report.reportTag!),
                ],
              )
            : null,
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(report.amount),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            isSelectionMode
                ? Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap?.call(),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (report.isArchived)
                        _buildStatusIcon(
                          'assets/icons/status_archived.png',
                          'Archivado',
                        )
                      else
                        _buildStatusIcon(
                          report.status.iconPath,
                          report.status.label,
                        ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(String assetPath, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Image.asset(
        assetPath,
        width: 24,
        height: 24,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(Icons.help_outline, size: 24, color: Colors.grey);
        },
      ),
    );
  }
}
