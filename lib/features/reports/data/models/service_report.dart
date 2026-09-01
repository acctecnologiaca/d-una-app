import 'service_report_item_product.dart';
import 'service_report_item_service.dart';
import 'service_report_condition.dart';
import '../../../clients/data/models/client_model.dart';
import '../../../collaborators/domain/models/collaborator.dart';

class ServiceReport {
  final String id;
  final String userId;
  final String? reportNumber;
  final String clientId;
  final String? contactId;
  final String? advisorId;
  final String? categoryId;
  final String status;
  final String interventionType;
  final String? requestDescription;
  final String? workDescription;
  final String? recommendations;
  final DateTime serviceDate;
  final String? startTime;
  final String? endTime;
  final int? durationMinutes;
  final double subtotal;
  final double taxAmount;
  final double total;
  final String? notes;
  final String? reportTag;
  final bool isArchived;
  final String? pdfUrl;
  final String? actionToken;
  final DateTime? actionTokenExpiresAt;
  final DateTime? openedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined/Fetched Data
  final String? clientName;
  final String? categoryName;
  final String? contactName;
  final String? contactPhone;
  final String? contactEmail;
  final String? advisorName;
  final List<Collaborator>? technicians;
  final List<ServiceReportItemProduct>? products;
  final List<ServiceReportItemService>? services;
  final List<ServiceReportCondition>? conditions;
  final Contact? contact;

  // Additional Client Details (for View / PDF Mode)
  final String? clientTaxId;
  final String? clientAddress;
  final String? clientPhone;
  final String? clientEmail;
  final String? clientType;
  final String? clientCity;
  final String? clientState;
  final String? clientCountry;

