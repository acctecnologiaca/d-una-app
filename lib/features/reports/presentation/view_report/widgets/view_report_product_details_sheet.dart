import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/shared/widgets/uom_status_badge.dart';
import 'package:d_una_app/shared/widgets/info_block.dart';
import 'package:d_una_app/shared/widgets/app_toast.dart';
import '../../../data/models/service_report_item_product.dart';

class ViewReportProductDetailsSheet extends StatelessWidget {
  final ServiceReportItemProduct item;

  const ViewReportProductDetailsSheet({
    super.key,
    required this.item,
  });

  static Future<void> show(
    BuildContext context, {
    required ServiceReportItemProduct item,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => ViewReportProductDetailsSheet(item: item),
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
                  item.brand!,
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
                      item.name,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  UomStatusBadge(
                    quantity: item.quantity,
                    maxStock: item.availableStock,
                    uomAbbreviation: item.uom,
                    uomIconName: item.uomIconName,
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
                  ),
                ),
              ],

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // Información Técnica
              Row(
                children: [
                  Icon(
                    Symbols.info,
                    size: 18,
                    color: colors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Información técnica',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              InfoBlock.text(
                label: 'Garantía',
                value: _formatWarranty(),
                icon: Symbols.verified_user,
              ),

              if (item.description != null &&
                  item.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                InfoBlock.text(
                  label: 'Descripción o notas',
                  value: item.description!.trim(),
                  icon: Symbols.notes,
                ),
              ],

              // Sección de Seriales (si aplica)
              if (item.requiresSerials || item.serials.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Icon(
                      Symbols.barcode,
                      size: 20,
                      color: colors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Seriales (${item.serials.length}/${item.quantity.round()})',
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
                ] else if (!item.hasMissingSerials) ...[
                  Text(
                    'No se requieren seriales para este producto.',
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.onSurfaceVariant,
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
