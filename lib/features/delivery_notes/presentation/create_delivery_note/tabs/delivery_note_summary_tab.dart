import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import '../providers/create_delivery_note_provider.dart';
import '../../../domain/models/delivery_note_item_model.dart';

class DeliveryNoteSummaryTab extends ConsumerWidget {
  final Function(int) onNavigateToTab;

  const DeliveryNoteSummaryTab({super.key, required this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(createDeliveryNoteProvider);
    final colors = Theme.of(context).colorScheme;

    if (state.items.isEmpty && state.clientId == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: colors.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Sin datos que mostrar',
              style: TextStyle(color: colors.onSurfaceVariant, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Cliente Section
          _buildSectionHeader(context, Icons.people, 'Cliente'),
          _buildClientCard(context, state),
          const SizedBox(height: 20),

          // 2. Despacho Section
          _buildSectionHeader(context, Icons.local_shipping, 'Despacho'),
          _buildDeliveryCard(context, state),
          const SizedBox(height: 20),

          // 3. A Despachar Section (Sin montos ni costos monetarios)
          _buildSectionHeader(
            context,
            Symbols.hand_package_rounded,
            'A Despachar',
            fill: 1.0,
          ),
          _buildProductsCard(context, state.items),
          const SizedBox(height: 20),

          // 4. Documento Vinculado (Opcional si proviene de Cotización u Orden de Compra)
          if (state.quoteId != null || state.supplierOrderId != null) ...[
            _buildSectionHeader(context, Icons.link, 'Documento vinculado'),
            _buildLinkedDocumentCard(context, state),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  // ── Section Header ─────────────────────────────────────────
  Widget _buildSectionHeader(
    BuildContext context,
    IconData icon,
    String title, {
    double? fill = 1.0,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: colors.onSurfaceVariant,
            fill: fill,
          ),
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

  // ── 1. Cliente Card ────────────────────────────────────────
  Widget _buildClientCard(BuildContext context, DeliveryNoteCreateState state) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
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
              state.clientName ?? 'No seleccionado',
              isTextValue: true,
            ),
            const SizedBox(height: 10),
            _buildSummaryRow(
              context,
              Icons.person_outline,
              'Contacto',
              (state.contactName != null &&
                      state.contactName!.trim().isNotEmpty)
                  ? state.contactName!
                  : 'No especificado',
              isTextValue: true,
            ),
          ],
        ),
      ),
    );
  }

