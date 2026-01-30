import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:share_plus/share_plus.dart';

class EstimatePriceDialog extends StatefulWidget {
  final double basePrice;
  final String productName;
  final String? productModel;
  final String? productBrand;

  const EstimatePriceDialog({
    super.key,
    required this.basePrice,
    required this.productName,
    this.productModel,
    this.productBrand,
  });

  @override
  State<EstimatePriceDialog> createState() => _EstimatePriceDialogState();
}

class _EstimatePriceDialogState extends State<EstimatePriceDialog> {
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
    // Simple formatter. Ideally use NumberFormat.
    final intPart = value.floor();
    final decPart = ((value - intPart) * 100).round();
    return '\$${intPart.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')},${decPart.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: colors.surfaceContainer, // Light grey/blueish bg
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Icon(
              Symbols.sell, // Tag icon
              size: 32,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              'Estima tu precio\nde venta',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight:
                    FontWeight.w400, // Regular/light headline provided in mock
                color: colors.onSurface,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              'Indica que porcentaje de ganancia te gustaría sumarle al producto.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Stepper Control
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Minus Button
                IconButton(
                  onPressed: _decrement,
                  icon: const Icon(Icons.remove),
                  color: colors.onSurface,
                ),

                // Value Display Box
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: colors.surfaceContainerHighest.withOpacity(0.5),
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
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '%',
                            style: textTheme.titleMedium?.copyWith(
                              color: colors.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Editable Text Field
                          ConstrainedBox(
                            constraints: const BoxConstraints(
                              minWidth: 80,
                              maxWidth: 100,
                            ), // Accommodate ~6 chars + comma
                            child: IntrinsicWidth(
                              child: TextField(
                                controller: _percentageController,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                onChanged: _updatePercentageFromText,
                                style: textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colors.onSurface,
                                ),
                                decoration: const InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
                                ),
                                textAlign:
                                    TextAlign.center, // To mimick the prev look
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Plus Button
                IconButton(
                  onPressed: _increment,
                  icon: const Icon(Icons.add),
                  color: colors.onSurface,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Selling Price Label
            Text(
              'Precio de venta',
              style: textTheme.titleLarge?.copyWith(
                color: colors.onSurface,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 8),

            // Selling Price Value
            Text(
              _formatCurrency(_sellingPrice),
              style: textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 16),

            // Profit Label
            RichText(
              text: TextSpan(
                style: textTheme.bodyMedium,
                children: [
                  WidgetSpan(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: Icon(
                        Symbols.trending_up,
                        size: 24,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    alignment: PlaceholderAlignment.middle,
                  ),
                  TextSpan(
                    text: 'Ganancia: ',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  TextSpan(
                    text: '${_formatCurrency(_profitPerUnit)}/ud.',
                    style: TextStyle(
                      color: Colors.green[700], // Green for profit
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Share Button (Left/Start) or Right? User asked for bottom right corner relative to what?
                // "abajo en la esquina inferior derecha" -> usually next to Close or instead of it?
                // Standard dialogs have actions on the bottom right.
                // Let's put Share and Close in a Row.

                // Oops, user said "abajo en la esquina inferior derecha".
                // Currently 'Close' is at `Alignment.centerRight`.
                // Maybe put Share next to it?

                // Let's use a standard Row for actions.
                IconButton(
                  onPressed: () {
                    final text =
                        '*Producto*\n\n'
                        '*Nombre:* ${widget.productName}\n'
                        '*Marca:* ${widget.productBrand ?? "Genérica"}\n'
                        '*Modelo:* ${widget.productModel ?? "N/A"}\n'
                        '*Precio:* ${_formatCurrency(_sellingPrice)}\n'
                        '\nLos precios no incluyen IVA y pueden variar sin previo aviso'
                        '\nEnviado desde *D-Una App*';
                    Share.share(text);
                  },
                  icon: const Icon(Icons.share, size: 24),
                  tooltip: 'Compartir',
                ),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
