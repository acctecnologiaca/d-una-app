import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../domain/models/supplier_model.dart';
// import 'package:go_router/go_router.dart'; // Uncomment if navigation is needed inside the card or passed as callback

class SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final bool isLocked;
  final VoidCallback? onTap;

  const SupplierCard({
    super.key,
    required this.supplier,
    this.isLocked = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 180,
        foregroundDecoration: isLocked
            ? BoxDecoration(
                color: Colors.grey.withOpacity(0.7),
                borderRadius: BorderRadius.circular(16),
              )
            : null,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade400),
          image: supplier.bannerUrl != null
              ? DecorationImage(
                  image: CachedNetworkImageProvider(supplier.bannerUrl!),
                  fit: BoxFit.cover,
                  // Optional: apply grayscale filter to image itself if preferred
                  // colorFilter: isLocked ? ColorFilter.mode(Colors.grey, BlendMode.saturation) : null,
                )
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Center Content (Logo or Name) - Only if NO banner
            if (supplier.bannerUrl == null)
              Positioned.fill(
                child: Center(
                  child: supplier.logoUrl != null
                      ? CachedNetworkImage(
                          imageUrl: supplier.logoUrl!,
                          height: 120,
                          fit: BoxFit.contain,
                        )
                      : Text(
                          supplier.name,
                          style: const TextStyle(
                            color: Colors.black, // Dark text on white bg
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),

            // Trade Type Chip - Always visible (Top Right)
            if (supplier.tradeType != null)
              Positioned(
                top: 12,
                right: 12,
                child: _TradeTypeChip(tradeType: supplier.tradeType!),
              ),

            // Lock Icon - Center (if locked)
            if (isLocked)
              const Positioned.fill(
                child: Center(
                  child: Icon(
                    Icons.lock_outline,
                    color: Colors.white, // Visible against grey overlay
                    size: 48,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TradeTypeChip extends StatelessWidget {
  final String tradeType;

  const _TradeTypeChip({required this.tradeType});

  @override
  Widget build(BuildContext context) {
    String label;
    Color color;

    switch (tradeType) {
      case 'WHOLESALE':
        label = 'Mayorista';
        color = Colors.blue.shade900;
        break;
      case 'RETAIL':
        label = 'Minorista';
        color = Colors.green.shade800;
        break;
      case 'BOTH':
        label = 'Mayorista / Minorista';
        color = Colors.purple.shade900;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
