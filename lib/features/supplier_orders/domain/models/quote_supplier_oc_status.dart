class QuoteSupplierOcStatus {
  final String supplierId;
  final String supplierName;
  final int itemCount;
  final double total;
  final bool hasExistingOc;
  final String? existingOrderNumber;
  final String? existingOrderId;

  const QuoteSupplierOcStatus({
    required this.supplierId,
    required this.supplierName,
    required this.itemCount,
    required this.total,
    required this.hasExistingOc,
    this.existingOrderNumber,
    this.existingOrderId,
  });
}
