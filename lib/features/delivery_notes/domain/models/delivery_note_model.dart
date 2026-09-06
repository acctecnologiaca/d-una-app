import 'delivery_note_status.dart';
import 'delivery_note_item_model.dart';
import 'delivery_note_observation_model.dart';

class DeliveryNoteModel {
  final String id;
  final String userId;
  final String deliveryNoteNumber;
  final String clientId;
  final String? contactId;
  final String? quoteId;
  final String? supplierOrderId;
  final String? clientPoNumber;
  final String? tag;
  final String? notes;
  final DeliveryNoteStatus status;
  final DateTime date;
  final DateTime? deliveryDate;
  final String deliveryType; // 'pickup', 'direct_delivery', 'courier'
  final String? shippingCompanyId;
  final String? trackingNumber;
  final String? recipientAddress;
  final String? recipientCity;
  final String? recipientState;
  final String? deliveryInstructions;
  final String? receivedByName;
  final String? receivedById;
  final String? receivedByPhone;
  final String? receiverRelationship;
  final DateTime? receivedAt;
  final String? signatureData;
  final double subtotal;
  final double taxRate;
  final double taxAmount;
  final double total;
  final bool isDropshipping;
  final bool hasMissingSerials;
  final String? actionToken;
  final DateTime? actionTokenExpiresAt;
  final DateTime? openedAt;
  final String? pdfUrl;
  final bool isArchived;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields for UI
  final String clientName;
  final String? clientTaxId;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final String? clientPhone;
  final String? clientEmail;
  final String? shippingCompanyName;
  final List<DeliveryNoteItemModel> items;
  final List<DeliveryNoteObservationModel> observations;

  const DeliveryNoteModel({
    required this.id,
    required this.userId,
    required this.deliveryNoteNumber,
    required this.clientId,
    this.contactId,
    this.quoteId,
    this.supplierOrderId,
    this.clientPoNumber,
    this.tag,
    this.notes,
    this.status = DeliveryNoteStatus.draft,
    required this.date,
    this.deliveryDate,
    this.deliveryType = 'direct_delivery',
    this.shippingCompanyId,
    this.trackingNumber,
    this.recipientAddress,
    this.recipientCity,
    this.recipientState,
    this.deliveryInstructions,
    this.receivedByName,
    this.receivedById,
    this.receivedByPhone,
    this.receiverRelationship,
    this.receivedAt,
    this.signatureData,
    this.subtotal = 0.0,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.total = 0.0,
    this.isDropshipping = false,
    this.hasMissingSerials = false,
    this.actionToken,
    this.actionTokenExpiresAt,
    this.openedAt,
    this.pdfUrl,
    this.isArchived = false,
    required this.createdAt,
    required this.updatedAt,
    this.clientName = 'Cliente',
    this.clientTaxId,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.clientPhone,
    this.clientEmail,
    this.shippingCompanyName,
    this.items = const [],
    this.observations = const [],
  });

  String get shortNumber {
    final parts = deliveryNoteNumber.split('-');
    if (parts.length >= 3) {
      return parts.last;
    }
    return deliveryNoteNumber;
  }

  double get subtotalAmount => subtotal;
  double get totalAmount => total;
  int get itemsCount => items.length;

  int get totalItemsCount => items.fold<int>(0, (sum, item) => sum + item.quantity.round());

  bool get checkHasMissingSerials {
    return items.any((i) => i.hasMissingSerials);
  }

