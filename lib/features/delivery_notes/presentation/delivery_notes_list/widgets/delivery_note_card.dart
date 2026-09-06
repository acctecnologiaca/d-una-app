import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:d_una_app/shared/widgets/standard_list_item.dart';
import 'package:d_una_app/shared/utils/currency_formatter.dart';
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
    final textTheme = Theme.of(context).textTheme;
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? colors.primaryContainer.withValues(alpha: 0.3)
            : null,
      ),
      child: StandardListItem(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        onTap: onTap,
        onLongPress: onLongPress,
        overline: Text(
          '${note.deliveryNoteNumber} (${dateFormat.format(note.date)})',
        ),
        title: note.clientName,
        subtitle: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (note.tag != null && note.tag!.isNotEmpty)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.label_outline, size: 14),
                  const SizedBox(width: 3),
                  Text(
                    note.tag!,
                    style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                  ),
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
            if (note.itemsCount > 0)
              Text(
                '${note.itemsCount} ${note.itemsCount == 1 ? "ítem" : "ítems"}',
                style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
              ),
          ],
        ),
        trailing: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              CurrencyFormatter.format(note.totalAmount),
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            if (isSelectionMode)
              Checkbox(
                value: isSelected,
                onChanged: (_) => onTap?.call(),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: note.status.statusColor(colors).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: note.status.statusColor(colors).withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      note.status.iconData,
                      size: 13,
                      color: note.status.statusColor(colors),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      note.status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: note.status.statusColor(colors),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
