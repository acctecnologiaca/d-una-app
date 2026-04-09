import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../quotes/presentation/create_quote/providers/create_quote_provider.dart';
import '../../../../shared/widgets/custom_action_sheet.dart';
import '../../../../shared/widgets/custom_stepper.dart';

class EstimatePriceSheet extends ConsumerStatefulWidget {
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: EstimatePriceSheet(
          basePrice: basePrice,
          productName: productName,
          productModel: productModel,
          productBrand: productBrand,
          uom: uom,
        ),
      ),
    );
  }

  @override
  ConsumerState<EstimatePriceSheet> createState() => _EstimatePriceSheetState();
}

class _EstimatePriceSheetState extends ConsumerState<EstimatePriceSheet> {
  double _profitPercentage = 25.0; // Default will be overwritten in initState
  late final TextEditingController _percentageController;
  late String _pricingMethod;
  bool _isEdited = false;

  @override
  void initState() {
    super.initState();
    final quoteState = ref.read(createQuoteProvider);
    _profitPercentage = quoteState.globalMargin;
    _pricingMethod = quoteState.pricingMethod;
    _percentageController = TextEditingController(
      text: _formatNumber(_profitPercentage),
    );
  }

  @override
  void dispose() {
    _percentageController.dispose();
    super.dispose();
  }

  double get _sellingPrice {
    if (_pricingMethod == 'margin') {
      // Margin: price = cost / (1 - %/100)
      final factor = 1 - (_profitPercentage / 100);
      return factor > 0 ? widget.basePrice / factor : widget.basePrice;
    }
    // Markup: price = cost * (1 + %/100)
    return widget.basePrice * (1 + _profitPercentage / 100);
  }

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
        _isEdited = true;
        _profitPercentage = val;
      });
    }
  }

  void _increment() {
    setState(() {
      _isEdited = true;
      _profitPercentage += 1.0;
      _percentageController.text = _formatNumber(_profitPercentage);
    });
  }

  void _decrement() {
    setState(() {
      if (_profitPercentage > 0) {
        _isEdited = true;
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
    ref.listen<QuoteState>(createQuoteProvider, (previous, next) {
      // If was loading and finished, or if it was the first load and we have defaults
      if ((previous == null || previous.isLoading) && !next.isLoading) {
        if (!_isEdited) {
          setState(() {
            _profitPercentage = next.globalMargin;
            _percentageController.text = _formatNumber(_profitPercentage);
            _pricingMethod = next.pricingMethod;
          });
        }
      }
    });

    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final textTheme = theme.textTheme;

    return CustomActionSheet(
      title: 'Estima el precio de venta',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Subtitle
          Text(
            'Indica que porcentaje de ganancia te gustaría sumarle al producto.',
            textAlign: TextAlign.left,
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),

          // Stepper Control (Center)
          Center(
            child: CustomStepper(
              controller: _percentageController,
              label: 'Porcentaje',
              prefixText: '%',
              onChanged: _updatePercentageFromText,
              onIncrement: _increment,
              onDecrement: _decrement,
            ),
          ),

          const SizedBox(height: 24),

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
              color: colors.surface.withAlpha(128), // approx 0.5
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Ganancia: ',
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.onSurface,
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
          const SizedBox(height: 24),
        ],
      ),
      actions: [
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
          ],
        ),
      ],
    );
  }
}
