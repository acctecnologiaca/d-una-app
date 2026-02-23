class CommercialCondition {
  final String id;
  final String description;
  final bool isDefault;
  final bool isActive;

  CommercialCondition({
    required this.id,
    required this.description,
    required this.isDefault,
    required this.isActive,
  });

  factory CommercialCondition.fromJson(Map<String, dynamic> json) {
    return CommercialCondition(
      id: json['id'] as String,
      description: json['description'] as String,
      isDefault: json['is_default'] as bool,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'is_default': isDefault,
      'is_active': isActive,
    };
  }
}
