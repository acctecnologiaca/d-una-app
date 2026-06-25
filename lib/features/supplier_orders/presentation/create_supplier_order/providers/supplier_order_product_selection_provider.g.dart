// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_order_product_selection_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$supplierOrderProductSuggestionsHash() =>
    r'cace72bc114e52c6d1bf9241b682b1a897e32c02';

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

/// See also [supplierOrderProductSuggestions].
@ProviderFor(supplierOrderProductSuggestions)
const supplierOrderProductSuggestionsProvider =
    SupplierOrderProductSuggestionsFamily();

/// See also [supplierOrderProductSuggestions].
class SupplierOrderProductSuggestionsFamily
    extends Family<AsyncValue<List<AggregatedProduct>>> {
  /// See also [supplierOrderProductSuggestions].
  const SupplierOrderProductSuggestionsFamily();

  /// See also [supplierOrderProductSuggestions].
  SupplierOrderProductSuggestionsProvider call({
    required String supplierId,
    String query = '',
  }) {
    return SupplierOrderProductSuggestionsProvider(
      supplierId: supplierId,
      query: query,
    );
  }

  @override
  SupplierOrderProductSuggestionsProvider getProviderOverride(
    covariant SupplierOrderProductSuggestionsProvider provider,
  ) {
    return call(supplierId: provider.supplierId, query: provider.query);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'supplierOrderProductSuggestionsProvider';
}

/// See also [supplierOrderProductSuggestions].
class SupplierOrderProductSuggestionsProvider
    extends AutoDisposeFutureProvider<List<AggregatedProduct>> {
  /// See also [supplierOrderProductSuggestions].
  SupplierOrderProductSuggestionsProvider({
    required String supplierId,
    String query = '',
  }) : this._internal(
         (ref) => supplierOrderProductSuggestions(
           ref as SupplierOrderProductSuggestionsRef,
           supplierId: supplierId,
           query: query,
         ),
         from: supplierOrderProductSuggestionsProvider,
         name: r'supplierOrderProductSuggestionsProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$supplierOrderProductSuggestionsHash,
         dependencies: SupplierOrderProductSuggestionsFamily._dependencies,
         allTransitiveDependencies:
             SupplierOrderProductSuggestionsFamily._allTransitiveDependencies,
         supplierId: supplierId,
         query: query,
       );

  SupplierOrderProductSuggestionsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.supplierId,
    required this.query,
  }) : super.internal();

  final String supplierId;
  final String query;

  @override
  Override overrideWith(
    FutureOr<List<AggregatedProduct>> Function(
      SupplierOrderProductSuggestionsRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SupplierOrderProductSuggestionsProvider._internal(
        (ref) => create(ref as SupplierOrderProductSuggestionsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        supplierId: supplierId,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<AggregatedProduct>> createElement() {
    return _SupplierOrderProductSuggestionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SupplierOrderProductSuggestionsProvider &&
        other.supplierId == supplierId &&
        other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, supplierId.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SupplierOrderProductSuggestionsRef
    on AutoDisposeFutureProviderRef<List<AggregatedProduct>> {
  /// The parameter `supplierId` of this provider.
  String get supplierId;

  /// The parameter `query` of this provider.
  String get query;
}

class _SupplierOrderProductSuggestionsProviderElement
    extends AutoDisposeFutureProviderElement<List<AggregatedProduct>>
    with SupplierOrderProductSuggestionsRef {
  _SupplierOrderProductSuggestionsProviderElement(super.provider);

  @override
  String get supplierId =>
      (origin as SupplierOrderProductSuggestionsProvider).supplierId;
  @override
  String get query => (origin as SupplierOrderProductSuggestionsProvider).query;
}

String _$supplierOrderProductBranchesHash() =>
    r'0a307a6d20fda674885e8cd51f5e43f4ad30cb72';

/// See also [supplierOrderProductBranches].
@ProviderFor(supplierOrderProductBranches)
const supplierOrderProductBranchesProvider =
    SupplierOrderProductBranchesFamily();

/// See also [supplierOrderProductBranches].
class SupplierOrderProductBranchesFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [supplierOrderProductBranches].
  const SupplierOrderProductBranchesFamily();

  /// See also [supplierOrderProductBranches].
  SupplierOrderProductBranchesProvider call({
    required String supplierId,
    required AggregatedProduct product,
  }) {
    return SupplierOrderProductBranchesProvider(
      supplierId: supplierId,
      product: product,
    );
  }

  @override
  SupplierOrderProductBranchesProvider getProviderOverride(
    covariant SupplierOrderProductBranchesProvider provider,
  ) {
    return call(supplierId: provider.supplierId, product: provider.product);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'supplierOrderProductBranchesProvider';
}

/// See also [supplierOrderProductBranches].
class SupplierOrderProductBranchesProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [supplierOrderProductBranches].
  SupplierOrderProductBranchesProvider({
    required String supplierId,
    required AggregatedProduct product,
  }) : this._internal(
         (ref) => supplierOrderProductBranches(
           ref as SupplierOrderProductBranchesRef,
           supplierId: supplierId,
           product: product,
         ),
         from: supplierOrderProductBranchesProvider,
         name: r'supplierOrderProductBranchesProvider',
         debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
             ? null
             : _$supplierOrderProductBranchesHash,
         dependencies: SupplierOrderProductBranchesFamily._dependencies,
         allTransitiveDependencies:
             SupplierOrderProductBranchesFamily._allTransitiveDependencies,
         supplierId: supplierId,
         product: product,
       );

  SupplierOrderProductBranchesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.supplierId,
    required this.product,
  }) : super.internal();

  final String supplierId;
  final AggregatedProduct product;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(
      SupplierOrderProductBranchesRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SupplierOrderProductBranchesProvider._internal(
        (ref) => create(ref as SupplierOrderProductBranchesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        supplierId: supplierId,
        product: product,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _SupplierOrderProductBranchesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SupplierOrderProductBranchesProvider &&
        other.supplierId == supplierId &&
        other.product == product;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, supplierId.hashCode);
    hash = _SystemHash.combine(hash, product.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SupplierOrderProductBranchesRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `supplierId` of this provider.
  String get supplierId;

  /// The parameter `product` of this provider.
  AggregatedProduct get product;
}

class _SupplierOrderProductBranchesProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with SupplierOrderProductBranchesRef {
  _SupplierOrderProductBranchesProviderElement(super.provider);

  @override
  String get supplierId =>
      (origin as SupplierOrderProductBranchesProvider).supplierId;
  @override
  AggregatedProduct get product =>
      (origin as SupplierOrderProductBranchesProvider).product;
}

String _$branchProductKeysHash() => r'613884f596c6825ffb91238424dbd88dd713c3c2';

/// See also [branchProductKeys].
@ProviderFor(branchProductKeys)
const branchProductKeysProvider = BranchProductKeysFamily();

/// See also [branchProductKeys].
class BranchProductKeysFamily extends Family<AsyncValue<Set<String>>> {
  /// See also [branchProductKeys].
  const BranchProductKeysFamily();

  /// See also [branchProductKeys].
  BranchProductKeysProvider call(String branchId) {
    return BranchProductKeysProvider(branchId);
  }

  @override
  BranchProductKeysProvider getProviderOverride(
    covariant BranchProductKeysProvider provider,
  ) {
    return call(provider.branchId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'branchProductKeysProvider';
}

/// See also [branchProductKeys].
class BranchProductKeysProvider extends AutoDisposeFutureProvider<Set<String>> {
  /// See also [branchProductKeys].
  BranchProductKeysProvider(String branchId)
    : this._internal(
        (ref) => branchProductKeys(ref as BranchProductKeysRef, branchId),
        from: branchProductKeysProvider,
        name: r'branchProductKeysProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$branchProductKeysHash,
        dependencies: BranchProductKeysFamily._dependencies,
        allTransitiveDependencies:
            BranchProductKeysFamily._allTransitiveDependencies,
        branchId: branchId,
      );

  BranchProductKeysProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.branchId,
  }) : super.internal();

  final String branchId;

  @override
  Override overrideWith(
    FutureOr<Set<String>> Function(BranchProductKeysRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BranchProductKeysProvider._internal(
        (ref) => create(ref as BranchProductKeysRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        branchId: branchId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Set<String>> createElement() {
    return _BranchProductKeysProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BranchProductKeysProvider && other.branchId == branchId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, branchId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin BranchProductKeysRef on AutoDisposeFutureProviderRef<Set<String>> {
  /// The parameter `branchId` of this provider.
  String get branchId;
}

class _BranchProductKeysProviderElement
    extends AutoDisposeFutureProviderElement<Set<String>>
    with BranchProductKeysRef {
  _BranchProductKeysProviderElement(super.provider);

  @override
  String get branchId => (origin as BranchProductKeysProvider).branchId;
}

String _$paginatedSupplierOrderProductSearchHash() =>
    r'5b010aa901b5a52a920aa8ff71e006deb2666c0d';

/// See also [PaginatedSupplierOrderProductSearch].
@ProviderFor(PaginatedSupplierOrderProductSearch)
final paginatedSupplierOrderProductSearchProvider =
    AutoDisposeAsyncNotifierProvider<
      PaginatedSupplierOrderProductSearch,
      PaginatedState<AggregatedProduct>
    >.internal(
      PaginatedSupplierOrderProductSearch.new,
      name: r'paginatedSupplierOrderProductSearchProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$paginatedSupplierOrderProductSearchHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PaginatedSupplierOrderProductSearch =
    AutoDisposeAsyncNotifier<PaginatedState<AggregatedProduct>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
