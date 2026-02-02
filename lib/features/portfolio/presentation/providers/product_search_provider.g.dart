// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$productSearchHash() => r'f70989d751e1cd9e09d73a5935e97ac34448de40';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [productSearch].
@ProviderFor(productSearch)
const productSearchProvider = ProductSearchFamily();

/// See also [productSearch].
class ProductSearchFamily extends Family<AsyncValue<List<AggregatedProduct>>> {
  /// See also [productSearch].
  const ProductSearchFamily();

  /// See also [productSearch].
  ProductSearchProvider call(String query) {
    return ProductSearchProvider(query);
  }

  @override
  ProductSearchProvider getProviderOverride(
    covariant ProductSearchProvider provider,
  ) {
    return call(provider.query);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'productSearchProvider';
}

/// See also [productSearch].
class ProductSearchProvider
    extends AutoDisposeFutureProvider<List<AggregatedProduct>> {
  /// See also [productSearch].
  ProductSearchProvider(String query)
    : this._internal(
        (ref) => productSearch(ref as ProductSearchRef, query),
        from: productSearchProvider,
        name: r'productSearchProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$productSearchHash,
        dependencies: ProductSearchFamily._dependencies,
        allTransitiveDependencies:
            ProductSearchFamily._allTransitiveDependencies,
        query: query,
      );

  ProductSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<AggregatedProduct>> Function(ProductSearchRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ProductSearchProvider._internal(
        (ref) => create(ref as ProductSearchRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<AggregatedProduct>> createElement() {
    return _ProductSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductSearchProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProductSearchRef
    on AutoDisposeFutureProviderRef<List<AggregatedProduct>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _ProductSearchProviderElement
    extends AutoDisposeFutureProviderElement<List<AggregatedProduct>>
    with ProductSearchRef {
  _ProductSearchProviderElement(super.provider);

  @override
  String get query => (origin as ProductSearchProvider).query;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
