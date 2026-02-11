// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_search_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$productSearchHash() => r'505f942b82bd9368ed9d9129eb76855bfd9f751c';

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
  ProductSearchProvider call(ProductSearchParams params) {
    return ProductSearchProvider(params);
  }

  @override
  ProductSearchProvider getProviderOverride(
    covariant ProductSearchProvider provider,
  ) {
    return call(provider.params);
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
  ProductSearchProvider(ProductSearchParams params)
    : this._internal(
        (ref) => productSearch(ref as ProductSearchRef, params),
        from: productSearchProvider,
        name: r'productSearchProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$productSearchHash,
        dependencies: ProductSearchFamily._dependencies,
        allTransitiveDependencies:
            ProductSearchFamily._allTransitiveDependencies,
        params: params,
      );

  ProductSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.params,
  }) : super.internal();

  final ProductSearchParams params;

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
        params: params,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<AggregatedProduct>> createElement() {
    return _ProductSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ProductSearchProvider && other.params == params;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, params.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ProductSearchRef
    on AutoDisposeFutureProviderRef<List<AggregatedProduct>> {
  /// The parameter `params` of this provider.
  ProductSearchParams get params;
}

class _ProductSearchProviderElement
    extends AutoDisposeFutureProviderElement<List<AggregatedProduct>>
    with ProductSearchRef {
  _ProductSearchProviderElement(super.provider);

  @override
  ProductSearchParams get params => (origin as ProductSearchProvider).params;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
