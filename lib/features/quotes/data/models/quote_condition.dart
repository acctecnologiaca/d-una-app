class QuoteCondition {
  final String id;
  final String quoteId;
  final String? conditionId; // Link to standard
  final String description; // Snapshot
  final int orderIndex;

  QuoteCondition({
    required this.id,
    required this.quoteId,
    this.conditionId,
    required this.description,
    required this.orderIndex,
  });

  factory QuoteCondition.fromJson(Map<String, dynamic> json) {
    return QuoteCondition(
      id: json['id'] as String,
      quoteId: json['quote_id'] as String,
      conditionId: json['condition_id'] as String?,
      description: json['description'] as String,
      orderIndex: json['order_index'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'quote_id': quoteId,
      'condition_id': conditionId,
      'description': description,
      'order_index': orderIndex,
    };
  }
}
