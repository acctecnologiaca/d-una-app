import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../../../domain/models/delivery_note_model.dart';
import '../../../domain/models/delivery_note_status.dart';
import '../../delivery_notes_list/providers/delivery_notes_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/linked_document_card.dart';
import 'package:d_una_app/features/quotes/domain/models/quote_model.dart';
import 'package:d_una_app/features/supplier_orders/presentation/supplier_orders_list/providers/supplier_orders_providers.dart';
import 'package:d_una_app/features/supplier_orders/domain/models/supplier_order_status.dart';

class ViewDeliveryNoteSummaryTab extends ConsumerWidget {
  final String noteId;
  final Function(int) onNavigateToTab;
  final double bottomPadding;

  const ViewDeliveryNoteSummaryTab({
    super.key,
    required this.noteId,
    required this.onNavigateToTab,
    this.bottomPadding = 24.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(deliveryNoteDetailProvider(noteId));

    return noteAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error al cargar resumen: $e')),
      data: (note) {
        if (note == null) {
          return const Center(
            child: Text('No se encontró la información de la nota de entrega'),
          );
        }

        final status = note.status;
        final isDelivered = status == DeliveryNoteStatus.finalized;

        final String deliveryTypeLabel = switch (note.deliveryType) {
          'pickup' => 'Retiro en tienda / almacén',
          'courier' => 'Envío por encomienda',
          _ => 'Despacho propio',
        };

        final displayItems = note.items.take(3).toList();

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 0. Info Section (Status & Last Mod)
              _buildInfoCard(context, note, status),
              const SizedBox(height: 16),

              // 1. Cliente Section
              _buildSectionHeader(context, Icons.people, 'Cliente'),
              _buildClientCard(context, note),
              const SizedBox(height: 16),

              // 2. Despacho Section
              _buildSectionHeader(context, Icons.local_shipping, 'Despacho'),
              _buildDeliveryCard(context, note, deliveryTypeLabel),
              const SizedBox(height: 16),

              // 3. A Despachar Section (Productos)
              _buildSectionHeader(
                context,
                Symbols.hand_package_rounded,
                'A Despachar',
                fill: 1.0,
              ),
              _buildProductsCard(context, note, displayItems),

              // 4. Documento Vinculado Section (si aplica)
              if (note.quoteId != null || note.supplierOrderId != null) ...[
                _buildLinkedDocumentSection(context, ref, note),
              ],

              // 5. Recepción y Firma Section (solo si ya fue entregada / firmada)
              if (isDelivered ||
                  (note.receivedByName != null &&
                      note.receivedByName!.isNotEmpty)) ...[
                const SizedBox(height: 16),
                _buildSectionHeader(
                  context,
                  Symbols.signature,
                  'Recepción y Firma',
                ),
                _buildReceptionCard(context, ref, note),
              ],
            ],
          ),
        );
      },
    );
  }

  // ── 0. Info Card (Estatus & Últ. Mod) ──────────────────────────────
  Widget _buildInfoCard(
    BuildContext context,
    DeliveryNoteModel note,
    DeliveryNoteStatus status,
  ) {
    final colors = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy - hh:mm a');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.outlineVariant),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Symbols.conversion_path,
                  size: 20,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Estatus:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                _buildStatusBadge(context, status),
                if (note.isDropshipping) ...[
                  const Spacer(),
                  Chip(
                    label: const Text(
                      'Dropshipping',
                      style: TextStyle(fontSize: 11),
                    ),
                    avatar: const Icon(Symbols.local_shipping, size: 14),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Symbols.update, size: 20, color: colors.onSurfaceVariant),
                const SizedBox(width: 8),
                Text(
                  'Últ. mod:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  dateFormat.format(note.updatedAt.toLocal()),
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, DeliveryNoteStatus status) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(status.iconPath, width: 16, height: 16),
          const SizedBox(width: 8),
          Text(
            status.label,
            style: TextStyle(
              color: status.statusColor(colors),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  // ── Section Header ────────────────────────────────────────────────
  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title, {
    double? fill,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.onSurfaceVariant, fill: fill),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  // ── 1. Cliente Card ───────────────────────────────────────────────
  Widget _buildClientCard(BuildContext context, DeliveryNoteModel note) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.outlineVariant),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryRow(
              context,
              Icons.domain,
              'Razón social',
              note.clientName,
              isTextValue: true,
            ),
            if (note.contactName != null && note.contactName!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSummaryRow(
                context,
                Icons.person_outline,
                'Contacto',
                note.contactName!,
                isTextValue: true,
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onNavigateToTab(0),
                icon: const Icon(Icons.arrow_forward_ios, size: 14),
                label: const Text(
                  'Ir a General',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. Despacho Card ──────────────────────────────────────────────
  Widget _buildDeliveryCard(
    BuildContext context,
    DeliveryNoteModel note,
    String deliveryTypeLabel,
  ) {
    final colors = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy');
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.outlineVariant),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryRow(
              context,
              Icons.calendar_today_outlined,
              'Fecha de Despacho',
              note.deliveryDate != null
                  ? dateFormat.format(note.deliveryDate!)
                  : dateFormat.format(note.date),
              isTextValue: true,
            ),
            const SizedBox(height: 12),
            _buildSummaryRow(
              context,
              Icons.local_shipping_outlined,
              'Modalidad',
              deliveryTypeLabel,
              isTextValue: true,
            ),
            if (note.deliveryType == 'courier' &&
                note.shippingCompanyName != null) ...[
              const SizedBox(height: 12),
              _buildSummaryRow(
                context,
                Icons.directions_bus_outlined,
                'Transporte',
                '${note.shippingCompanyName}${note.trackingNumber != null ? " • Guía: ${note.trackingNumber}" : ""}',
                isTextValue: true,
              ),
            ],
            if (note.recipientAddress != null &&
                note.recipientAddress!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSummaryRow(
                context,
                Icons.location_on_outlined,
                'Dirección',
                '${note.recipientAddress}${note.recipientCity != null ? ", ${note.recipientCity}" : ""}',
                isTextValue: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── 3. A Despachar Card (Productos) ───────────────────────────────
  Widget _buildProductsCard(
    BuildContext context,
    DeliveryNoteModel note,
    List<dynamic> displayItems,
  ) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.outlineVariant),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Symbols.inventory_2,
                      size: 18,
                      color: colors.onSurface,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Productos (${note.items.length})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...displayItems.map((item) {
              final qtyFormatted = item.quantity % 1 == 0
                  ? item.quantity.toInt().toString()
                  : item.quantity.toString();
              return Padding(
                padding: const EdgeInsets.only(bottom: 6.0, left: 4.0),
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '$qtyFormatted ${item.uom}: ',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: item.name,
                        style: TextStyle(color: colors.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              );
            }),
            if (note.items.length > 3) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4.0, top: 2.0),
                child: Text(
                  '+ ${note.items.length - 3} producto(s) más...',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            if (note.hasMissingSerials) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colors.errorContainer.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, size: 16, color: colors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Hay productos con seriales pendientes por completar.',
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => onNavigateToTab(1), // Productos Tab
                icon: const Icon(Icons.arrow_forward_ios, size: 14),
                label: const Text(
                  'Ir a productos',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Documento Vinculado Section ───────────────────────────────
  Widget _buildLinkedDocumentSection(
    BuildContext context,
    WidgetRef ref,
    DeliveryNoteModel note,
  ) {
    if (note.quoteId != null && note.quoteId!.isNotEmpty) {
      final linkedQuoteAsync = ref.watch(linkedQuoteProvider(note.quoteId!));
      return linkedQuoteAsync.when(
        data: (quote) {
          if (quote == null) return const SizedBox.shrink();
          final quoteNumber = quote.quoteNumber ?? 'Sin número';
          final status = QuoteStatus.fromDbValue(quote.status);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _buildSectionHeader(
                context,
                Icons.request_quote_outlined,
                'Cotización',
              ),
              LinkedDocumentCard.single(
                id: note.quoteId!,
                title: quoteNumber,
                statusLabel: status.label,
                statusIconPath: status.iconPath,
                isCancelled: status == QuoteStatus.cancelled,
                onTap: () async {
                  await context.push('/quotes/view/${note.quoteId}');
                  ref.invalidate(linkedQuoteProvider(note.quoteId!));
                },
              ),
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      );
    }

    if (note.supplierOrderId != null && note.supplierOrderId!.isNotEmpty) {
      final linkedOrderAsync = ref.watch(
        supplierOrderDetailProvider(note.supplierOrderId!),
      );
      return linkedOrderAsync.when(
        data: (orderData) {
          final order = orderData.order;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _buildSectionHeader(
                context,
                Icons.shopping_cart_outlined,
                'Orden de compra',
              ),
              LinkedDocumentCard.single(
                id: order.id,
                title: order.orderNumber,
                companyName: order.supplierName,
                statusLabel: order.status.label,
                statusIconPath: order.status.iconPath,
                isCancelled: order.status == SupplierOrderStatus.cancelled,
                onTap: () async {
                  await context.push('/supplier-orders/view/${order.id}');
                  ref.invalidate(supplierOrderDetailProvider(note.supplierOrderId!));
                },
              ),
            ],
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      );
    }

    return const SizedBox.shrink();
  }

  // ── 5. Recepción y Firma Card ─────────────────────────────────────
  Widget _buildReceptionCard(
    BuildContext context,
    WidgetRef ref,
    DeliveryNoteModel note,
  ) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colors.outlineVariant),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSummaryRow(
              context,
              Icons.person_pin_outlined,
              'Receptor',
              note.receivedByName ?? 'No registrado',
              isTextValue: true,
            ),
            if (note.receivedById != null && note.receivedById!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSummaryRow(
                context,
                Icons.badge_outlined,
                'Cédula / ID',
                note.receivedById!,
                isTextValue: true,
              ),
            ],
            if (note.receivedByPhone != null &&
                note.receivedByPhone!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSummaryRow(
                context,
                Icons.phone_outlined,
                'Teléfono',
                note.receivedByPhone!,
                isTextValue: true,
              ),
            ],
            if (note.receiverRelationship != null &&
                note.receiverRelationship!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildSummaryRow(
                context,
                Icons.work_outline,
                'Cargo',
                note.receiverRelationship!,
                isTextValue: true,
              ),
            ],
            if (note.receivedAt != null) ...[
              const SizedBox(height: 12),
              _buildSummaryRow(
                context,
                Icons.access_time,
                'Fecha de recepción',
                DateFormat('dd/MM/yyyy - hh:mm a').format(note.receivedAt!.toLocal()),
                isTextValue: true,
              ),
            ],
            if (note.signatureData != null &&
                note.signatureData!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Firma Digital Registrada:',
                style: textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 130,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colors.outlineVariant),
                ),
                padding: const EdgeInsets.all(12),
                clipBehavior: Clip.antiAlias,
                alignment: Alignment.center,
                child: note.signatureData!.startsWith('data:image')
                    ? Image.memory(
                        base64Decode(note.signatureData!.split(',').last),
                        fit: BoxFit.contain,
                      )
                    : const Text('Firma en formato digital registrada'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Summary Row Helper ────────────────────────────────────────────
  Widget _buildSummaryRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    TextStyle? valueStyle,
    Color? iconColor,
    bool isTextValue = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: iconColor ?? colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style:
                valueStyle ??
                TextStyle(
                  fontWeight: isTextValue ? FontWeight.normal : FontWeight.w600,
                  color: isTextValue
                      ? colors.onSurfaceVariant
                      : colors.onSurface,
                  fontSize: isTextValue ? 14 : 15,
                ),
          ),
        ),
      ],
    );
  }
}
