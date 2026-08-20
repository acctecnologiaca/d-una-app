import 'package:flutter/material.dart';

enum ServiceReportStatus {
  draft,
  sent,
  resent,
  opened,
  finalized,
  cancelled;

  String get label {
    switch (this) {
      case ServiceReportStatus.draft:
        return 'Borrador';
      case ServiceReportStatus.sent:
        return 'Enviado';
      case ServiceReportStatus.resent:
        return 'Reenviado';
      case ServiceReportStatus.opened:
        return 'Abierto';
      case ServiceReportStatus.finalized:
        return 'Finalizado';
      case ServiceReportStatus.cancelled:
        return 'Cancelado';
    }
  }

  String get iconPath {
    switch (this) {
      case ServiceReportStatus.draft:
        return 'assets/icons/status_draft.png';
      case ServiceReportStatus.sent:
        return 'assets/icons/status_sent.png';
      case ServiceReportStatus.resent:
        return 'assets/icons/status_resent.png';
      case ServiceReportStatus.opened:
        return 'assets/icons/status_opened.png';
      case ServiceReportStatus.finalized:
        return 'assets/icons/status_finalized.png';
      case ServiceReportStatus.cancelled:
        return 'assets/icons/status_cancelled.png';
    }
  }

  String get dbValue {
    switch (this) {
      case ServiceReportStatus.draft:
        return 'draft';
      case ServiceReportStatus.sent:
        return 'sent';
      case ServiceReportStatus.resent:
        return 'resent';
      case ServiceReportStatus.opened:
        return 'opened';
      case ServiceReportStatus.finalized:
        return 'finalized';
      case ServiceReportStatus.cancelled:
        return 'cancelled';
    }
  }

  static ServiceReportStatus fromDbValue(String value) {
    switch (value) {
      case 'draft':
        return ServiceReportStatus.draft;
      case 'sent':
        return ServiceReportStatus.sent;
      case 'resent':
        return ServiceReportStatus.resent;
      case 'opened':
        return ServiceReportStatus.opened;
      case 'finalized':
        return ServiceReportStatus.finalized;
      case 'cancelled':
        return ServiceReportStatus.cancelled;
      default:
        return ServiceReportStatus.draft;
    }
  }

  Color statusColor(ColorScheme colors) {
    switch (this) {
      case ServiceReportStatus.draft:
        return colors.onSurfaceVariant;
      case ServiceReportStatus.sent:
        return colors.primary;
      case ServiceReportStatus.resent:
        return const Color(0xFF1D8DC7);
      case ServiceReportStatus.opened:
        return const Color(0xFF5C6BC0);
      case ServiceReportStatus.finalized:
        return const Color(0xFF6A53AD);
      case ServiceReportStatus.cancelled:
        return colors.error;
    }
  }
}

enum InterventionType {
  preventive,
  corrective,
  installation,
  diagnosis,
  warranty,
  support;

  String get label {
    switch (this) {
      case InterventionType.preventive:
        return 'Mant. Preventivo';
      case InterventionType.corrective:
        return 'Mant. Correctivo';
      case InterventionType.installation:
        return 'Instalación';
      case InterventionType.diagnosis:
        return 'Diagnóstico';
      case InterventionType.warranty:
        return 'Garantía';
      case InterventionType.support:
        return 'Soporte Técnico';
    }
  }

  String get dbValue {
    switch (this) {
      case InterventionType.preventive:
        return 'preventive';
      case InterventionType.corrective:
        return 'corrective';
      case InterventionType.installation:
        return 'installation';
      case InterventionType.diagnosis:
        return 'diagnosis';
      case InterventionType.warranty:
        return 'warranty';
      case InterventionType.support:
        return 'support';
    }
  }

  static InterventionType fromDbValue(String value) {
    switch (value) {
      case 'preventive':
        return InterventionType.preventive;
      case 'corrective':
        return InterventionType.corrective;
      case 'installation':
        return InterventionType.installation;
      case 'diagnosis':
        return InterventionType.diagnosis;
      case 'warranty':
        return InterventionType.warranty;
      case 'support':
        return InterventionType.support;
      default:
        return InterventionType.corrective;
    }
  }

  IconData get icon {
    switch (this) {
      case InterventionType.preventive:
        return Icons.build_outlined;
      case InterventionType.corrective:
        return Icons.handyman_outlined;
      case InterventionType.installation:
        return Icons.bolt_outlined;
      case InterventionType.diagnosis:
        return Icons.search_outlined;
      case InterventionType.warranty:
        return Icons.verified_outlined;
      case InterventionType.support:
        return Icons.computer_outlined;
    }
  }
}

class ServiceReportSummary {
  final String id;
  final String reportNumber;
  final String clientName;
  final DateTime date;
  final double amount;
  final String? categoryId;
  final String? categoryName;
  final ServiceReportStatus status;
  final InterventionType interventionType;
  final String? advisorId;
  final String? advisorName;
  final bool isArchived;
  final String? reportTag;
  final DateTime createdAt;
  final String? durationText;

  ServiceReportSummary({
    required this.id,
    required this.reportNumber,
    required this.clientName,
    required this.date,
    required this.amount,
    this.categoryId,
    this.categoryName,
    this.advisorId,
    this.advisorName,
    required this.status,
    required this.interventionType,
    this.isArchived = false,
    this.reportTag,
    required this.createdAt,
    this.durationText,
  });

  ServiceReportSummary copyWith({
    String? id,
    String? reportNumber,
    String? clientName,
    DateTime? date,
    double? amount,
    String? categoryId,
    String? categoryName,
    String? advisorId,
    String? advisorName,
    ServiceReportStatus? status,
    InterventionType? interventionType,
    bool? isArchived,
    String? reportTag,
    DateTime? createdAt,
    String? durationText,
  }) {
    return ServiceReportSummary(
      id: id ?? this.id,
      reportNumber: reportNumber ?? this.reportNumber,
      clientName: clientName ?? this.clientName,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      advisorId: advisorId ?? this.advisorId,
      advisorName: advisorName ?? this.advisorName,
      status: status ?? this.status,
      interventionType: interventionType ?? this.interventionType,
      isArchived: isArchived ?? this.isArchived,
      reportTag: reportTag ?? this.reportTag,
      createdAt: createdAt ?? this.createdAt,
      durationText: durationText ?? this.durationText,
    );
  }
}