  // ── 2. Despacho Card ───────────────────────────────────────
  Widget _buildDeliveryCard(
    BuildContext context,
    DeliveryNoteCreateState state,
  ) {
    final colors = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy');

    String modalityLabel;
    IconData modalityIcon;
    switch (state.deliveryType) {
      case 'pickup':
        modalityLabel = 'Retiro en Sede';
        modalityIcon = Icons.storefront_outlined;
        break;
      case 'courier':
        modalityLabel = 'Encomienda';
        modalityIcon = Icons.markunread_mailbox_outlined;
        break;
      case 'direct_delivery':
      default:
        modalityLabel = 'Entrega Directa';
        modalityIcon = Icons.local_shipping_outlined;
        break;
    }

    final fullAddress = [
      state.recipientAddress,
      state.recipientCity,
      state.recipientState,
    ].whereType<String>().where((s) => s.trim().isNotEmpty).join(', ');

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildSummaryRow(
              context,
              Icons.calendar_today_outlined,
              'Fecha de entrega',
              state.deliveryDate != null
                  ? dateFormat.format(state.deliveryDate!)
                  : 'No establecida',
              isTextValue: true,
            ),
            const SizedBox(height: 10),
            _buildSummaryRow(
              context,
              modalityIcon,
              'Modalidad',
              modalityLabel,
              isTextValue: true,
            ),
            if (state.deliveryType == 'courier') ...[
              if (state.shippingCompanyName != null &&
                  state.shippingCompanyName!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildSummaryRow(
                  context,
                  Icons.local_shipping_outlined,
                  'Empresa courier',
                  state.shippingCompanyName!,
                  isTextValue: true,
                ),
              ],
              if (state.trackingNumber != null &&
                  state.trackingNumber!.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildSummaryRow(
                  context,
                  Icons.numbers_outlined,
                  'N° Guía / Tracking',
                  state.trackingNumber!,
                  isTextValue: true,
                ),
              ],
            ],
            if (state.deliveryType != 'pickup') ...[
              if (fullAddress.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildSummaryRow(
                  context,
                  Icons.place_outlined,
                  'Dirección',
                  fullAddress,
                  isTextValue: true,
                ),
              ],
              if (state.deliveryInstructions != null &&
                  state.deliveryInstructions!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildSummaryRow(
                  context,
                  Icons.info_outline,
                  'Instrucciones',
                  state.deliveryInstructions!,
                  isTextValue: true,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  // ── 3. A Despachar Card (Homologado a Registro de Compras, sin costos) ────
  Widget _buildProductsCard(
    BuildContext context,
    List<DeliveryNoteItemModel> items,
  ) {
    final colors = Theme.of(context).colorScheme;
    final displayItems = items.take(3).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      color: colors.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header interno de productos
            _buildProductHeaderRow(
              context,
              Icons.inventory_2_outlined,
              'Productos',
              itemsCount: items.length,
            ),
            const SizedBox(height: 10),

            // Lista de productos (máximo 3)
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8.0,
                  horizontal: 26.0,
                ),
                child: Text(
                  'No se han agregado productos',
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              ...displayItems.map((item) {
                final qty = item.quantity % 1 == 0
                    ? item.quantity.toInt().toString()
                    : item.quantity.toStringAsFixed(1);
                final uom = item.uom;
                final needed = item.quantity.round();
                final assigned = item.serials.length;
                final missingSerials =
                    item.requiresSerials && (assigned < needed);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0, left: 26.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: '$qty $uom: ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              TextSpan(
                                text: item.name,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (missingSerials) ...[
                        const SizedBox(width: 8),
                        _buildMissingSerialsBadge(context, item),
                      ],
                    ],
                  ),
                );
              }),

            // Indicador de productos adicionales si hay más de 3
            if (items.length > 3)
              Padding(
                padding: const EdgeInsets.only(
                  left: 26.0,
                  top: 2.0,
                  bottom: 4.0,
                ),
                child: Text(
                  '+ ${items.length - 3} producto${items.length - 3 == 1 ? "" : "s"} más...',
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: colors.onSurfaceVariant.withValues(alpha: 0.8),
                  ),
                ),
              ),

            // Botón "Ir a productos" si hay más de cero productos (> 0)
            if (items.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () => onNavigateToTab(2),
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
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeaderRow(
    BuildContext context,
    IconData icon,
    String title, {
    required int itemsCount,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 18, color: colors.onSurface),
        const SizedBox(width: 8),
        Text(
          '$title ($itemsCount)',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildMissingSerialsBadge(
    BuildContext context,
    DeliveryNoteItemModel item,
  ) {
    final colors = Theme.of(context).colorScheme;
    final needed = item.quantity.round();
    final assigned = item.serials.length;
    final missing = needed - assigned;
    if (missing <= 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Symbols.barcode, size: 14, color: colors.error),
          const SizedBox(width: 4),
          Text(
            '$assigned/$needed',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: colors.error,
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. Documento Vinculado Card ────────────────────────────
  Widget _buildLinkedDocumentCard(
    BuildContext context,
    DeliveryNoteCreateState state,
  ) {
    final colors = Theme.of(context).colorScheme;
    final isQuote = state.quoteId != null && state.quoteId!.isNotEmpty;
    final docTitle = isQuote
        ? 'Cotización vinculada'
        : 'Orden de Compra vinculada';
    final docId = isQuote ? state.quoteId! : state.supplierOrderId!;
    final route = isQuote
        ? '/quotes/view/$docId'
        : '/supplier-orders/view/$docId';

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: 0.6)),
      ),
      color: colors.surface,
      child: ListTile(
        leading: Icon(
          isQuote ? Icons.description_outlined : Icons.shopping_bag_outlined,
          color: colors.primary,
        ),
        title: Text(
          docTitle,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        subtitle: Text(
          'ID: $docId',
          style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          context.push(route);
        },
      ),
    );
  }

  // ── Helper Row ─────────────────────────────────────────────
  Widget _buildSummaryRow(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isTextValue = false,
  }) {
    final colors = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: colors.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontWeight: isTextValue ? FontWeight.w500 : FontWeight.w600,
              color: colors.onSurface,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
