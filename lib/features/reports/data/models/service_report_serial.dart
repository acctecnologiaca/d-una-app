class ServiceReportSerial {
  final String id;
  final String reportItemId;
  final String? productId;
  final String? productSerialId;
  final String serialNumber;
  final DateTime? createdAt;

  const ServiceReportSerial({
    required this.id,
    required this.reportItemId,
    this.productId,
    this.productSerialId,
    required this.serialNumber,
    this.createdAt,
  });

  factory ServiceReportSerial.fromJson(Map<String, dynamic> json) {
    return ServiceReportSerial(
      id: json['id'] as String? ?? '',
      reportItemId: (json['report_item_id'] ?? json['delivery_note_item_id'])
              as String? ??
          '',
      productId: json['product_id'] as String?,
      productSerialId: json['product_serial_id'] as String?,
      serialNumber: json['serial_number'] as String? ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_item_id': reportItemId,
      if (_cleanUuid(productId) != null) 'product_id': _cleanUuid(productId),
      if (_cleanUuid(productSerialId) != null)
        'product_serial_id': _cleanUuid(productSerialId),
      'serial_number': serialNumber,
    };
  }

  ServiceReportSerial copyWith({
    String? id,
    String? reportItemId,
    String? productId,
    String? productSerialId,
    String? serialNumber,
    DateTime? createdAt,
  }) {
    return ServiceReportSerial(
      id: id ?? this.id,
      reportItemId: reportItemId ?? this.reportItemId,
      productId: productId ?? this.productId,
      productSerialId: productSerialId ?? this.productSerialId,
      serialNumber: serialNumber ?? this.serialNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

String? _cleanUuid(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
