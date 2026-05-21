class DeliveryTime {
  final String id;
  final String? userId;
  final String name;
  final int? minValue;
  final int? maxValue;
  final String unit;
  final String type;
  final int orderIdx;
  final bool isVerified;
  final bool isActive;

  DeliveryTime({
    required this.id,
    this.userId,
    required this.name,
    this.minValue,
    this.maxValue,
    required this.unit,
    required this.type,
    required this.orderIdx,
    this.isVerified = false,
    this.isActive = true,
  });

  factory DeliveryTime.fromJson(Map<String, dynamic> json) {
    return DeliveryTime(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      minValue: json['min_value'],
      maxValue: json['max_value'],
      unit: json['unit'] ?? 'days',
      type: json['type'] ?? 'delivery',
      orderIdx: json['order_idx'] ?? 0,
      isVerified: json['is_verified'] ?? false,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'min_value': minValue,
      'max_value': maxValue,
      'unit': unit,
      'type': type,
      'order_idx': orderIdx,
      'is_verified': isVerified,
      'is_active': isActive,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeliveryTime &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
