import 'quote_item_product.dart';
import 'quote_item_service.dart';
import 'quote_condition.dart';
import '../../../clients/data/models/client_model.dart';

class Quote {
  final String id;
  final String userId;
  final String? quoteNumber;
  final String clientId;
  final String? contactId;
  final String? advisorId;
  final String? categoryId;
  final String status;
  final DateTime dateIssued;
  final int validityDays;
  final double subtotal;
  final double taxAmount;
  final double total;
  final String? notes;
  final String? quoteTag;
  final bool isArchived; // New Field
  final String? pdfUrl;
  final String? actionToken;
  final DateTime? actionTokenExpiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined/Fetched Data (Optional)
  final String? clientName; // New Field from join
  final String? categoryName; // New Field from join
  final String? contactName; // New Field from join
  final String? contactPhone; // New Field from join
  final String? contactEmail; // New Field from join
  final String? advisorName; // New Field from join
  final List<QuoteItemProduct>? products;
  final List<QuoteItemService>? services;
  final List<QuoteCondition>? conditions;
  final Contact? contact;

  // Additional Client Details (for View Mode)
  final String? clientTaxId;
  final String? clientAddress;
  final String? clientPhone;
  final String? clientEmail;
  final String? clientType;
  final String? clientCity;
  final String? clientState;
  final String? clientCountry;

  Quote({
    required this.id,
    required this.userId,
    this.quoteNumber,
    required this.clientId,
    this.contactId,
    this.advisorId,
    this.categoryId,
    required this.status,
    required this.dateIssued,
    required this.validityDays,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    this.notes,
    this.quoteTag,
    this.isArchived = false,
    this.pdfUrl,
    this.actionToken,
    this.actionTokenExpiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.clientName,
    this.categoryName,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.advisorName,
    this.products,
    this.services,
    this.conditions,
    this.clientTaxId,
    this.clientAddress,
    this.clientPhone,
    this.clientEmail,
    this.clientType,
    this.clientCity,
    this.clientState,
    this.clientCountry,
    this.contact,
  });

  Quote copyWith({
    String? id,
    String? userId,
    String? quoteNumber,
    String? clientId,
    String? contactId,
    String? advisorId,
    String? categoryId,
    String? status,
    DateTime? dateIssued,
    int? validityDays,
    double? subtotal,
    double? taxAmount,
    double? total,
    String? notes,
    String? quoteTag,
    bool? isArchived,
    String? pdfUrl,
    String? actionToken,
    DateTime? actionTokenExpiresAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? clientName,
    String? categoryName,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? advisorName,
    List<QuoteItemProduct>? products,
    List<QuoteItemService>? services,
    List<QuoteCondition>? conditions,
    Contact? contact,
    String? clientTaxId,
    String? clientAddress,
    String? clientPhone,
    String? clientEmail,
    String? clientType,
    String? clientCity,
    String? clientState,
    String? clientCountry,
  }) {
    return Quote(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      quoteNumber: quoteNumber ?? this.quoteNumber,
      clientId: clientId ?? this.clientId,
      contactId: contactId ?? this.contactId,
      advisorId: advisorId ?? this.advisorId,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      dateIssued: dateIssued ?? this.dateIssued,
      validityDays: validityDays ?? this.validityDays,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      quoteTag: quoteTag ?? this.quoteTag,
      isArchived: isArchived ?? this.isArchived,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      actionToken: actionToken ?? this.actionToken,
      actionTokenExpiresAt: actionTokenExpiresAt ?? this.actionTokenExpiresAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientName: clientName ?? this.clientName,
      categoryName: categoryName ?? this.categoryName,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      advisorName: advisorName ?? this.advisorName,
      products: products ?? this.products,
      services: services ?? this.services,
      conditions: conditions ?? this.conditions,
      contact: contact ?? this.contact,
      clientTaxId: clientTaxId ?? this.clientTaxId,
      clientAddress: clientAddress ?? this.clientAddress,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      clientType: clientType ?? this.clientType,
      clientCity: clientCity ?? this.clientCity,
      clientState: clientState ?? this.clientState,
      clientCountry: clientCountry ?? this.clientCountry,
    );
  }

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      quoteNumber: json['quote_number'] as String?,
      clientId: json['client_id'] as String,
      contactId: json['contact_id'] as String?,
      advisorId: json['advisor_id'] as String?,
      categoryId: json['category_id'] as String?,
      status: json['status'] as String,
      dateIssued: DateTime.parse(json['date_issued'] as String),
      validityDays: json['validity_days'] as int,

      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,

