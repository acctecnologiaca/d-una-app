class Observation {
  final String id;
  final String? userId;
  final String description;
  final bool isDefaultDeliveryNote;
  final bool isActive;

  Observation({
    required this.id,
    this.userId,
    required this.description,
    required this.isDefaultDeliveryNote,
    required this.isActive,
  });

  factory Observation.fromJson(Map<String, dynamic> json) {
    return Observation(
      id: json['id'] as String,
      userId: json['user_id'] as String?,
      description: json['description'] as String,
      isDefaultDeliveryNote: json['is_default_delivery_note'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'description': description,
      'is_default_delivery_note': isDefaultDeliveryNote,
      'is_active': isActive,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Observation &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
