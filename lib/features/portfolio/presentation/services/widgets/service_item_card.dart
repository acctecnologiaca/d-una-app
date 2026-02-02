import 'package:flutter/material.dart';

class ServiceItemCard extends StatelessWidget {
  final String name;
  final String? category;
  final double price;
  final String priceUnit;
  final VoidCallback onTap;

  const ServiceItemCard({
    super.key,
    required this.name,
    this.category,
    required this.price,
    required this.priceUnit,
    required this.onTap,
  });

  String _getSymbol(String unit) {
    final match = RegExp(r'\((.*?)\)').firstMatch(unit);
    return match?.group(1) ?? unit;
  }

  String _formatPriceDisplay() {
    final symbol = _getSymbol(priceUnit);
    if (price == 0) {
      return '??/$symbol';
    }
    return '${_formatPrice(price)}/$symbol';
  }

  String _formatPrice(double val) {
    // Simple formatting #,##0.00
    // Replace . with , for decimals
    return '\$${val.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Side: Name & Category
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (category != null && category!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      category!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Right Side: Price
            const SizedBox(width: 16),
            Text(
              _formatPriceDisplay(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600, // Slightly bolder for price
              ),
            ),
          ],
        ),
      ),
    );
  }
}
