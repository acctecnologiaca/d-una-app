import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../domain/models/quote_model.dart';
// For TitleCase if needed
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/standard_list_item.dart';

class QuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const QuoteCard({
    super.key,
    required this.quote,
    this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Formatters
    final dateFormat = DateFormat('dd/MM/yyyy');

    // Definimos si el estatus permite alertas visuales (evitamos estados finales)
    final canShowAlert =
        quote.status != QuoteStatus.rejected &&
        quote.status != QuoteStatus.finalized &&
        quote.status != QuoteStatus.cancelled &&
        quote.status != QuoteStatus.expired;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primaryContainer.withValues(alpha: 0.3)
            : (canShowAlert &&
                      (quote.stockStatus != StockStatus.available ||
                          quote.hasPriceIncrease)
                  ? colors.errorContainer.withValues(alpha: 0.8)
                  : null),
      ),
      child: StandardListItem(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        onTap: onTap,
        onLongPress: onLongPress,
        overline: Text(
          '${quote.quoteNumber} (${dateFormat.format(quote.date)})',
        ),
        title: quote.clientName,
        subtitle: quote.quoteTag != null
            ? Row(
                children: [
                  const Icon(Icons.label_outline, size: 16),
                  const SizedBox(width: 4),
                  Text(quote.quoteTag!),
                ],
              )
            : null,
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
                      if (quote.isArchived)
                        _buildStatusIcon(
                          'assets/icons/status_archived.png',
                          'Archivada',
                        )
                      else ...[
                        if (canShowAlert && quote.hasPriceIncrease)
                          _buildStatusIcon(
                            'assets/icons/price_increase.png',
                            'Aumento de costo',
                          ),
                        const SizedBox(width: 4),
                        if (canShowAlert &&
                            quote.stockStatus != StockStatus.available)
                          _buildStatusIcon(
                            quote.stockStatus.iconPath,
                            quote.stockStatus.label,
                          ),
                      ],
                      if (quote.clientFeedback != null &&
                          quote.clientFeedback!.trim().isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Tooltip(
                          message: 'Comentario: ${quote.clientFeedback}',
                          child: const Icon(
                            Icons.chat_bubble_outline,
                            size: 18,
                            color: Color(0xFFFFB964),
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      _buildStatusIcon(
                        quote.status.iconPath,
                        quote.status.label,
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
