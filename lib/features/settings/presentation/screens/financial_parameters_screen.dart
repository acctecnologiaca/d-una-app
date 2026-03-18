import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:d_una_app/shared/widgets/standard_app_bar.dart';
import 'package:d_una_app/shared/widgets/custom_stepper.dart';
import 'package:d_una_app/shared/widgets/custom_dropdown.dart';
import 'package:d_una_app/shared/widgets/form_bottom_bar.dart';
import 'package:d_una_app/shared/data/currencies.dart';
import 'package:d_una_app/features/quotes/data/models/financial_parameter.dart';
import 'package:d_una_app/features/quotes/presentation/quotes_list/providers/quotes_provider.dart';
import 'package:d_una_app/features/quotes/presentation/create_quote/providers/create_quote_provider.dart';

class FinancialParametersScreen extends ConsumerStatefulWidget {
  const FinancialParametersScreen({super.key});

  @override
  ConsumerState<FinancialParametersScreen> createState() =>
      _FinancialParametersScreenState();
}

class _FinancialParametersScreenState
    extends ConsumerState<FinancialParametersScreen> {
  final _marginController = TextEditingController();
  final _taxController = TextEditingController();

  double _profitMargin = 20.0;
  double _taxRate = 16.0;
  String _currencyCode = 'USD';
  String _pricingMethod = 'margin';
  String? _parameterId;

  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanged = false;

  // Track originals for change detection
  double _origMargin = 20.0;
  double _origTax = 16.0;
  String _origCurrency = 'USD';
  String _origMethod = 'margin';

  @override
  void initState() {
    super.initState();
    _loadParameters();
  }

  @override
  void dispose() {
    _marginController.dispose();
    _taxController.dispose();
    super.dispose();
  }

  Future<void> _loadParameters() async {
    try {
      final repo = ref.read(quotesRepositoryProvider);
      final params = await repo.getFinancialParameters();
      setState(() {
        _parameterId = params.id.isEmpty ? null : params.id;
        _profitMargin = params.profitMargin;
        _taxRate = params.taxRate;
        _currencyCode = params.currencyCode;
        _pricingMethod = params.pricingMethod;

        _origMargin = _profitMargin;
        _origTax = _taxRate;
        _origCurrency = _currencyCode;
        _origMethod = _pricingMethod;

        _marginController.text = _formatNumber(_profitMargin);
        _taxController.text = _formatNumber(_taxRate);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _marginController.text = _formatNumber(_profitMargin);
        _taxController.text = _formatNumber(_taxRate);
        _isLoading = false;
      });
    }
  }

  String _formatNumber(double value) {
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }

  void _checkChanged() {
    final changed =
        _profitMargin != _origMargin ||
        _taxRate != _origTax ||
        _currencyCode != _origCurrency ||
        _pricingMethod != _origMethod;
    if (_hasChanged != changed) {
      setState(() => _hasChanged = changed);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      final repo = ref.read(quotesRepositoryProvider);
      final params = FinancialParameter(
        id: _parameterId ?? '',
        profitMargin: _profitMargin,
        taxRate: _taxRate,
        currencyCode: _currencyCode,
        pricingMethod: _pricingMethod,
        updatedAt: DateTime.now(),
      );
      await repo.updateFinancialParameters(params);
      // Refresh global state
      ref.read(createQuoteProvider.notifier).loadFinancialParameters();
      navigator.pop(true);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Parámetros financieros actualizados')),
      );
    } catch (e) {
      setState(() => _isSaving = false);
      scaffoldMessenger.showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    if (_isLoading) {
      return Scaffold(
        appBar: const StandardAppBar(title: 'Parámetros financieros'),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: const StandardAppBar(title: 'Parámetros financieros'),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Establece los parametros financieros por defecto que usarás en tus cotizaciones o reportes de servicios.',
            style: textTheme.bodyMedium?.copyWith(
              color: colors.onSurface,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // ── Márgenes ──────────────────────────────────────────────
          _buildSectionTitle('Ganancia', textTheme, colors),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Márgen de ganancia por defecto',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              CustomStepper(
                controller: _marginController,
                label: 'Porcentaje',
                prefixText: '%',
                onChanged: (value) {
                  final val = double.tryParse(value.replaceAll(',', '.'));
                  if (val != null) {
                    _profitMargin = val;
                    _checkChanged();
                  }
                },
                onIncrement: () {
                  setState(() {
                    _profitMargin += 1;
                    _marginController.text = _formatNumber(_profitMargin);
                    _checkChanged();
                  });
                },
                onDecrement: () {
                  if (_profitMargin >= 1) {
                    setState(() {
                      _profitMargin -= 1;
                      _marginController.text = _formatNumber(_profitMargin);
                      _checkChanged();
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Método de fijación de precios
          CustomDropdown<String>(
            value: _pricingMethod,
            items: const ['markup', 'margin'],
            label: 'Método de fijación de precios',
            itemLabelBuilder: (value) {
              switch (value) {
                case 'markup':
                  return 'Sobre el costo (Markup)';
                case 'margin':
                  return 'Sobre el precio de venta (Margen)';
                default:
                  return value;
              }
            },
            onChanged: (val) {
              if (val != null) {
                setState(() => _pricingMethod = val);
                _checkChanged();
              }
            },
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (_) {
              final symbol = availableCurrencies
                  .firstWhere(
                    (c) => c.code == _currencyCode,
                    orElse: () => const Currency(
                      code: 'USD',
                      name: 'Estados Unidos',
                      symbol: '\$',
                    ),
                  )
                  .symbol;
              final pct = _profitMargin.toStringAsFixed(0);
              double resultPrice;
              if (_pricingMethod == 'markup') {
                resultPrice = 100 * (1 + _profitMargin / 100);
              } else {
                final factor = 1 - (_profitMargin / 100);
                resultPrice = factor > 0 ? 100 / factor : 100;
              }
              final priceStr = resultPrice
                  .toStringAsFixed(2)
                  .replaceAll('.', ',');
              final text = _pricingMethod == 'markup'
                  ? 'Ej: Si tu costo es ${symbol}100 y aplicas $pct%, tu precio de venta ser\u00e1 $symbol$priceStr. La ganancia representa el $pct% del costo.'
                  : 'Ej: Si tu costo es ${symbol}100 y aplicas $pct%, tu precio de venta ser\u00e1 $symbol$priceStr. La ganancia representa el $pct% del precio de venta.';
              return Text(
                text,
                textAlign: TextAlign.center,
                style: textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontStyle: FontStyle.italic,
                  color: colors.onSurfaceVariant,
                ),
              );
            },
          ),
          const SizedBox(height: 32),

          // ── Impuestos ─────────────────────────────────────────────
          _buildSectionTitle('Impuestos', textTheme, colors),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Impuesto al valor agregado (IVA)',
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.onSurface,
                  ),
                ),
              ),
              CustomStepper(
                controller: _taxController,
                label: 'Porcentaje',
                prefixText: '%',
                onChanged: (value) {
                  final val = double.tryParse(value.replaceAll(',', '.'));
                  if (val != null) {
                    _taxRate = val;
                    _checkChanged();
                  }
                },
                onIncrement: () {
                  setState(() {
                    _taxRate += 1;
                    _taxController.text = _formatNumber(_taxRate);
                    _checkChanged();
                  });
                },
                onDecrement: () {
                  if (_taxRate >= 1) {
                    setState(() {
                      _taxRate -= 1;
                      _taxController.text = _formatNumber(_taxRate);
                      _checkChanged();
                    });
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 32),

          // ── Moneda ────────────────────────────────────────────────
          _buildSectionTitle('Moneda', textTheme, colors),
          const SizedBox(height: 16),

          CustomDropdown<String>(
            value: _currencyCode,
            searchable: true,
            items: availableCurrencies.map((c) => c.code).toList(),
            label: 'Tipo de moneda',
            itemLabelBuilder: (code) {
              final currency = availableCurrencies.firstWhere(
                (c) => c.code == code,
                orElse: () => const Currency(
                  code: 'USD',
                  name: 'Estados Unidos',
                  symbol: '\$',
                ),
              );
              return currency.displayLabel;
            },
            onChanged: (val) {
              if (val != null) {
                setState(() => _currencyCode = val);
                _checkChanged();
              }
            },
          ),
          const SizedBox(height: 48),

          // ── Bottom Bar ────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom > 0
                  ? MediaQuery.of(context).padding.bottom
                  : 40.0,
            ),
            child: FormBottomBar(
              onCancel: () => context.pop(),
              onSave: _hasChanged ? _save : null,
              isSaveEnabled: _hasChanged,
              isLoading: _isSaving,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    String title,
    TextTheme textTheme,
    ColorScheme colors,
  ) {
    return Text(
      title,
      style: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.bold,
        color: colors.onSurface,
      ),
    );
  }
}
