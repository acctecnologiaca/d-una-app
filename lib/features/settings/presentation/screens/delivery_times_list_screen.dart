import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:d_una_app/shared/widgets/generic_list_screen.dart';
import 'package:d_una_app/shared/widgets/standard_list_item.dart';
import 'package:d_una_app/shared/widgets/sort_selector.dart';
import 'package:d_una_app/features/portfolio/data/models/delivery_time_model.dart';
import 'package:d_una_app/features/portfolio/presentation/providers/lookup_providers.dart';
import '../widgets/add_edit_delivery_time_sheet.dart';

class DeliveryTimesListScreen extends ConsumerWidget {
  const DeliveryTimesListScreen({super.key});

  void _showAddEditSheet(BuildContext context, [DeliveryTime? deliveryTime]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) =>
          AddEditDeliveryTimeSheet(deliveryTime: deliveryTime),
    );
  }

  int _getDurationInHours(DeliveryTime t) {
    if (t.minValue == null && t.maxValue == null) return 999999;
    final val = t.maxValue ?? t.minValue ?? 0;
    switch (t.unit) {
      case 'hours':
        return val;
      case 'days':
        return val * 24;
      case 'weeks':
        return val * 24 * 7;
      case 'months':
        return val * 24 * 30;
      default:
        return val;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final timesAsync = ref.watch(deliveryTimesProvider);

    return GenericListScreen<DeliveryTime>(
      title: 'Tiempos de entrega y ejecución',
      descriptionText:
          'Configura los tiempos de entrega de productos y los tiempos de ejecución para servicios.',
      itemsAsync: timesAsync,
      emptyListMessage: 'No se encontraron configuraciones.',
      onAddPressed: () => _showAddEditSheet(context),
      sortOptions: const [
        SortOption.durationAsc,
        SortOption.durationDesc,
        SortOption.type,
        SortOption.nameAZ,
        SortOption.nameZA,
      ],
      initialSort: SortOption.durationAsc,
      onSearch: (item, query) =>
          item.name.toLowerCase().contains(query.toLowerCase()),
      onSort: (a, b, sort) {
        if (sort == SortOption.nameZA) {
          return b.name.compareTo(a.name);
        } else if (sort == SortOption.durationAsc) {
          return _getDurationInHours(a).compareTo(_getDurationInHours(b));
        } else if (sort == SortOption.durationDesc) {
          return _getDurationInHours(b).compareTo(_getDurationInHours(a));
        } else if (sort == SortOption.type) {
          return a.type.compareTo(b.type);
        }
        return a.name.compareTo(b.name);
      },
      itemBuilder: (context, time) {
        final bool canEdit = !time.isVerified;

        return Opacity(
          opacity: canEdit ? 1.0 : 0.5,
          child: StandardListItem(
            title: time.name,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (time.type == 'delivery' || time.type == 'both')
                  Icon(
                    Icons.local_shipping_outlined,
                    color: colors.onSurfaceVariant,
                  ),
                if (time.type == 'both') const SizedBox(width: 8),
                if (time.type == 'execution' || time.type == 'both')
                  Icon(Icons.timer_outlined, color: colors.onSurfaceVariant),
                if (time.isVerified) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.verified,
                    size: 20,
                    color: colors.primary.withValues(alpha: 0.5),
                  ),
                ],
              ],
            ),
            onTap: () {
              if (canEdit) {
                _showAddEditSheet(context, time);
              } else {
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      duration: const Duration(seconds: 5),
                      content: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Este es un ajuste verificado, no puede ser modificado.',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.white,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () => ScaffoldMessenger.of(
                              context,
                            ).hideCurrentSnackBar(),
                          ),
                        ],
                      ),
                    ),
                  );
              }
            },
          ),
        );
      },
    );
  }
}
