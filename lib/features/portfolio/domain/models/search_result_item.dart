import 'package:d_una_app/features/portfolio/domain/models/supplier_model.dart';
import 'package:d_una_app/features/portfolio/domain/models/aggregated_product.dart';

/// A union class to hold either a Supplier or an AggregatedProduct
/// for the unified search screen.
sealed class SearchResultItem {
  const SearchResultItem();
}

class SupplierResultItem extends SearchResultItem {
  final Supplier supplier;
  const SupplierResultItem(this.supplier);
}

class ProductResultItem extends SearchResultItem {
  final AggregatedProduct product;
  const ProductResultItem(this.product);
}

class HeaderResultItem extends SearchResultItem {
  final String title;
  const HeaderResultItem(this.title);
}

class DividerResultItem extends SearchResultItem {
  const DividerResultItem();
}
