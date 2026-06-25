import 'package:supabase/supabase.dart';

void main() async {
  final client = SupabaseClient(
    'https://fdkswvzrozijbizdthge.supabase.co',
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZka3N3dnpyb3ppamJpemR0aGdlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njc0NzQ2MzMsImV4cCI6MjA4MzA1MDYzM30.ZENEwSy2E8iSHuy4Y4uTd7CBd32iaE-tJmSww6cw0TY',
  );

  try {
    // 1. Get info about get_product_suppliers / search_supplier_products
    final response = await client.rpc('search_supplier_products', params: {
      'query_text': '',
      'brand_filter': null,
      'category_filter': null,
      'supplier_filter': null,
      'min_price_filter': null,
      'max_price_filter': null,
    });
    print('Result from search_supplier_products:');
    if (response is List && response.isNotEmpty) {
      print('Columns: ${response.first.keys.toList()}');
      print('First row: ${response.first}');
    } else {
      print('Empty response or not a list: $response');
    }

    print('\nGetting list of functions/procedures...');
    // We can query pg_catalog to see RPC arguments
    final funcResponse = await client.from('pg_proc').select('proname, proargnames').ilike('proname', '%search_supplier_products%');
    print('pg_proc search_supplier_products: $funcResponse');
  } catch (e) {
    print('Error: $e');
  }
}
