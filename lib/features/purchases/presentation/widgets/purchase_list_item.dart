import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../domain/models/purchase_model.dart';
import 'package:d_una_app/shared/utils/currency_formatter.dart';

class PurchaseListItem extends StatelessWidget {
  final Purchase purchase;
  final VoidCallback? onTap;

  const PurchaseListItem({super.key, required this.purchase, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Format Date: "05/10/2025"
    final dateFormatter = DateFormat('dd/MM/yyyy');
    final formattedDate = dateFormatter.format(purchase.date);

    final formattedAmount = CurrencyFormatter.format(purchase.subtotal);

    // Document Icon
    final docIcon = purchase.documentType == 'invoice'
        ? Icons.receipt_long
        : Icons.list_alt;

    // Background Color logic - red tint if missing serials
    final backgroundColor = purchase.hasMissingSerials
        ? colors.errorContainer.withValues(alpha: 0.8)
        : Colors.transparent;

    return Material(
      color: backgroundColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formattedDate,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      purchase.supplierName ?? 'Desconocido',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ).copyWith(color: colors.onSurface),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      purchase.documentNumber,
                      style: textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formattedAmount,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12), // Space between amount and icons
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (purchase.hasMissingSerials) ...[
                        Tooltip(
                          message: 'Faltan seriales por registrar',
                          child: Image.asset(
                            'assets/icons/no_barcode.png',
                            width: 20,
                            height: 20,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 4),
                      ],
                      Tooltip(
                        message: purchase.documentType == 'invoice'
                            ? 'Factura'
                            : 'Nota de Entrega',
                        child: Icon(
                          docIcon,
                          size: 20,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
