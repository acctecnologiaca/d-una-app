import 'package:flutter/material.dart';
import '../../../../../../shared/utils/currency_formatter.dart';
import '../../../../../../shared/widgets/standard_list_item.dart';

class ServiceItemCard extends StatelessWidget {
  final String name;
  final String? category;
  final double price;
  final String priceUnit;
  final VoidCallback onTap;

  const ServiceItemCard({
    super.key,
    required this.name,
    this.category,
    required this.price,
    required this.priceUnit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return StandardListItem(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      onTap: onTap,
      overline: (category != null && category!.isNotEmpty)
          ? Text(category!)
          : null,
      title: name,
      trailing: Text(
        '${CurrencyFormatter.format(price)}/${_getShortUnit(priceUnit)}',
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _getShortUnit(String unit) {
    final match = RegExp(r'\((.*?)\)').firstMatch(unit);
    return match?.group(1) ?? unit;
  }
}
