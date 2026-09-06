class DeliveryNoteObservationModel {
  final String? id;
  final String? deliveryNoteId;
  final String? observationId;
  final String title;
  final String description;
  final int orderIndex;

  const DeliveryNoteObservationModel({
    this.id,
    this.deliveryNoteId,
    this.observationId,
    this.title = 'Observación',
    required this.description,
    this.orderIndex = 0,
  });

  factory DeliveryNoteObservationModel.fromJson(Map<String, dynamic> json) {
    return DeliveryNoteObservationModel(
      id: json['id'] as String?,
      deliveryNoteId: json['delivery_note_id'] as String?,
      observationId: json['observation_id'] as String?,
      title: json['title'] as String? ?? 'Observación',
      description: json['description'] as String? ?? '',
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (deliveryNoteId != null) 'delivery_note_id': deliveryNoteId,
      if (observationId != null) 'observation_id': observationId,
      'description': description,
      'order_index': orderIndex,
    };
  }

  DeliveryNoteObservationModel copyWith({
    String? id,
    String? deliveryNoteId,
    String? observationId,
    String? description,
    int? orderIndex,
  }) {
    return DeliveryNoteObservationModel(
      id: id ?? this.id,
      deliveryNoteId: deliveryNoteId ?? this.deliveryNoteId,
      observationId: observationId ?? this.observationId,
      description: description ?? this.description,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }
}
