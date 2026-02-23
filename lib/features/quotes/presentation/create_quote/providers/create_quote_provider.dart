import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/models.dart';
import '../../../domain/repositories/quotes_repository.dart';
import '../../quotes_list/providers/quotes_provider.dart';

class QuoteState {
  final Quote? quote; // The final object being built
  final List<QuoteItemProduct> products;
  final List<QuoteItemService> services;
  final List<QuoteCondition> conditions;
  final String? clientId;
  final String? clientName; // For UI display
  final bool isLoading;
  final String? error;

  // Financial Context
  final double globalMargin;
  final double globalTaxRate;

  QuoteState({
    this.quote,
    this.products = const [],
    this.services = const [],
    this.conditions = const [],
    this.clientId,
    this.clientName,
    this.isLoading = false,
    this.error,
    this.globalMargin = 0.30,
    this.globalTaxRate = 0.16,
  });

  QuoteState copyWith({
    Quote? quote,
    List<QuoteItemProduct>? products,
    List<QuoteItemService>? services,
    List<QuoteCondition>? conditions,
    String? clientId,
    String? clientName,
    bool? isLoading,
    String? error,
    double? globalMargin,
    double? globalTaxRate,
  }) {
    return QuoteState(
      quote: quote ?? this.quote,
      products: products ?? this.products,
      services: services ?? this.services,
      conditions: conditions ?? this.conditions,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      globalMargin: globalMargin ?? this.globalMargin,
      globalTaxRate: globalTaxRate ?? this.globalTaxRate,
    );
  }
}

class CreateQuoteNotifier extends StateNotifier<QuoteState> {
  final QuotesRepository _repository;

  CreateQuoteNotifier(this._repository) : super(QuoteState()) {
    _loadFinancialDefaults();
  }

  Future<void> _loadFinancialDefaults() async {
    try {
      state = state.copyWith(isLoading: true);
      final params = await _repository.getFinancialParameters();
      state = state.copyWith(
        globalMargin: params.profitMargin,
        globalTaxRate: params.taxRate,
        isLoading: false,
      );
    } catch (e) {
      // Fallback to defaults in constructor if fetch fails
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  // --- Product Management ---
  void addProduct(QuoteItemProduct product) {
    state = state.copyWith(products: [...state.products, product]);
  }

  void removeProduct(String id) {
    state = state.copyWith(
      products: state.products.where((p) => p.id != id).toList(),
    );
  }

  // --- Service Management ---
  void addService(QuoteItemService service) {
    state = state.copyWith(services: [...state.services, service]);
  }

  void removeService(String id) {
    state = state.copyWith(
      services: state.services.where((s) => s.id != id).toList(),
    );
  }

  // --- Client Management ---
  void selectClient(String id, String name) {
    state = state.copyWith(clientId: id, clientName: name);
  }

  // --- Final Creation ---
  Future<bool> createQuote() async {
    if (state.clientId == null) {
      state = state.copyWith(error: "Selecciona un cliente");
      return false;
    }

    // Logic to assemble Quote object and call repository
    // ...
    return true;
  }
}

final createQuoteProvider =
    StateNotifierProvider<CreateQuoteNotifier, QuoteState>((ref) {
      final repository = ref.watch(quotesRepositoryProvider);
      return CreateQuoteNotifier(repository);
    });
