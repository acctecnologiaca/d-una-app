import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import '../../delivery_notes_list/providers/delivery_notes_providers.dart';

class ViewDeliveryNoteDeliveryTab extends ConsumerWidget {
  final String noteId;
  final double bottomPadding;

  const ViewDeliveryNoteDeliveryTab({
    super.key,
    required this.noteId,
    this.bottomPadding = 24.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final noteAsync = ref.watch(deliveryNoteDetailProvider(noteId));

    return noteAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('Error al cargar datos de despacho: $e')),
      data: (note) {
        if (note == null) {
          return const Center(
            child: Text('No se encontró la información de la nota de entrega'),
          );
        }

        final dateFormat = DateFormat('dd/MM/yyyy');

        final String deliveryTypeLabel = switch (note.deliveryType) {
          'pickup' => 'Retiro en tienda / almacén',
          'courier' => 'Envío por encomienda / transportista',
          _ => 'Despacho propio',
        };

        final String fullAddress = [
          if (note.recipientAddress != null &&
              note.recipientAddress!.trim().isNotEmpty)
            note.recipientAddress!.trim(),
          if (note.recipientCity != null && note.recipientCity!.trim().isNotEmpty)
            note.recipientCity!.trim(),
          if (note.recipientState != null &&
              note.recipientState!.trim().isNotEmpty)
            note.recipientState!.trim(),
        ].join(', ');

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Modalidad y Logística
              Text(
                'Modalidad y Logística',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              InfoBlock.text(
                icon: Icons.calendar_today_outlined,
                label: 'Fecha de Despacho',
                value: note.deliveryDate != null
                    ? dateFormat.format(note.deliveryDate!)
                    : 'No especificada',
              ),

              const SizedBox(height: 24),

              InfoBlock.text(
                icon: Icons.local_shipping_outlined,
                label: 'Modalidad de Entrega',
                value: deliveryTypeLabel,
              ),

              if (note.isDropshipping) ...[
                const SizedBox(height: 24),
                InfoBlock.text(
                  icon: Symbols.local_shipping,
                  label: 'Tipo de Operación',
                  value:
                      'Dropshipping (Despacho directo desde instalaciones del proveedor)',
                ),
              ],

              // 2. Empresa de Transporte (si es courier)
              if (note.deliveryType == 'courier') ...[
                const SizedBox(height: 32),
                Text(
                  'Empresa de Transporte',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                InfoBlock.text(
                  icon: Icons.directions_bus_outlined,
                  label: 'Empresa de Encomienda',
                  value: note.shippingCompanyName ?? 'No especificada',
                ),
                const SizedBox(height: 24),
                InfoBlock.text(
                  icon: Icons.confirmation_number_outlined,
                  label: 'Número de Guía / Tracking',
                  value: note.trackingNumber ?? 'Sin número de guía asignado',
                ),
              ],

              // 3. Destino de la Mercancía
              const SizedBox(height: 32),
              Text(
                'Destino de la Mercancía',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 24),

              InfoBlock.text(
                icon: Icons.location_on_outlined,
                label: 'Dirección de Entrega',
                value: fullAddress.isNotEmpty ? fullAddress : 'No especificada',
              ),

              // 4. Instrucciones Especiales
              if (note.deliveryInstructions != null &&
                  note.deliveryInstructions!.trim().isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'Instrucciones Especiales',
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                InfoBlock.text(
                  icon: Icons.info_outline,
                  label: 'Instrucciones para el Despachador',
                  value: note.deliveryInstructions!,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
