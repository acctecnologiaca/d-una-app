import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/widgets/send_document_email_sheet.dart';
import '../../../data/models/quote.dart';
import 'package:d_una_app/features/quotes/domain/models/quote_model.dart'
    show QuoteStatus;
import 'package:d_una_app/features/quotes/presentation/quotes_list/providers/quotes_provider.dart';
import '../providers/view_quote_provider.dart';

class SendEmailBottomSheet {
  static Future<void> show(BuildContext context, Quote quote) {
    return SendDocumentEmailSheet.show(
      context: context,
      documentId: quote.id,
      documentType: 'quote',
      documentNumber: quote.quoteNumber,
      initialRecipient: quote.contactEmail ?? quote.clientEmail,
      validityDays: quote.validityDays,
      sheetTitle: 'Enviar cotización por correo',
      categoryName: quote.categoryName,
      tag: quote.quoteTag,
      advisorName: quote.advisorName,
      clientDisplayName: quote.contactName ?? quote.clientName,
      generateToken: (ref) =>
          ref.read(quotesRepositoryProvider).generateActionToken(quote.id),
      onStatusUpdate: (ref, _) async {
        final currentStatus = quote.status;
        final newStatus = (currentStatus == QuoteStatus.sent.dbValue ||
                currentStatus == QuoteStatus.resent.dbValue)
            ? QuoteStatus.resent.dbValue
            : QuoteStatus.sent.dbValue;
        await ref
            .read(quotesRepositoryProvider)
            .updateQuoteStatus(quote.id, newStatus);
      },
      onSendSuccess: () {
        final container = ProviderScope.containerOf(context, listen: false);
        container.invalidate(viewQuoteProvider(quote.id));
        refreshAllQuoteProviders(container);
      },
    );
  }
}
