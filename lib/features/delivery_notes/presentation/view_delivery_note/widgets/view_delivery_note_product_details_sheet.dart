import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/core/utils/string_extensions.dart';
import 'package:d_una_app/shared/widgets/uom_status_badge.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import '../../../domain/models/delivery_note_item_model.dart';

class ViewDeliveryNoteProductDetailsSheet extends StatelessWidget {
  final DeliveryNoteItemModel item;

  const ViewDeliveryNoteProductDetailsSheet({
    super.key,
    required this.item,
  });

  static Future<void> show(
    BuildContext context, {
    required DeliveryNoteItemModel item,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => ViewDeliveryNoteProductDetailsSheet(item: item),
    );
  }

  String _formatWarranty() {
    if (item.warrantyTime == null || item.warrantyTime == 0) {
      return 'Sin garantía registrada';
    }
    final unit = item.warrantyUnit == 'years'
        ? (item.warrantyTime == 1 ? 'año' : 'años')
        : (item.warrantyUnit == 'months'
            ? (item.warrantyTime == 1 ? 'mes' : 'meses')
            : (item.warrantyTime == 1 ? 'día' : 'días'));
    return '${item.warrantyTime} $unit';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(0, 16, 0, 16),
                  height: 4,
                  width: 32,
                  decoration: BoxDecoration(
                    color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Cabecera del Producto
              if (item.brand != null && item.brand!.isNotEmpty) ...[
                Text(
                  item.brand!.toTitleCase,
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.name.toTitleCase,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  UomStatusBadge(
                    quantity: item.quantity,
                    uomAbbreviation: item.uom,
                  ),
                ],
              ),
              if (item.model != null && item.model!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  item.model!.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    color: colors.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              const SizedBox(height: 20),
              Divider(height: 1, color: colors.outlineVariant),
              const SizedBox(height: 20),

              // Bloque: Garantía
              InfoBlock.text(
                icon: (item.warrantyTime != null && item.warrantyTime! > 0)
                    ? Symbols.verified_user
                    : Symbols.shield_moon,
                label: 'Garantía',
                value: _formatWarranty(),
              ),

              const SizedBox(height: 20),

              // Bloque: Serialización
              if (!item.requiresSerials) ...[
                InfoBlock.text(
                  icon: Symbols.barcode_scanner,
                  label: 'Control de seriales',
                  value: 'Este producto no requiere seriales',
                ),
              ] else ...[
                Row(
                  children: [
                    Icon(
                      Symbols.barcode_scanner,
                      size: 20,
                      color: colors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Seriales asignados (${item.serials.length}/${item.quantity.round()}):',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Alerta si faltan seriales
                if (item.hasMissingSerials) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.errorContainer.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: colors.error.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: colors.error,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Faltan ${item.missingSerialsCount} serial(es) por asignar.',
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Lista de seriales
                if (item.serials.isNotEmpty) ...[
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: item.serials.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, sIndex) {
                      final s = item.serials[sIndex];
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colors.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Symbols.qr_code,
                              size: 18,
                              color: colors.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: SelectableText(
                                s.serialNumber,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Symbols.content_copy, size: 18),
                              tooltip: 'Copiar serial',
                              color: colors.onSurfaceVariant,
                              visualDensity: VisualDensity.compact,
                              onPressed: () {
                                Clipboard.setData(
                                  ClipboardData(text: s.serialNumber),
                                );
                                AppToast.success(
                                  context,
                                  message: 'Serial copiado al portapapeles',
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ] else ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 28.0),
                    child: Text(
                      'No hay seriales registrados en este producto.',
                      style: TextStyle(
                        fontSize: 13,
                        color: colors.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