  factory DeliveryNoteModel.fromJson(Map<String, dynamic> json) {
    final clientData = json['clients'] as Map<String, dynamic>?;
    final contactData = json['contacts'] as Map<String, dynamic>?;
    final shippingData = json['shipping_companies'] as Map<String, dynamic>?;

    final rawItems = json['delivery_note_items'] as List<dynamic>? ?? [];
    final itemsList = rawItems
        .map((i) => DeliveryNoteItemModel.fromJson(i as Map<String, dynamic>))
        .toList();

    final rawObs = json['delivery_note_observations'] as List<dynamic>? ?? [];
    final obsList = rawObs
        .map((o) => DeliveryNoteObservationModel.fromJson(o as Map<String, dynamic>))
        .toList();

    return DeliveryNoteModel(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      deliveryNoteNumber: json['delivery_note_number'] as String? ?? 'NE-PENDIENTE',
      clientId: json['client_id'] as String? ?? '',
      contactId: json['contact_id'] as String?,
      quoteId: json['quote_id'] as String?,
      supplierOrderId: json['supplier_order_id'] as String?,
      clientPoNumber: json['client_po_number'] as String?,
      tag: json['tag'] as String?,
      notes: json['notes'] as String?,
      status: DeliveryNoteStatus.fromDbValue(json['status'] as String? ?? 'draft'),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      deliveryDate: json['delivery_date'] != null
          ? DateTime.tryParse(json['delivery_date'] as String)
          : null,
      deliveryType: json['delivery_type'] as String? ?? 'direct_delivery',
      shippingCompanyId: json['shipping_company_id'] as String?,
      trackingNumber: json['tracking_number'] as String?,
      recipientAddress: json['recipient_address'] as String?,
      recipientCity: json['recipient_city'] as String?,
      recipientState: json['recipient_state'] as String?,
      deliveryInstructions: json['delivery_instructions'] as String?,
      receivedByName: json['received_by_name'] as String?,
      receivedById: json['received_by_id'] as String?,
      receivedByPhone: json['received_by_phone'] as String?,
      receiverRelationship: json['receiver_relationship'] as String?,
      receivedAt: json['received_at'] != null
          ? DateTime.tryParse(json['received_at'] as String)
          : null,
      signatureData: json['signature_data'] as String?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxRate: (json['tax_rate'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      isDropshipping: json['is_dropshipping'] == true,
      hasMissingSerials: json['has_missing_serials'] == true,
      actionToken: json['action_token'] as String?,
      actionTokenExpiresAt: json['action_token_expires_at'] != null
          ? DateTime.tryParse(json['action_token_expires_at'] as String)
          : null,
      openedAt: json['opened_at'] != null
          ? DateTime.tryParse(json['opened_at'] as String)
          : null,
      pdfUrl: json['pdf_url'] as String?,
      isArchived: json['is_archived'] == true,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      clientName: clientData?['name'] as String? ?? 'Cliente',
      clientTaxId: (clientData?['tax_id'] ?? clientData?['identification_id']) as String?,
      contactName: contactData?['name'] as String?,
      contactPhone: contactData?['phone'] as String?,
      contactEmail: contactData?['email'] as String?,
      clientPhone: clientData?['phone'] as String?,
      clientEmail: clientData?['email'] as String?,
      shippingCompanyName: shippingData?['name'] as String?,
      items: itemsList,
      observations: obsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'delivery_note_number': deliveryNoteNumber,
      'client_id': clientId,
      if (contactId != null) 'contact_id': contactId,
      if (quoteId != null) 'quote_id': quoteId,
      if (supplierOrderId != null) 'supplier_order_id': supplierOrderId,
      if (clientPoNumber != null) 'client_po_number': clientPoNumber,
      if (tag != null) 'tag': tag,
      if (notes != null) 'notes': notes,
      'status': status.dbValue,
      'date': date.toIso8601String().split('T')[0],
      if (deliveryDate != null)
        'delivery_date': deliveryDate!.toIso8601String().split('T')[0],
      'delivery_type': deliveryType,
      if (shippingCompanyId != null) 'shipping_company_id': shippingCompanyId,
      if (trackingNumber != null) 'tracking_number': trackingNumber,
      if (recipientAddress != null) 'recipient_address': recipientAddress,
      if (recipientCity != null) 'recipient_city': recipientCity,
      if (recipientState != null) 'recipient_state': recipientState,
      if (deliveryInstructions != null)
        'delivery_instructions': deliveryInstructions,
      if (receivedByName != null) 'received_by_name': receivedByName,
      if (receivedById != null) 'received_by_id': receivedById,
      if (receivedByPhone != null) 'received_by_phone': receivedByPhone,
      if (receiverRelationship != null)
        'receiver_relationship': receiverRelationship,
      if (receivedAt != null) 'received_at': receivedAt!.toIso8601String(),
      if (signatureData != null) 'signature_data': signatureData,
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total': total,
      'is_dropshipping': isDropshipping,
      'has_missing_serials': hasMissingSerials,
      if (actionToken != null) 'action_token': actionToken,
      if (actionTokenExpiresAt != null)
        'action_token_expires_at': actionTokenExpiresAt!.toIso8601String(),
      if (openedAt != null) 'opened_at': openedAt!.toIso8601String(),
      if (pdfUrl != null) 'pdf_url': pdfUrl,
      'is_archived': isArchived,
    };
  }

  DeliveryNoteModel copyWith({
    String? id,
    String? userId,
    String? deliveryNoteNumber,
    String? clientId,
    String? contactId,
    String? quoteId,
    String? supplierOrderId,
    String? clientPoNumber,
    String? tag,
    String? notes,
    DeliveryNoteStatus? status,
    DateTime? date,
    DateTime? deliveryDate,
    String? deliveryType,
    String? shippingCompanyId,
    String? trackingNumber,
    String? recipientAddress,
    String? recipientCity,
    String? recipientState,
    String? deliveryInstructions,
    String? receivedByName,
    String? receivedById,
    String? receivedByPhone,
    String? receiverRelationship,
    DateTime? receivedAt,
    String? signatureData,
    double? subtotal,
    double? taxRate,
    double? taxAmount,
    double? total,
    bool? isDropshipping,
    bool? hasMissingSerials,
    String? actionToken,
    DateTime? actionTokenExpiresAt,
    DateTime? openedAt,
    String? pdfUrl,
    bool? isArchived,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? clientName,
    String? clientTaxId,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? clientPhone,
    String? clientEmail,
    String? shippingCompanyName,
    List<DeliveryNoteItemModel>? items,
    List<DeliveryNoteObservationModel>? observations,
  }) {
    return DeliveryNoteModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      deliveryNoteNumber: deliveryNoteNumber ?? this.deliveryNoteNumber,
      clientId: clientId ?? this.clientId,
      contactId: contactId ?? this.contactId,
      quoteId: quoteId ?? this.quoteId,
      supplierOrderId: supplierOrderId ?? this.supplierOrderId,
      clientPoNumber: clientPoNumber ?? this.clientPoNumber,
      tag: tag ?? this.tag,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      date: date ?? this.date,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveryType: deliveryType ?? this.deliveryType,
      shippingCompanyId: shippingCompanyId ?? this.shippingCompanyId,
      trackingNumber: trackingNumber ?? this.trackingNumber,
      recipientAddress: recipientAddress ?? this.recipientAddress,
      recipientCity: recipientCity ?? this.recipientCity,
      recipientState: recipientState ?? this.recipientState,
      deliveryInstructions: deliveryInstructions ?? this.deliveryInstructions,
      receivedByName: receivedByName ?? this.receivedByName,
      receivedById: receivedById ?? this.receivedById,
      receivedByPhone: receivedByPhone ?? this.receivedByPhone,
      receiverRelationship: receiverRelationship ?? this.receiverRelationship,
      receivedAt: receivedAt ?? this.receivedAt,
      signatureData: signatureData ?? this.signatureData,
      subtotal: subtotal ?? this.subtotal,
      taxRate: taxRate ?? this.taxRate,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      isDropshipping: isDropshipping ?? this.isDropshipping,
      hasMissingSerials: hasMissingSerials ?? this.hasMissingSerials,
      actionToken: actionToken ?? this.actionToken,
      actionTokenExpiresAt: actionTokenExpiresAt ?? this.actionTokenExpiresAt,
      openedAt: openedAt ?? this.openedAt,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientName: clientName ?? this.clientName,
      clientTaxId: clientTaxId ?? this.clientTaxId,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      shippingCompanyName: shippingCompanyName ?? this.shippingCompanyName,
      items: items ?? this.items,
      observations: observations ?? this.observations,
    );
  }
}
