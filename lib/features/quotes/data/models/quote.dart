import 'quote_item_product.dart';
import 'quote_item_service.dart';
import 'quote_condition.dart';

class Quote {
  final String id;
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
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined/Fetched Data (Optional)
  final List<QuoteItemProduct>? products;
  final List<QuoteItemService>? services;
  final List<QuoteCondition>? conditions;

  Quote({
    required this.id,
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
    required this.createdAt,
    required this.updatedAt,
    this.products,
    this.services,
    this.conditions,
  });

  factory Quote.fromJson(Map<String, dynamic> json) {
    return Quote(
      id: json['id'] as String,
      quoteNumber: json['quote_number'] as String?,
      clientId: json['client_id'] as String,
      contactId: json['contact_id'] as String?,
      advisorId: json['advisor_id'] as String?,
      categoryId: json['category_id'] as String?,
      status: json['status'] as String,
      dateIssued: DateTime.parse(json['date_issued'] as String),
      validityDays: json['validity_days'] as int,

      subtotal: (json['subtotal'] as num).toDouble(),
      taxAmount: (json['tax_amount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),

      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),

      // Handle nested items if joined
      products: (json['quote_items_products'] as List?)
          ?.map((e) => QuoteItemProduct.fromJson(e))
          .toList(),
      services: (json['quote_items_services'] as List?)
          ?.map((e) => QuoteItemService.fromJson(e))
          .toList(),
      conditions: (json['quote_conditions'] as List?)
          ?.map((e) => QuoteCondition.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
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
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
