import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/purchase_item_product.dart';
import '../../domain/models/models.dart';
import 'package:d_una_app/features/purchases/presentation/providers/purchases_providers.dart';

typedef PurchaseDetailsData = ({
  Purchase purchase,
  List<PurchaseItemProduct> items,
  List<ProductSerial> serials,
  String? supplierTaxId
});

final purchaseDetailsProvider = FutureProvider.family<PurchaseDetailsData, String>((ref, purchaseId) async {
  final repository = ref.read(purchasesRepositoryProvider);
  return repository.getPurchaseDetails(purchaseId);
});

extension PurchaseDetailsDataX on PurchaseDetailsData {
  bool get hasMissingSerials {
    for (var product in items) {
      if (product.requiresSerials) {
        final count =
            serials.where((s) => s.productId == product.productId).length;
        if (count < product.quantity) return true;
      }
    }
    return false;
  }
}
