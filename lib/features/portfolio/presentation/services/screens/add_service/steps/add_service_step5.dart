import 'package:flutter/material.dart';
import '../../../../../../../shared/widgets/wizard_bottom_bar.dart';
import '../../../../../../../shared/widgets/info_block.dart';

class AddServiceStep5 extends StatelessWidget {
  final String serviceName;
  final String category;
  final bool hasWarranty;
  final int? warrantyTime;
  final String? warrantyUnit;
  final String description;
  final double price;
  final String rateUnit;
  final bool isPriceFixed;
  final VoidCallback onBack;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  const AddServiceStep5({
    super.key,
    required this.serviceName,
    required this.category,
    required this.hasWarranty,
    this.warrantyTime,
    this.warrantyUnit,
    required this.description,
    required this.price,
    required this.rateUnit,
    required this.isPriceFixed,
    required this.onBack,
    required this.onCancel,
    required this.onSubmit,
  });

  String _getSymbol(String unit) {
    final match = RegExp(r'\((.*?)\)').firstMatch(unit);
    return match?.group(1) ?? unit;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Resúmen',
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w400,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  serviceName,
                  style: textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // Category
                InfoBlock.text(
                  icon: Icons.category_outlined,
                  label: 'Categoría',
                  value: category.isEmpty ? 'Sin categoría' : category,
                ),
                const SizedBox(height: 24),

                // Warranty
                InfoBlock.text(
                  icon: Icons.verified_outlined,
                  label: 'Tiempo de garantía',
                  value: hasWarranty
                      ? '$warrantyTime $warrantyUnit'
                      : 'No ofrezco garantía',
                ),
                const SizedBox(height: 24),

                // Description
                InfoBlock(
                  icon: Icons.description_outlined,
                  label: 'Descripción',
                  content: description.isEmpty
                      ? const Text('Sin descripción')
                      : Text(
                          description,
                          style: TextStyle(
                            fontSize: 16,
                            color: colors.onSurface,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                ),

                const SizedBox(height: 24),

                // Price
                InfoBlock(
                  icon: Icons.attach_money,
                  label: 'Precio de venta',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPriceFixed
                            ? '\$${price.toStringAsFixed(2)}/${_getSymbol(rateUnit)}'
                            : '??/${_getSymbol(rateUnit)}',
                        style: textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colors.onSurface,
                        ),
                      ),
                      if (!isPriceFixed)
                        Text(
                          'Precio variable',
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 40),
          child: WizardButtonBar(
            onCancel: onCancel,
            onBack: onBack,
            onNext: onSubmit,
            labelNext: 'Finalizar',
          ),
        ),
      ],
    );
  }
}
