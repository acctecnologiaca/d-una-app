import 'dart:math' as math;
import 'package:d_una_app/features/portfolio/data/models/product_model.dart';
import 'package:d_una_app/features/quotes/data/models/quote.dart';
import 'package:d_una_app/features/quotes/data/models/quote_item_product.dart';

class DeliveryNoteStockUtils {
  /// Calcula el stock disponible contextualizado para un producto en una Nota de Entrega.
  ///
  /// - Para NE desde cero:
  ///   `FreeStock = max(0, product.inventoryQuantity - product.reservedQuantity)`.
  ///   Disponible = `FreeStock + currentItemQuantityInThisNote`.
  ///
  /// - Para NE vinculada a una cotización aprobada:
  ///   El stock disponible incluye las unidades reservadas exclusivamente por esa
  ///   cotización (`quoteOwnQty - alreadyFinalizedInOtherNotesForQuote`) más cualquier
  ///   `FreeStock` disponible en almacén para despachos adicionales.
  static double calculateAvailableStock({
    required Product product,
    String? quoteId,
    Quote? linkedQuote,
    double currentItemQuantityInThisNote = 0.0,
    double alreadyFinalizedInOtherNotesForQuote = 0.0,
  }) {
    // 1. Stock libre en inventario general (sin reservas de nadie)
    final double freeStock =
        math.max(0.0, product.inventoryQuantity - product.reservedQuantity);

    // 2. Si la nota está vinculada a una cotización
    final bool hasLinkedQuote = quoteId != null && quoteId.isNotEmpty;
    final bool isApprovedQuote = hasLinkedQuote &&
        (linkedQuote == null || linkedQuote.status.toLowerCase() == 'approved');

    if (hasLinkedQuote && isApprovedQuote) {
      if (linkedQuote != null) {
        // Buscar productos en la cotización por id o por nombre
        final matchingQuoteProducts = linkedQuote.products?.where((p) {
          final matchesId = (p.productId != null &&
              product.id.isNotEmpty &&
              p.productId == product.id);
          final matchesName = p.name.trim().toLowerCase() ==
              product.name.trim().toLowerCase();
          return matchesId || matchesName;
        }).toList() ?? [];

        if (matchingQuoteProducts.isNotEmpty) {
          final double quoteTotalQty = matchingQuoteProducts.fold<double>(
            0.0,
            (sum, p) => sum + p.quantity,
          );

          final isOwn = matchingQuoteProducts
              .any((p) => p.sourceType == QuoteItemSourceType.own);

          final double quoteRemainingBalance = math.max(
            0.0,
            quoteTotalQty - alreadyFinalizedInOtherNotesForQuote,
          );

          // Si es propio, puede usar su reserva de cotización + stock libre de almacén
          if (isOwn) {
            return quoteRemainingBalance + freeStock;
          } else {
            // Si es afiliado/externo/temporal, su disponibilidad máxima a despachar es lo cotizado
            return quoteRemainingBalance;
          }
        }
      }

      // Si linkedQuote todavía no se ha cargado en memoria o es un ítem ya cargado de la cotización:
      if (currentItemQuantityInThisNote > 0) {
        return math.max(
          currentItemQuantityInThisNote,
          freeStock + currentItemQuantityInThisNote,
        );
      }

      return freeStock;
    }

    // 3. Nota desde cero (o cotización no aprobada / desvinculada):
    // Solo puede consumir stock libre. Si estamos editando el ítem dentro de la nota,
    // se reincorpora la cantidad que este mismo ítem ya tenía tomada.
    return freeStock + currentItemQuantityInThisNote;
  }
}
