class QuoteValidationResult {
  final String itemId;
  final String itemType; // 'OWN' or 'SUPPLIER'
  final double currentStock;
  final double currentCost;
  final double reservedStock;

  QuoteValidationResult({
    required this.itemId,
    required this.itemType,
    required this.currentStock,
    required this.currentCost,
    required this.reservedStock,
  });

  factory QuoteValidationResult.fromMap(Map<String, dynamic> map) {
    return QuoteValidationResult(
      itemId: map['item_id'] as String,
      itemType: map['item_type'] as String,
      currentStock: (map['current_stock'] as num).toDouble(),
      currentCost: (map['current_cost'] as num).toDouble(),
      reservedStock: (map['reserved_stock'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
