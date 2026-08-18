class CreditTransactionModel {
  final String id;
  final String userId;
  final String transactionType;
  final int amount;
  final int remainingAmount;
  final String? referenceType;
  final String? referenceId;
  final String? description;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const CreditTransactionModel({
    required this.id,
    required this.userId,
    required this.transactionType,
    required this.amount,
    required this.remainingAmount,
    this.referenceType,
    this.referenceId,
    this.description,
    required this.createdAt,
    this.expiresAt,
  });

  factory CreditTransactionModel.fromJson(Map<String, dynamic> json) {
    return CreditTransactionModel(
      id: json['id'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      transactionType: json['transaction_type'] as String? ?? '',
      amount: json['amount'] as int? ?? 0,
      remainingAmount: json['remaining_amount'] as int? ?? 0,
      referenceType: json['reference_type'] as String?,
      referenceId: json['reference_id'] as String?,
      description: json['description'] as String?,
      createdAt: DateTime.parse(
        json['created_at'] as String? ?? DateTime.now().toIso8601String(),
      ),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }
}
