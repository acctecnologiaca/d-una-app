class ServiceReportCondition {
  final String id;
  final String reportId;
  final String? conditionId; // Link to commercial_conditions
  final String description; // Snapshot
  final int orderIndex;

  ServiceReportCondition({
    required this.id,
    required this.reportId,
    this.conditionId,
    required this.description,
    required this.orderIndex,
  });

  factory ServiceReportCondition.fromJson(Map<String, dynamic> json) {
    return ServiceReportCondition(
      id: json['id'] as String? ?? '',
      reportId: json['report_id'] as String? ?? '',
      conditionId: json['condition_id'] as String?,
      description: json['description'] as String? ?? '',
      orderIndex: json['order_index'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_id': reportId,
      if (conditionId != null) 'condition_id': conditionId,
      'description': description,
      'order_index': orderIndex,
    };
  }

  ServiceReportCondition copyWith({
    String? id,
    String? reportId,
    String? conditionId,
    String? description,
    int? orderIndex,
  }) {
    return ServiceReportCondition(
      id: id ?? this.id,
      reportId: reportId ?? this.reportId,
      conditionId: conditionId ?? this.conditionId,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