      notes: json['notes'] as String?,
      quoteTag: json['quote_tag'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isArchived: json['is_archived'] as bool? ?? false,
      pdfUrl: json['pdf_url'] as String?,
      actionToken: json['action_token'] as String?,
      actionTokenExpiresAt: json['action_token_expires_at'] != null
          ? DateTime.parse(json['action_token_expires_at'] as String)
          : null,

      // Handle joined client name (robust mapping for Map or List)
      clientName: _extractClientName(json['clients']),

      // Handle joined category name
      categoryName: _extractCategoryName(json['category'] ?? json['categories']),

      // Handle joined contact info
      contactName: _extractField(json['contacts'], 'name'),
      contactPhone: _extractField(json['contacts'], 'phone'),
      contactEmail: _extractField(json['contacts'], 'email'),

      // Handle full contact object
      contact: json['contacts'] != null ? _extractContact(json['contacts']) : null,

      // Handle joined advisor name
      advisorName: _extractAdvisorName(json['advisor']),

      // Handle nested items if joined
      products: (json['quote_items_products'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((e) => QuoteItemProduct.fromJson(e))
          .toList(),
      services: (json['quote_items_services'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((e) => QuoteItemService.fromJson(e))
          .toList(),
      conditions: (json['quote_conditions'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((e) => QuoteCondition.fromJson(e))
          .toList(),

      // Extract additional client info
      clientTaxId: _extractField(json['clients'], 'tax_id'),
      clientAddress: _extractField(json['clients'], 'address'),
      clientPhone: _extractField(json['clients'], 'phone'),
      clientEmail: _extractField(json['clients'], 'email'),
      clientType: _extractField(json['clients'], 'type'),
      clientCity: _extractField(json['clients'], 'city'),
      clientState: _extractField(json['clients'], 'state'),
      clientCountry: _extractField(json['clients'], 'country'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'quote_number': quoteNumber,
      'client_id': clientId,
      'contact_id': contactId,
      'advisor_id': advisorId,
      'category_id': categoryId,
      'status': status,
      'date_issued': dateIssued.toIso8601String(),
      'validity_days': validityDays,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total': total,
      'notes': notes,
      'quote_tag': quoteTag,
      'is_archived': isArchived,
      'pdf_url': pdfUrl,
      'action_token': actionToken,
      'action_token_expires_at': actionTokenExpiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static String? _extractClientName(dynamic clientsJson) {
    if (clientsJson == null) return 'Cliente Desconocido';
    if (clientsJson is Map) {
      return clientsJson['name'] as String? ?? 'Cliente Desconocido';
    }
    if (clientsJson is List && clientsJson.isNotEmpty) {
      final first = clientsJson.first;
      if (first is Map) {
        return first['name'] as String? ?? 'Cliente Desconocido';
      }
    }
    return 'Cliente Desconocido';
  }

  static String? _extractCategoryName(dynamic categoriesJson) {
    if (categoriesJson == null) return null;
    if (categoriesJson is Map) {
      return categoriesJson['name'] as String?;
    }
    if (categoriesJson is List && categoriesJson.isNotEmpty) {
      final first = categoriesJson.first;
      if (first is Map) {
        return first['name'] as String?;
      }
    }
    return null;
  }
  static String? _extractAdvisorName(dynamic advisorJson) {
    if (advisorJson == null) return null;
    if (advisorJson is Map) {
      return advisorJson['full_name'] as String?;
    }
    if (advisorJson is List && advisorJson.isNotEmpty) {
      final first = advisorJson.first;
      if (first is Map) {
        return first['full_name'] as String?;
      }
    }
    return null;
  }


  static String? _extractField(dynamic json, String field) {
    if (json == null) return null;
    if (json is Map) return json[field]?.toString();
    if (json is List && json.isNotEmpty) {
      final first = json.first;
      if (first is Map) return first[field]?.toString();
    }
    return null;
  }

  static Contact? _extractContact(dynamic contactJson) {
    if (contactJson == null) return null;
    if (contactJson is Map) {
      return Contact.fromJson(contactJson as Map<String, dynamic>);
    }
    if (contactJson is List && contactJson.isNotEmpty) {
      final first = contactJson.first;
      if (first is Map) {
        return Contact.fromJson(first as Map<String, dynamic>);
      }
    }
    return null;
  }
}
