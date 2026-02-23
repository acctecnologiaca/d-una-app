import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class EstimatePriceSheet extends StatefulWidget {
  final double basePrice;
  final String productName;
  final String? productModel;
  final String? productBrand;
  final String uom;

  const EstimatePriceSheet({
    super.key,
    required this.basePrice,
    required this.productName,
    this.productModel,
    this.productBrand,
    this.uom = 'ud.',
  });

  static void show(
    BuildContext context, {
    required double basePrice,
    required String productName,
    String? productModel,
    String? productBrand,
    String uom = 'ud.',
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => EstimatePriceSheet(
        basePrice: basePrice,
        productName: productName,
        productModel: productModel,
        productBrand: productBrand,
        uom: uom,
      ),
    );
  }

  @override
  State<EstimatePriceSheet> createState() => _EstimatePriceSheetState();
}

class _EstimatePriceSheetState extends State<EstimatePriceSheet> {
  double _profitPercentage = 25.0; // Default starts at 25%
  late final TextEditingController _percentageController;

  @override
  void initState() {
    super.initState();
    _percentageController = TextEditingController(
      text: _formatNumber(_profitPercentage),
    );
  }

  @override
  void dispose() {
    _percentageController.dispose();
    super.dispose();
  }

  double get _sellingPrice => widget.basePrice * (1 + _profitPercentage / 100);
  double get _profitPerUnit => _sellingPrice - widget.basePrice;

  String _formatNumber(double value) {
    // Format to 2 decimal places, replace dot with comma
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  void _updatePercentageFromText(String text) {
    if (text.isEmpty) return;
    // Parse "25,00" -> 25.00
    final sanitized = text.replaceAll(',', '.');
    final val = double.tryParse(sanitized);
    if (val != null) {
      setState(() {
        _profitPercentage = val;
      });
    }
  }

  void _increment() {
    setState(() {
      _profitPercentage += 1.0;
      _percentageController.text = _formatNumber(_profitPercentage);
    });
  }

  void _decrement() {
    setState(() {
      if (_profitPercentage > 0) {
        _profitPercentage -= 1.0;
        _percentageController.text = _formatNumber(_profitPercentage);
      }
    });
  }

  String _formatCurrency(double value) {
    final intPart = value.floor();
    final decPart = ((value - intPart) * 100).round();
    return '\$${intPart.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')},${decPart.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer, // Mimic dialog bg
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      // Use SafeArea to respect bottom nav bar/gestures
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header (Close Icon + Title)
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: colors.onSurface,
                ),
                Expanded(
                  child: Text(
                    'Estima el precio de venta',
                    textAlign: TextAlign
                        .left, // Center title as per mock? Or left? Mock seems slightly left aligned relative to X, but centered in available space. Let's start with center (or generic Title style).
                    // Actually, mock has "X   Estima el precio de venta". It looks like "Leading X, Title".
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance the icon button
              ],
            ),
            const SizedBox(height: 16),

            // Subtitle
            Text(
              'Indica que porcentaje de ganancia te gustaría sumarle al producto.',
              textAlign: TextAlign
                  .left, // Or left? Mock looks like left-ish or justified? Let's keep center for bottom sheet usually looks better, but mock text starts left aligned visualy? No, looks responsive. Let's try start alignment if it feels better, but dialog had center.
              // Mock image: Text is definitely left-aligned or justified.
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),

            // Stepper Control (Center)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Minus
                IconButton(
                  onPressed: _decrement,
                  icon: const Icon(Icons.remove),
                  color: colors.onSurface,
                ),
                const SizedBox(width: 16),

                // Value Box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surface.withValues(alpha: 0.5), // Lighter bg
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.outlineVariant),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Porcentaje',
                        style: textTheme.labelSmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '%',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colors.onSurface,
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 80,
                            child: TextField(
                              controller: _percentageController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              onChanged: _updatePercentageFromText,
                              textAlign: TextAlign.center,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              decoration: InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                                fillColor: colors.surface.withValues(
                                  alpha: 0.5,
                                ), // Lighter bg,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),
                // Plus
                IconButton(
                  onPressed: _increment,
                  icon: const Icon(Icons.add),
                  color: colors.onSurface,
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Selling Price
            Text(
              'Precio de venta',
              style: textTheme.titleMedium?.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              _formatCurrency(_sellingPrice),
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
                fontSize: 32, // Make it big
              ),
            ),

            const SizedBox(height: 16),

            // Profit
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surface.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.outlineVariant),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  /*Icon(
                    Symbols.trending_up,
                    size: 20,
                    color: colors.onSurfaceVariant,
                  ),*/
                  const SizedBox(width: 8),
                  Text(
                    'Ganancia: ',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _formatCurrency(_profitPerUnit),
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '/${widget.uom}',
                    style: textTheme.bodyLarge?.copyWith(
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Bottom Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Share Icon
                IconButton(
                  onPressed: () async {
                    final text =
                        '*Producto*\n\n'
                        '*Nombre:* ${widget.productName}\n'
                        '*Marca:* ${widget.productBrand ?? "Genérica"}\n'
                        '*Modelo:* ${widget.productModel ?? "N/A"}\n'
                        '*Precio:* ${_formatCurrency(_sellingPrice)}\n'
                        '\nLos precios no incluyen IVA y pueden variar sin previo aviso'
                        '\nEnviado desde *d·una app*';
                    await SharePlus.instance.share(
                      ShareParams(
                        text: text,
                        subject: 'Estimación de precio - ${widget.productName}',
                      ),
                    );
                  },
                  icon: const Icon(Icons.share_outlined),
                  color: colors.onSurface,
                ),
                /* const Spacer(),
               // Close Button
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                    backgroundColor: const Color(
                      0xFF335C81,
                    ), // Mock color seems dark blue
                  ),
                  child: const Text('Cerrar'),
                ),*/
              ],
            ),
          ],
        ),
      ),
    );
  }
}
