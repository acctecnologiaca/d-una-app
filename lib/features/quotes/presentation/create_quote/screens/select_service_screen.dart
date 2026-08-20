import 'package:d_una_app/shared/widgets/info_disclaimer_card.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../shared/widgets/standard_app_bar.dart';
import '../../../../../shared/widgets/custom_search_bar.dart';
import '../../../../../shared/widgets/sort_selector.dart';
import '../../../../../shared/widgets/custom_extended_fab.dart';
import '../../../../../shared/widgets/friendly_error_widget.dart';
import '../../../../../shared/utils/currency_formatter.dart';
import '../../../../portfolio/data/models/service_model.dart';
import '../providers/quote_service_selection_provider.dart';
import '../providers/create_quote_provider.dart';
import '../widgets/quote_service_selection_card.dart';
import '../widgets/quote_service_sale_details_sheet.dart';

class SelectServiceScreen extends ConsumerStatefulWidget {
  const SelectServiceScreen({super.key});

  @override
  ConsumerState<SelectServiceScreen> createState() =>
      _SelectServiceScreenState();
}

class _SelectServiceScreenState extends ConsumerState<SelectServiceScreen> {
  SortOption _currentSort = SortOption.recent;
  String? _selectedServiceId;
  double _selectedQuantity = 0.0;
  ServiceModel? _selectedService;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final suggestionsAsync = ref.watch(quoteServiceSuggestionsProvider);

    final quoteState = ref.watch(createQuoteProvider);
    final quoteNumber =
        quoteState.quote?.quoteNumber ?? quoteState.currentQuoteNumber ?? '';
    final quoteServices = quoteState.services;

    final hasSelection = _selectedQuantity > 0 && _selectedService != null;

    final formattedQty =
        _selectedQuantity.truncateToDouble() == _selectedQuantity
            ? _selectedQuantity.toInt().toString()
            : _selectedQuantity.toStringAsFixed(2);
    final totalPrice = (_selectedService?.price ?? 0.0) * _selectedQuantity;
    final formattedTotal = CurrencyFormatter.format(totalPrice);
    final rateSymbol = _selectedService?.serviceRate?.symbol ?? 'ud.';

    return Scaffold(
      appBar: StandardAppBar(
        title: 'Agregar servicio',
        subtitle: quoteNumber.isNotEmpty ? 'Cotización #$quoteNumber' : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Search Bar (Read-only -> Navigates to Search)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: InkWell(
              onTap: () {
                context.push('/quotes/create/select-service/search').then((
                  result,
                ) {
                  if (result == true) {
                    if (context.mounted) {
                      context.pop(true);
                    }
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: IgnorePointer(
                child: CustomSearchBar(
                  hintText: 'Buscar servicio...',
                  onChanged: (_) {}, // No-op, handled by onTap
                  readOnly: true,
                  showFilterIcon: true,
                ),
              ),
            ),
          ),

          // 2. Add Temporal Service Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: OutlinedButton(
              onPressed: () {
                context
                    .push('/quotes/create/select-service/temporal-service')
                    .then((result) {
                      if (result == true && context.mounted) {
                        context.pop(true);
                      }
                    });
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(color: colors.outlineVariant),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                foregroundColor: colors.onSurface,
              ),
              child: const Text(
                'Agregar servicio temporal',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),

          // 3. Disclaimer
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: const InfoDisclaimerCard(
              text: 'Precios no incluyen impuestos',
              showCloseButton: true,
            ),
          ),

          // 4. Sort Selector
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                SortSelector(
                  currentSort: _currentSort,
                  options: const [
                    SortOption.frequency,
                    SortOption.recent,
                    SortOption.nameAZ,
                    SortOption.nameZA,
                  ],
                  onSortChanged: (val) => setState(() => _currentSort = val),
                ),
              ],
            ),
          ),

          // 5. List
          Expanded(
            child: suggestionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => FriendlyErrorWidget(
                error: err,
                onRetry: () => ref.invalidate(quoteServiceSuggestionsProvider),
              ),
              data: (services) {
                // Determine sort list
                final sortedServices = List.of(services);
                sortedServices.sort((a, b) {
                  switch (_currentSort) {
                    case SortOption.recent:
                    case SortOption.frequency:
                      return b.createdAt.compareTo(a.createdAt);
                    case SortOption.nameAZ:
                      return a.name.toLowerCase().compareTo(
                        b.name.toLowerCase(),
                      );
                    case SortOption.nameZA:
                      return b.name.toLowerCase().compareTo(
                        a.name.toLowerCase(),
                      );
                    default:
                      return 0;
                  }
                });

                if (sortedServices.isEmpty) {
                  return Center(
                    child: Text(
                      'No hay servicios disponibles',
                      style: TextStyle(color: colors.outline),
                    ),
                  );
                }

                return ListView.separated(
                  //padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: sortedServices.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: Colors.transparent),
                  itemBuilder: (context, index) {
                    final service = sortedServices[index];
                    final currentQty = _selectedServiceId == service.id
                        ? _selectedQuantity
                        : 0.0;
                    final isLocked =
                        _selectedServiceId != null &&
                        _selectedServiceId != service.id;
                    final isAlreadyInQuote = quoteServices.any(
                      (s) => s.serviceId == service.id,
                    );

                    return QuoteServiceSelectionCard(
                      service: service,
                      selectedQty: currentQty,
                      isLocked: isLocked,
                      isAlreadyInQuote: isAlreadyInQuote,
                      onQtyChanged: (qty) {
                        setState(() {
                          if (qty > 0) {
                            _selectedServiceId = service.id;
                            _selectedQuantity = qty;
                            _selectedService = service;
                          } else {
                            if (_selectedServiceId == service.id) {
                              _selectedServiceId = null;
                              _selectedQuantity = 0.0;
                              _selectedService = null;
                            }
                          }
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: hasSelection
          ? Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: CustomExtendedFab(
                icon: Icons.check,
                label:
                    'Confirmar ($formattedQty $rateSymbol - $formattedTotal)',
                isEnabled: true,
                onPressed: () async {
                  if (_selectedService == null || _selectedQuantity <= 0) {
                    return;
                  }

                  final item = await QuoteServiceSaleDetailsSheet.show(
                    context,
                    service: _selectedService!,
                    selectedQuantity: _selectedQuantity,
                  );

                  if (item != null && context.mounted) {
                    ref.read(createQuoteProvider.notifier).addService(item);
                    context.pop(true);
                  }
                },
              ),
            )
          : null,
    );
  }
}