  ServiceReport({
    required this.id,
    required this.userId,
    this.reportNumber,
    required this.clientId,
    this.contactId,
    this.advisorId,
    this.categoryId,
    required this.status,
    this.interventionType = 'corrective',
    this.requestDescription,
    this.workDescription,
    this.recommendations,
    required this.serviceDate,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    required this.subtotal,
    required this.taxAmount,
    required this.total,
    this.notes,
    this.reportTag,
    this.isArchived = false,
    this.pdfUrl,
    this.actionToken,
    this.actionTokenExpiresAt,
    this.openedAt,
    required this.createdAt,
    required this.updatedAt,
    this.clientName,
    this.categoryName,
    this.contactName,
    this.contactPhone,
    this.contactEmail,
    this.advisorName,
    this.technicians,
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

  ServiceReport copyWith({
    String? id,
    String? userId,
    String? reportNumber,
    String? clientId,
    String? contactId,
    String? advisorId,
    String? categoryId,
    String? status,
    String? interventionType,
    String? requestDescription,
    String? workDescription,
    String? recommendations,
    DateTime? serviceDate,
    String? startTime,
    String? endTime,
    int? durationMinutes,
    double? subtotal,
    double? taxAmount,
    double? total,
    String? notes,
    String? reportTag,
    bool? isArchived,
    String? pdfUrl,
    String? actionToken,
    DateTime? actionTokenExpiresAt,
    DateTime? openedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? clientName,
    String? categoryName,
    String? contactName,
    String? contactPhone,
    String? contactEmail,
    String? advisorName,
    List<Collaborator>? technicians,
    List<ServiceReportItemProduct>? products,
    List<ServiceReportItemService>? services,
    List<ServiceReportCondition>? conditions,
    String? clientTaxId,
    String? clientAddress,
    String? clientPhone,
    String? clientEmail,
    String? clientType,
    String? clientCity,
    String? clientState,
    String? clientCountry,
    Contact? contact,
  }) {
    return ServiceReport(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      reportNumber: reportNumber ?? this.reportNumber,
      clientId: clientId ?? this.clientId,
      contactId: contactId ?? this.contactId,
      advisorId: advisorId ?? this.advisorId,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      interventionType: interventionType ?? this.interventionType,
      requestDescription: requestDescription ?? this.requestDescription,
      workDescription: workDescription ?? this.workDescription,
      recommendations: recommendations ?? this.recommendations,
      serviceDate: serviceDate ?? this.serviceDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      subtotal: subtotal ?? this.subtotal,
      taxAmount: taxAmount ?? this.taxAmount,
      total: total ?? this.total,
      notes: notes ?? this.notes,
      reportTag: reportTag ?? this.reportTag,
      isArchived: isArchived ?? this.isArchived,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      actionToken: actionToken ?? this.actionToken,
      actionTokenExpiresAt: actionTokenExpiresAt ?? this.actionTokenExpiresAt,
      openedAt: openedAt ?? this.openedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      clientName: clientName ?? this.clientName,
      categoryName: categoryName ?? this.categoryName,
      contactName: contactName ?? this.contactName,
      contactPhone: contactPhone ?? this.contactPhone,
      contactEmail: contactEmail ?? this.contactEmail,
      advisorName: advisorName ?? this.advisorName,
      technicians: technicians ?? this.technicians,
      products: products ?? this.products,
      services: services ?? this.services,
      conditions: conditions ?? this.conditions,
      clientTaxId: clientTaxId ?? this.clientTaxId,
      clientAddress: clientAddress ?? this.clientAddress,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      clientType: clientType ?? this.clientType,
      clientCity: clientCity ?? this.clientCity,
      clientState: clientState ?? this.clientState,
      clientCountry: clientCountry ?? this.clientCountry,
      contact: contact ?? this.contact,
    );
  }

  factory ServiceReport.fromJson(Map<String, dynamic> json) {
    // 1. Resolve nested client info
    String? resolvedClientName;
    String? resolvedClientTaxId;
    String? resolvedClientAddress;
    String? resolvedClientPhone;
    String? resolvedClientEmail;
    String? resolvedClientType;
    String? resolvedClientCity;
    String? resolvedClientState;
    String? resolvedClientCountry;

    if (json['clients'] != null && json['clients'] is Map<String, dynamic>) {
      final clientMap = json['clients'] as Map<String, dynamic>;
      resolvedClientName = clientMap['name'] as String?;
      resolvedClientTaxId = clientMap['tax_id'] as String?;
      resolvedClientAddress = clientMap['address'] as String?;
      resolvedClientPhone = clientMap['phone'] as String?;
      resolvedClientEmail = clientMap['email'] as String?;
      resolvedClientType = clientMap['type'] as String?;
      resolvedClientCity = clientMap['city'] as String?;
      resolvedClientState = clientMap['state'] as String?;
      resolvedClientCountry = clientMap['country'] as String?;
    } else {
      resolvedClientName = json['client_name'] as String?;
      resolvedClientTaxId = json['client_tax_id'] as String?;
      resolvedClientAddress = json['client_address'] as String?;
      resolvedClientPhone = json['client_phone'] as String?;
      resolvedClientEmail = json['client_email'] as String?;
      resolvedClientType = json['client_type'] as String?;
      resolvedClientCity = json['client_city'] as String?;
      resolvedClientState = json['client_state'] as String?;
      resolvedClientCountry = json['client_country'] as String?;
    }

    // 2. Resolve nested category
    String? resolvedCategoryName;
    if (json['categories'] != null &&
        json['categories'] is Map<String, dynamic>) {
      resolvedCategoryName = json['categories']['name'] as String?;
    } else {
      resolvedCategoryName = json['category_name'] as String?;
    }

    // 3. Resolve technicians and nested advisor
    List<Collaborator>? resolvedTechnicians;
    if (json['service_report_collaborators'] != null &&
        json['service_report_collaborators'] is List) {
      resolvedTechnicians = (json['service_report_collaborators'] as List)
          .map((c) {
            if (c is Map<String, dynamic> && c['collaborators'] != null) {
              return Collaborator.fromJson(
                c['collaborators'] as Map<String, dynamic>,
              );
            }
            return null;
          })
          .whereType<Collaborator>()
          .toList();
    }

    String? resolvedAdvisorName;
    if (resolvedTechnicians != null && resolvedTechnicians.isNotEmpty) {
      resolvedAdvisorName =
          resolvedTechnicians.map((t) => t.fullName).join(', ');
    } else if (json['collaborators'] != null &&
        json['collaborators'] is Map<String, dynamic>) {
      resolvedAdvisorName = json['collaborators']['full_name'] as String?;
    } else {
      resolvedAdvisorName = json['advisor_name'] as String?;
    }

    // 4. Resolve nested contact
    String? resolvedContactName;
    String? resolvedContactPhone;
    String? resolvedContactEmail;
    Contact? resolvedContact;
    if (json['contacts'] != null && json['contacts'] is Map<String, dynamic>) {
      final contactMap = json['contacts'] as Map<String, dynamic>;
      resolvedContactName = contactMap['name'] as String?;
      resolvedContactPhone = contactMap['phone'] as String?;
      resolvedContactEmail = contactMap['email'] as String?;
      try {
        resolvedContact = Contact.fromJson(contactMap);
      } catch (_) {}
    } else {
      resolvedContactName = json['contact_name'] as String?;
      resolvedContactPhone = json['contact_phone'] as String?;
      resolvedContactEmail = json['contact_email'] as String?;
    }

    return ServiceReport(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      reportNumber: json['report_number'] as String?,
      clientId: json['client_id'] as String,
      contactId: json['contact_id'] as String?,
      advisorId: json['advisor_id'] as String?,
      categoryId: json['category_id'] as String?,
      status: json['status'] as String? ?? 'draft',
      interventionType: json['intervention_type'] as String? ?? 'corrective',
      requestDescription: json['request_description'] as String?,
      workDescription: json['work_description'] as String?,
      recommendations: json['recommendations'] as String?,
      serviceDate: json['service_date'] != null
          ? DateTime.parse(json['service_date'] as String)
          : DateTime.now(),
      startTime: json['start_time'] as String?,
      endTime: json['end_time'] as String?,
      durationMinutes: json['duration_minutes'] as int?,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      taxAmount: (json['tax_amount'] as num?)?.toDouble() ?? 0.0,
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String?,
      reportTag: json['report_tag'] as String?,
      isArchived: json['is_archived'] as bool? ?? false,
      pdfUrl: json['pdf_url'] as String?,
      actionToken: json['action_token'] as String?,
      actionTokenExpiresAt: json['action_token_expires_at'] != null
          ? DateTime.parse(json['action_token_expires_at'] as String)
          : null,
      openedAt: json['opened_at'] != null
          ? DateTime.parse(json['opened_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      clientName: resolvedClientName,
      categoryName: resolvedCategoryName,
      contactName: resolvedContactName,
      contactPhone: resolvedContactPhone,
      contactEmail: resolvedContactEmail,
      advisorName: resolvedAdvisorName,
      clientTaxId: resolvedClientTaxId,
      clientAddress: resolvedClientAddress,
      clientPhone: resolvedClientPhone,
      clientEmail: resolvedClientEmail,
      clientType: resolvedClientType,
      clientCity: resolvedClientCity,
      clientState: resolvedClientState,
      clientCountry: resolvedClientCountry,
      contact: resolvedContact,
      technicians: resolvedTechnicians,
      products: json['service_report_items_products'] != null
          ? (json['service_report_items_products'] as List)
              .map((p) =>
                  ServiceReportItemProduct.fromJson(p as Map<String, dynamic>))
              .toList()
          : null,
      services: json['service_report_items_services'] != null
          ? (json['service_report_items_services'] as List)
              .map((s) =>
                  ServiceReportItemService.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
      conditions: json['service_report_conditions'] != null
          ? (json['service_report_conditions'] as List)
              .map((c) =>
                  ServiceReportCondition.fromJson(c as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      if (reportNumber != null) 'report_number': reportNumber,
      'client_id': clientId,
      if (contactId != null) 'contact_id': contactId,
      if (advisorId != null) 'advisor_id': advisorId,
      if (categoryId != null) 'category_id': categoryId,
      'status': status,
      'intervention_type': interventionType,
      if (requestDescription != null)
        'request_description': requestDescription,
      if (workDescription != null) 'work_description': workDescription,
      if (recommendations != null) 'recommendations': recommendations,
      'service_date': serviceDate.toIso8601String().split('T').first,
      if (startTime != null) 'start_time': startTime,
      if (endTime != null) 'end_time': endTime,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      'subtotal': subtotal,
      'tax_amount': taxAmount,
      'total': total,
      if (notes != null) 'notes': notes,
      if (reportTag != null) 'report_tag': reportTag,
      'is_archived': isArchived,
      if (pdfUrl != null) 'pdf_url': pdfUrl,
      if (actionToken != null) 'action_token': actionToken,
      if (actionTokenExpiresAt != null)
        'action_token_expires_at': actionTokenExpiresAt!.toIso8601String(),
      if (openedAt != null) 'opened_at': openedAt!.toIso8601String(),
    };
  }
}
