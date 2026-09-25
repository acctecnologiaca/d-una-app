import '../models/supplier_order.dart';
import '../models/supplier_order_status.dart';

class SupplierOrderMergeValidationResult {
  final bool isValid;
  final String? errorMessage;
  final bool hasBranchConflict;
  final bool hasPaymentMethodConflict;

  const SupplierOrderMergeValidationResult({
    required this.isValid,
    this.errorMessage,
    this.hasBranchConflict = false,
    this.hasPaymentMethodConflict = false,
  });
}

class SupplierOrderMergeValidator {
  static SupplierOrderMergeValidationResult validate(List<SupplierOrder> orders) {
    if (orders.length < 2) {
      return const SupplierOrderMergeValidationResult(
        isValid: false,
        errorMessage: 'Se requieren al menos 2 órdenes para consolidar.',
      );
    }

    // 1. Validar que TODAS las órdenes estén en estado BORRADOR
    final allDrafts = orders.every((o) => o.status == SupplierOrderStatus.draft);
    if (!allDrafts) {
      return const SupplierOrderMergeValidationResult(
        isValid: false,
        errorMessage: 'Solo se pueden consolidar órdenes en estado Borrador.',
      );
    }

    // 2. Validar que pertenezcan al mismo proveedor
    final firstSupplierId = orders.first.supplierId;
    final sameSupplier = orders.every((o) => o.supplierId == firstSupplierId);
    if (!sameSupplier) {
      return const SupplierOrderMergeValidationResult(
        isValid: false,
        errorMessage: 'Solo se pueden consolidar órdenes del mismo proveedor.',
      );
    }

    // 3. Validar Dropshipping
    final hasDropship = orders.any((o) => o.isDropshipping);
    if (hasDropship) {
      final allDropship = orders.every((o) => o.isDropshipping);
      if (!allDropship) {
        return const SupplierOrderMergeValidationResult(
          isValid: false,
          errorMessage:
              'No se pueden consolidar órdenes de entrega Dropshipping con inventario propio.',
        );
      }
      final firstClientId = orders.first.clientId;
      final sameClient = orders.every((o) => o.clientId == firstClientId);
      final firstAddress = orders.first.recipientAddress;
      final sameAddress = orders.every((o) => o.recipientAddress == firstAddress);

      if (!sameClient || !sameAddress) {
        return const SupplierOrderMergeValidationResult(
          isValid: false,
          errorMessage:
              'Las órdenes Dropshipping a consolidar deben ser para el mismo cliente y dirección.',
        );
      }
    }

    // 4. Detectar divergencias no bloqueantes (requieren confirmación / selección en modal)
    final firstBranch = orders.first.supplierBranchId;
    final hasBranchConflict = orders.any((o) => o.supplierBranchId != firstBranch);

    final firstPayment = orders.first.paymentMethod;
    final hasPaymentConflict = orders.any((o) => o.paymentMethod != firstPayment);

    return SupplierOrderMergeValidationResult(
      isValid: true,
      hasBranchConflict: hasBranchConflict,
      hasPaymentMethodConflict: hasPaymentConflict,
    );
  }
}
