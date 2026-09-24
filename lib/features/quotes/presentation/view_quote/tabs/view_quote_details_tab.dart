import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import '../../../../../shared/widgets/info_block.dart';
import '../../../../clients/presentation/widgets/contact_list_tile.dart';
import '../../../../../core/utils/contact_utils.dart';
import '../providers/view_quote_provider.dart';
import '../../../domain/models/quote_model.dart';
import '../../../../../shared/utils/fab_scroll_padding.dart';

class ViewQuoteDetailsTab extends ConsumerWidget {
  final String quoteId;
  const ViewQuoteDetailsTab({super.key, required this.quoteId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final state = ref.watch(viewQuoteProvider(quoteId));
    final activeFabs = ref.watch(quoteActiveFabsCountProvider(quoteId));
    final bottomPadding = FabScrollPadding.calculate(activeFabs);

    if (state.isLoading && state.quote == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final quote = state.quote;
    if (quote == null) {
      return const Center(
        child: Text('No se pudo cargar la información de la cotización'),
      );
    }

    final isCompany = quote.clientType == 'company';
    final fullAddress = [
      quote.clientAddress,
      quote.clientCity,
      quote.clientState,
      quote.clientCountry,
    ].where((e) => e != null && e.isNotEmpty).join(', ');

    final dateFormat = DateFormat('dd/MM/yyyy');
    final expirationDate = quote.dateIssued.add(
      Duration(days: quote.validityDays),
    );

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
      padding: EdgeInsets.fromLTRB(16.0, 16.0, 16.0, bottomPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── 1. Información del Cliente ────────────────────────
          Text(
            isCompany ? 'Cliente y Contacto' : 'Datos del Cliente',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 24),

          if (isCompany) ...[
            InfoBlock.text(
              icon: Icons.domain_outlined,
              label: 'Razón Social',
              value: quote.clientName ?? 'No registrado',
            ),
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: Icons.badge_outlined,
              label: 'RIF/NIF/RUT',
              value: quote.clientTaxId ?? 'No registrado',
            ),
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: Icons.location_on_outlined,
              label: 'Dirección Fiscal',
              value: fullAddress.isNotEmpty ? fullAddress : 'No registrada',
            ),
            const SizedBox(height: 24),
            if (quote.contact != null)
              ContactListTile(
                name: quote.contact!.name,
                role: quote.contact!.role ?? '',
                initial: quote.contact!.initial,
                isPrimary: quote.contact!.isPrimary,
                onPhoneTap: () =>
                    ContactUtils.makePhoneCall(quote.contact!.phone),
                onWhatsAppTap: () =>
                    ContactUtils.launchWhatsApp(quote.contact!.phone),
                onTap: () {
                  context.push(
                    '/clients/${quote.clientId}/contacts/details',
                    extra: {
                      'companyName': quote.clientName,
                      'contact': quote.contact,
                      'canEdit': false,
                    },
                  );
                },
              )
            else
              InfoBlock.text(
                icon: Icons.person_outline,
                label: 'Persona de contacto',
                value: quote.contactName ?? 'No especificado',
              ),
          ] else ...[
            InfoBlock.text(
              icon: Icons.person_outline,
              label: 'Nombre y apellido',
              value: quote.clientName ?? 'No registrado',
            ),
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: Icons.badge_outlined,
              label: 'Número de identificación',
              value: quote.clientTaxId ?? 'No registrado',
            ),
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: Icons.location_on_outlined,
              label: 'Dirección',
              value: fullAddress.isNotEmpty
                  ? fullAddress
                  : 'Dirección no registrada',
            ),
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: Icons.contact_phone_outlined,
              label: 'Teléfono',
              value: _formatPhone(quote.clientPhone),
            ),
            const SizedBox(height: 24),
            InfoBlock.text(
              icon: Icons.alternate_email_outlined,
              label: 'Correo Electrónico',
              value: quote.clientEmail ?? 'No registrado',
            ),
          ],

          const SizedBox(height: 32),

          // ── 2. Emisión, Vigencia y Asesor ───────────────────
          Text(
            'Emisión, Vigencia y Asesor',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
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

          const SizedBox(height: 32),

          // ── 3. Clasificación e Identificación ────────────────
          Text(
            'Clasificación e Identificación',
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
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

          // ── 4. Notas Adicionales ─────────────────────────────
          if (quote.notes != null && quote.notes!.trim().isNotEmpty) ...[
            Text(
              'Notas adicionales',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Text(
                quote.notes!,
                style: textTheme.bodyLarge?.copyWith(color: colors.onSurface),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatPhone(String? phone) {
    if (phone == null || phone.isEmpty) return 'No registrado';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 5) {
      return '${digits.substring(0, 4)}-${digits.substring(4)}';
    }
    return phone;
  }
}
