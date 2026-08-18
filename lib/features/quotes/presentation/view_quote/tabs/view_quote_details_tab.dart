import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../../../shared/widgets/info_block.dart';
import '../providers/view_quote_provider.dart';
import '../../../domain/models/quote_model.dart';

class ViewQuoteDetailsTab extends ConsumerWidget {
  final String quoteId;
  const ViewQuoteDetailsTab({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(viewQuoteProvider(quoteId));

    if (state.isLoading && state.quote == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final quote = state.quote;
    if (quote == null) {
      return const Center(child: Text('No se pudo cargar la información de la cotización'));
    }

    final dateFormat = DateFormat('dd/MM/yyyy');
    final expirationDate =
        quote.dateIssued.add(Duration(days: quote.validityDays));

    // Lógica de vencimiento refinada
    final status = QuoteStatus.fromDbValue(quote.status);
    final isPending =
        status == QuoteStatus.draft ||
        status == QuoteStatus.sent ||
        status == QuoteStatus.resent ||
        status == QuoteStatus.opened ||
        status == QuoteStatus.inReview;

    final isExpired = isPending && expirationDate.isBefore(DateTime.now());

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'General',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          InfoBlock.text(
            icon: Icons.numbers,
            label: 'Número de Cotización',
            value: quote.quoteNumber ?? 'S/N',
          ),
          const SizedBox(height: 24),
          InfoBlock.text(
            icon: Icons.calendar_today_outlined,
            label: 'Fecha de Emisión',
            value: dateFormat.format(quote.dateIssued),
          ),
          const SizedBox(height: 24),
          InfoBlock.text(
            icon: Symbols.event_busy,
            label: 'Fecha de Vencimiento',
            value: dateFormat.format(expirationDate),
            backgroundColor: isExpired
                ? colors.errorContainer.withValues(alpha: 0.8)
                : null,
          ),
          const SizedBox(height: 24),
          InfoBlock.text(
            icon: Icons.person_pin_outlined,
            label: 'Asesor Responsable',
            value: quote.advisorName ?? 'No asignado',
          ),
          const SizedBox(height: 24),
          InfoBlock.text(
            icon: Icons.category_outlined,
            label: 'Categoría',
            value: quote.categoryName ?? 'Sin categoría',
          ),
          const SizedBox(height: 24),
          InfoBlock.text(
            icon: Icons.label_outline,
            label: 'Etiqueta',
            value: quote.quoteTag ?? 'Sin etiqueta',
          ),
          if (quote.clientFeedback != null &&
              quote.clientFeedback!.trim().isNotEmpty) ...[
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: Icons.chat_bubble_outline,
              label: 'Comentario del Cliente',
              value: quote.clientFeedback!,
            ),
          ],

          const SizedBox(height: 32),

          Text(
            'Notas adicionales',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Text(
              quote.notes ?? 'No hay notas adicionales.',
              style: textTheme.bodyLarge?.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
