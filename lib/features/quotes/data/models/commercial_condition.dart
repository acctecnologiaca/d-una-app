class CommercialCondition {
  final String id;
  final String? userId;
  final String description;
  final bool isDefaultQuote;
  final bool isDefaultReport;
  final bool isActive;

  CommercialCondition({
    required this.id,
    this.userId,
    required this.description,
    required this.isDefaultQuote,
    required this.isDefaultReport,
    required this.isActive,
  });

  factory CommercialCondition.fromJson(Map<String, dynamic> json) {
    return CommercialCondition(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      description: json['description'] as String,
      isDefaultQuote: json['is_default_quote'] as bool? ?? false,
      isDefaultReport: json['is_default_report'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'description': description,
      'is_default_quote': isDefaultQuote,
      'is_default_report': isDefaultReport,
      'is_active': isActive,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommercialCondition &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
