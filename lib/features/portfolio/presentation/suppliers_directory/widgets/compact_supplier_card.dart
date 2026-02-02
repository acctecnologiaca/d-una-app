import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../domain/models/supplier_model.dart';
import 'supplier_card.dart'; // To reuse _TradeTypeChip logic if possible, or duplicate/move it

class CompactSupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback? onTap;

  const CompactSupplierCard({super.key, required this.supplier, this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Logo
            Container(
              width: 50,
              height: 50,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: supplier.logoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: supplier.logoUrl!,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.business,
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    )
                  : Icon(Icons.business, color: colors.onSurfaceVariant),
            ),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
                  ),
                  if (supplier.tradeType != null) ...[
                    const SizedBox(height: 4),
                    _CompactTradeTypeChip(tradeType: supplier.tradeType!),
                  ],
                ],
              ),
            ),
            // Chevron
            Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _CompactTradeTypeChip extends StatelessWidget {
  final String tradeType;

  const _CompactTradeTypeChip({required this.tradeType});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;
    Color bgColor;

    switch (tradeType) {
      case 'WHOLESALE':
        label = 'Mayorista';
        color = Colors.blue.shade900;
        bgColor = Colors.blue.shade50;
        break;
      case 'RETAIL':
        label = 'Minorista';
        color = Colors.green.shade800;
        bgColor = Colors.green.shade50;
        break;
      case 'BOTH':
        label = 'Mayorista / Minorista';
        color = Colors.purple.shade900;
        bgColor = Colors.purple.shade50;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
