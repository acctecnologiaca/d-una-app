import 'package:flutter/material.dart';
import '../../../features/portfolio/data/models/service_model.dart';
import '../../shared/utils/currency_formatter.dart';
import 'standard_list_item.dart';
import 'uom_status_badge.dart';

class ServiceListItem extends StatelessWidget {
  final ServiceModel service;
  final VoidCallback onTap;
  final bool isAlreadyAdded;

  const ServiceListItem({
    super.key,
    required this.service,
    required this.onTap,
    this.isAlreadyAdded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAlreadyAdded ? 0.5 : 1.0,
      child: StandardListItem(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        onTap: onTap,
        overline:
            (service.category?.name != null &&
                service.category!.name.isNotEmpty)
            ? Text(service.category!.name)
            : const Text('Sin categoría'),
        title: service.name,
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              CurrencyFormatter.format(service.price),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            UomStatusBadge(
              quantity: 0,
              showQuantity: false,
              uomAbbreviation: service.serviceRate?.symbol ?? 'ud.',
              uomIconName: service.serviceRate?.iconName,
            ),
          ],
        ),
      ),
    );
  }
}
