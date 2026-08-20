import 'package:flutter/material.dart';
import '../../../../../core/utils/string_extensions.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../../shared/widgets/expandable_action_card.dart';
import '../../../../../shared/widgets/editable_quantity_stepper.dart';
import '../../../../../shared/widgets/uom_status_badge.dart';
import '../../../../portfolio/data/models/service_model.dart';

class QuoteServiceSelectionCard extends StatefulWidget {
  final ServiceModel service;
  final double selectedQty;
  final ValueChanged<double> onQtyChanged;
  final bool isLocked;
  final bool isAlreadyInQuote;

  const QuoteServiceSelectionCard({
    super.key,
    required this.service,
    required this.selectedQty,
    required this.onQtyChanged,
    this.isLocked = false,
    this.isAlreadyInQuote = false,
  });

  @override
  State<QuoteServiceSelectionCard> createState() =>
      _QuoteServiceSelectionCardState();
}

class _QuoteServiceSelectionCardState extends State<QuoteServiceSelectionCard> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final rateSymbol = widget.service.serviceRate?.symbol ?? 'ud.';
    final isInactive = widget.isAlreadyInQuote || widget.isLocked;
    final opacity = widget.isAlreadyInQuote
        ? 0.5
        : (widget.isLocked ? 0.38 : 1.0);

    final categoryName = widget.service.category?.name;

    return Opacity(
      opacity: opacity,
      child: IgnorePointer(
        ignoring: isInactive,
        child: ExpandableActionCard(
          isExpandable: true,
          isExpanded: widget.selectedQty > 0 ? true : null,
          padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 12.0),
          overline: categoryName != null && categoryName.isNotEmpty
              ? Text(
                  categoryName.toTitleCase,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : Text(
                  'Sin categoría',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
          title: widget.service.name,
          subtitle:
              (widget.service.description != null &&
                  widget.service.description!.isNotEmpty)
              ? Text(
                  widget.service.description!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                )
              : null,
          trailing: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                rateSymbol.isNotEmpty
                    ? '${CurrencyFormatter.format(widget.service.price)}/$rateSymbol'
                    : CurrencyFormatter.format(widget.service.price),
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              UomStatusBadge(
                quantity: widget.selectedQty > 0 ? widget.selectedQty : 1,
                uomAbbreviation: rateSymbol,
                uomIconName: widget.service.serviceRate?.iconName,
              ),
            ],
          ),
          actions: [
            if (widget.selectedQty > 0)
              TextButton.icon(
                onPressed: () => widget.onQtyChanged(0.0),
                icon: const Icon(Icons.close, size: 16),
                label: const Text('Limpiar', style: TextStyle(fontSize: 13)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                  foregroundColor: colors.error,
                ),
              ),
          ],
          expandedTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Cantidad:',
                style: TextStyle(
                  fontSize: 13,
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              EditableQuantityStepper(
                value: widget.selectedQty,
                min: 0,
                max: 99999,
                onChanged: widget.onQtyChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
