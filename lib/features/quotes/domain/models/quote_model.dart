import 'package:flutter/material.dart';

enum QuoteStatus {
  draft,
  sent,
  resent,
  inReview,
  approved,
  rejected,
  finalized,
  cancelled,
  expired;

  String get label {
    switch (this) {
      case QuoteStatus.draft:
        return 'Borrador';
      case QuoteStatus.sent:
        return 'Enviada';
      case QuoteStatus.resent:
        return 'Reenviada';
      case QuoteStatus.inReview:
        return 'En revisión';
      case QuoteStatus.approved:
        return 'Aprobada';
      case QuoteStatus.rejected:
        return 'Rechazada';
      case QuoteStatus.finalized:
        return 'Finalizada';
      case QuoteStatus.cancelled:
        return 'Cancelada';
      case QuoteStatus.expired:
        return 'Expirada';
    }
  }

  String get iconPath {
    switch (this) {
      case QuoteStatus.draft:
        return 'assets/icons/status_draft.png';
      case QuoteStatus.sent:
        return 'assets/icons/status_sent.png';
      case QuoteStatus.resent:
        return 'assets/icons/status_resent.png';
      case QuoteStatus.inReview:
        return 'assets/icons/status_review.png';
      case QuoteStatus.approved:
        return 'assets/icons/status_approved.png';
      case QuoteStatus.rejected:
        return 'assets/icons/status_rejected.png';
      case QuoteStatus.finalized:
        return 'assets/icons/status_finalized.png';
      case QuoteStatus.cancelled:
        return 'assets/icons/status_cancelled.png';
      case QuoteStatus.expired:
        return 'assets/icons/status_expired.png';
    }
  }

  String get dbValue {
    switch (this) {
      case QuoteStatus.draft:
        return 'draft';
      case QuoteStatus.sent:
        return 'sent';
      case QuoteStatus.resent:
        return 'resent';
      case QuoteStatus.inReview:
        return 'review';
      case QuoteStatus.approved:
        return 'approved';
      case QuoteStatus.rejected:
        return 'rejected';
      case QuoteStatus.finalized:
        return 'finalized';
      case QuoteStatus.cancelled:
        return 'cancelled';
      case QuoteStatus.expired:
        return 'expired';
    }
  }

  static QuoteStatus fromDbValue(String value) {
    switch (value) {
      case 'draft':
        return QuoteStatus.draft;
      case 'sent':
        return QuoteStatus.sent;
      case 'resent':
        return QuoteStatus.resent;
      case 'review':
        return QuoteStatus.inReview;
      case 'approved':
        return QuoteStatus.approved;
      case 'rejected':
        return QuoteStatus.rejected;
      case 'finalized':
        return QuoteStatus.finalized;
      case 'cancelled':
        return QuoteStatus.cancelled;
      case 'expired':
        return QuoteStatus.expired;
      default:
        return QuoteStatus.draft;
    }
  }

  Color statusColor(ColorScheme colors) {
    switch (this) {
      case QuoteStatus.draft:
        return colors.onSurfaceVariant;
      case QuoteStatus.sent:
        return colors.primary;
      case QuoteStatus.resent:
        return const Color(0xFF1D8DC7);
      case QuoteStatus.inReview:
        return const Color(0xFFFFB964);
      case QuoteStatus.approved:
        return const Color(0xFF388E3C);
      case QuoteStatus.rejected:
        return const Color(0xFFF86F28);
      case QuoteStatus.finalized:
        return const Color(0xFF6A53AD);
      case QuoteStatus.cancelled:
        return colors.error;
      case QuoteStatus.expired:
        return colors.secondary;
    }
  }
}

enum StockStatus {
  available,
  lowStock,
  unavailable;

  String get label {
    switch (this) {
      case StockStatus.available:
        return 'Stock disponible';
      case StockStatus.lowStock:
        return 'Stock insuficiente';
      case StockStatus.unavailable:
        return 'Stock no disponible';
    }
  }

  String get iconPath {
    switch (this) {
      case StockStatus.available:
        return 'assets/icons/stock_available.png';
      case StockStatus.lowStock:
        return 'assets/icons/stock_down.png';
      case StockStatus.unavailable:
        return 'assets/icons/stock_unavailable.png';
    }
  }
}

class Quote {
  final String id;
  final String quoteNumber;
  final String clientName;
  final DateTime date;
  final double amount;
  final String? categoryId;
  final String? categoryName;
  final QuoteStatus status;
  final StockStatus stockStatus;
  final bool hasPriceIncrease;
  final bool isArchived;
  final String? quoteTag;
  final DateTime createdAt;

  bool get canShowAlerts =>
      status == QuoteStatus.draft ||
      status == QuoteStatus.sent ||
      status == QuoteStatus.resent ||
      status == QuoteStatus.inReview;

  Quote({
    required this.id,
    required this.quoteNumber,
    required this.clientName,
    required this.date,
    required this.amount,
    this.categoryId,
    this.categoryName,
    required this.status,
    required this.stockStatus,
    this.hasPriceIncrease = false,
    required this.createdAt,
    this.isArchived = false,
    this.quoteTag,
  });

  Quote copyWith({
    String? id,
    String? quoteNumber,
    String? clientName,
    DateTime? date,
    double? amount,
    String? categoryId,
    String? categoryName,
    QuoteStatus? status,
    StockStatus? stockStatus,
    bool? hasPriceIncrease,
    bool? isArchived,
    String? quoteTag,
    DateTime? createdAt,
  }) {
    return Quote(
      id: id ?? this.id,
      quoteNumber: quoteNumber ?? this.quoteNumber,
      clientName: clientName ?? this.clientName,
      date: date ?? this.date,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      status: status ?? this.status,
      stockStatus: stockStatus ?? this.stockStatus,
      hasPriceIncrease: hasPriceIncrease ?? this.hasPriceIncrease,
      isArchived: isArchived ?? this.isArchived,
      quoteTag: quoteTag ?? this.quoteTag,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
