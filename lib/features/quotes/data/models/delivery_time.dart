class DeliveryTime {
  final String id;
  final String name;
  final int? valueDays;
  final bool isActive;

  DeliveryTime({
    required this.id,
    required this.name,
    this.valueDays,
    required this.isActive,
  });

  factory DeliveryTime.fromJson(Map<String, dynamic> json) {
    return DeliveryTime(
      id: json['id'] as String,
      name: json['name'] as String,
      valueDays: json['value_days'] as int?,
      isActive: json['is_active'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'value_days': valueDays,
      'is_active': isActive,
    };
  }
}
