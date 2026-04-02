import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../portfolio/presentation/providers/product_search_provider.dart';
import '../../domain/models/quote_aggregated_product.dart';
import '../../domain/models/quote_product_source.dart';

class QuoteProductSelectionRepository {
  final SupabaseClient _supabase;

  QuoteProductSelectionRepository(this._supabase);

  Future<List<QuoteAggregatedProduct>> getQuoteProducts([
    ProductSearchParams? params,
  ]) async {
    final Map<String, dynamic> rpcParams = {};

    if (params != null) {
      if (params.query.isNotEmpty) rpcParams['query_text'] = params.query;
      if (params.filters.brands.isNotEmpty) {
        rpcParams['brand_filter'] = params.filters.brands.toList();
      }
      if (params.filters.categories.isNotEmpty) {
        rpcParams['category_filter'] = params.filters.categories.toList();
      }
      if (params.filters.supplierIds.isNotEmpty) {
        rpcParams['supplier_filter'] = params.filters.supplierIds.toList();
      }
      if (params.filters.minPrice != null) {
        rpcParams['min_price_filter'] = params.filters.minPrice;
      }
      if (params.filters.maxPrice != null) {
        rpcParams['max_price_filter'] = params.filters.maxPrice;
      }
    }

    final response = await _supabase.rpc(
      'get_quote_products',
      params: rpcParams.isNotEmpty ? rpcParams : null,
    );
    return (response as List)
        .map((item) => QuoteAggregatedProduct.fromMap(item))
        .toList();
  }

  Future<List<QuoteProductSource>> getProductSources({
    required String name,
    required String brand,
    required String model,
    required String uom,
  }) async {
    final response = await _supabase.rpc(
      'get_product_sources',
      params: {
        'p_name': name,
        'p_brand': brand,
        'p_model': model,
        'p_uom': uom,
      },
    );
    return (response as List)
        .map((item) => QuoteProductSource.fromMap(item))
        .toList();
  }
}
