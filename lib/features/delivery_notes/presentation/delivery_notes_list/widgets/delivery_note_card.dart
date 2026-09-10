import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/shared/widgets/standard_list_item.dart';
import '../../../domain/models/delivery_note_model.dart';

class DeliveryNoteCard extends StatelessWidget {
  final DeliveryNoteModel note;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelectionMode;
  final bool isSelected;

  const DeliveryNoteCard({
    super.key,
    required this.note,
    this.onTap,
    this.onLongPress,
    this.isSelectionMode = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dateFormat = DateFormat('dd/MM/yyyy');

    final hasWarning = note.hasMissingSerials;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primaryContainer.withValues(alpha: 0.3)
            : (hasWarning
                ? colors.errorContainer.withValues(alpha: 0.8)
                : null),
      ),
      child: StandardListItem(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        onTap: onTap,
        onLongPress: onLongPress,
        overline: Text(
          '${note.deliveryNoteNumber} (${dateFormat.format(note.date)})',
        ),
        title: note.clientName,
        subtitle: (note.tag != null && note.tag!.isNotEmpty) || note.isDropshipping
            ? Wrap(
                spacing: 6,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (note.tag != null && note.tag!.isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.label_outline, size: 16),
                        const SizedBox(width: 4),
                        Text(note.tag!),
                      ],
                    ),
                  if (note.isDropshipping)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.teal.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Symbols.local_shipping, size: 12, color: Colors.teal.shade700),
                          const SizedBox(width: 3),
                          Text(
                            'Dropshipping',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.teal.shade800,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              )
            : null,
        trailing: isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => onTap?.call(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (note.hasMissingSerials) ...[
                    Tooltip(
                      message: 'Faltan seriales por asignar',
                      child: Image.asset(
                        'assets/icons/no_barcode.png',
                        width: 20,
                        height: 20,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  Tooltip(
                    message: note.status.label,
                    child: Image.asset(
                      note.status.iconPath,
                      width: 24,
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          note.status.iconData,
                          size: 24,
                          color: note.status.statusColor(colors),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
