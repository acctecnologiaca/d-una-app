import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/quote_model.dart';
import '../../../../../core/utils/string_extensions.dart'; // For TitleCase if needed
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/standard_list_item.dart';

class QuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback? onTap;

  const QuoteCard({super.key, required this.quote, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Formatters
    final dateFormat = DateFormat('dd/MM/yyyy');

    return StandardListItem(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      onTap: onTap,
      overline: Text(dateFormat.format(quote.date)),
      title: quote.clientName,
      subtitle: Text(quote.quoteNumber),
      trailing: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            CurrencyFormatter.format(quote.amount),
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (quote.isArchived)
                _buildStatusIcon(
                  'assets/icons/status_archived.png',
                  'Archivada',
                )
              else
                _buildStatusIcon(
                  quote.stockStatus.iconPath,
                  quote.stockStatus.label,
                ),
              const SizedBox(width: 4),
              _buildStatusIcon(quote.status.iconPath, quote.status.label),
            ],
          ),
        ],
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
