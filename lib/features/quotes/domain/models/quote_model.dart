enum QuoteStatus {
  draft,
  sent,
  resent,
  approved,
  rejected,
  inReview,
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
      case QuoteStatus.approved:
        return 'Aprobada';
      case QuoteStatus.rejected:
        return 'Rechazada';
      case QuoteStatus.inReview:
        return 'En revisión';
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
      case QuoteStatus.approved:
        return 'assets/icons/status_approved.png';
      case QuoteStatus.rejected:
        return 'assets/icons/status_rejected.png';
      case QuoteStatus.inReview:
        return 'assets/icons/status_review.png';
      case QuoteStatus.finalized:
        return 'assets/icons/status_finalized.png';
      case QuoteStatus.cancelled:
        return 'assets/icons/status_cancelled.png';
      case QuoteStatus.expired:
        return 'assets/icons/status_expired.png';
    }
  }
}

enum StockStatus {
  available,
  unavailable;

  String get label {
    switch (this) {
      case StockStatus.available:
        return 'Stock disponible';
      case StockStatus.unavailable:
        return 'Stock no disponible';
    }
  }

  String get iconPath {
    switch (this) {
      case StockStatus.available:
        return 'assets/icons/stock_available.png';
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
  final QuoteStatus status;
  final StockStatus stockStatus;
  final bool isArchived;

  Quote({
    required this.id,
    required this.quoteNumber,
    required this.clientName,
    required this.date,
    required this.amount,
    required this.status,
    required this.stockStatus,
    this.isArchived = false,
  });
}
