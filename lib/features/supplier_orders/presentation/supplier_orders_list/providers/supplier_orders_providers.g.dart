// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_orders_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$supplierOrdersRepositoryHash() =>
    r'69c05e8c9369c71082a5fbd732e729aa76b1ea6c';

/// See also [supplierOrdersRepository].
@ProviderFor(supplierOrdersRepository)
final supplierOrdersRepositoryProvider =
    AutoDisposeProvider<SupplierOrdersRepository>.internal(
      supplierOrdersRepository,
      name: r'supplierOrdersRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$supplierOrdersRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SupplierOrdersRepositoryRef =
    AutoDisposeProviderRef<SupplierOrdersRepository>;
String _$supplierOrderDetailHash() =>
    r'5f92a3e0597631ad1d58258365214b8a738a155e';

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

/// See also [supplierOrderDetail].
@ProviderFor(supplierOrderDetail)
const supplierOrderDetailProvider = SupplierOrderDetailFamily();

/// See also [supplierOrderDetail].
class SupplierOrderDetailFamily
    extends
        Family<
          AsyncValue<({SupplierOrder order, List<SupplierOrderItem> items})>
        > {
  /// See also [supplierOrderDetail].
  const SupplierOrderDetailFamily();

  /// See also [supplierOrderDetail].
  SupplierOrderDetailProvider call(String id) {
    return SupplierOrderDetailProvider(id);
  }

  @override
  SupplierOrderDetailProvider getProviderOverride(
    covariant SupplierOrderDetailProvider provider,
  ) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'supplierOrderDetailProvider';
}

/// See also [supplierOrderDetail].
class SupplierOrderDetailProvider
    extends
        AutoDisposeFutureProvider<
          ({SupplierOrder order, List<SupplierOrderItem> items})
        > {
  /// See also [supplierOrderDetail].
  SupplierOrderDetailProvider(String id)
    : this._internal(
        (ref) => supplierOrderDetail(ref as SupplierOrderDetailRef, id),
        from: supplierOrderDetailProvider,
        name: r'supplierOrderDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$supplierOrderDetailHash,
        dependencies: SupplierOrderDetailFamily._dependencies,
        allTransitiveDependencies:
            SupplierOrderDetailFamily._allTransitiveDependencies,
        id: id,
      );

  SupplierOrderDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<({SupplierOrder order, List<SupplierOrderItem> items})> Function(
      SupplierOrderDetailRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SupplierOrderDetailProvider._internal(
        (ref) => create(ref as SupplierOrderDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<
    ({SupplierOrder order, List<SupplierOrderItem> items})
  >
  createElement() {
    return _SupplierOrderDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SupplierOrderDetailProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SupplierOrderDetailRef
    on
        AutoDisposeFutureProviderRef<
          ({SupplierOrder order, List<SupplierOrderItem> items})
        > {
  /// The parameter `id` of this provider.
  String get id;
}

class _SupplierOrderDetailProviderElement
    extends
        AutoDisposeFutureProviderElement<
          ({SupplierOrder order, List<SupplierOrderItem> items})
        >
    with SupplierOrderDetailRef {
  _SupplierOrderDetailProviderElement(super.provider);

  @override
  String get id => (origin as SupplierOrderDetailProvider).id;
}

String _$supplierBranchesHash() => r'61d2d2708e3fbd63e109a1e52ef33b865880db15';

/// See also [supplierBranches].
@ProviderFor(supplierBranches)
const supplierBranchesProvider = SupplierBranchesFamily();

/// See also [supplierBranches].
class SupplierBranchesFamily
    extends Family<AsyncValue<List<Map<String, dynamic>>>> {
  /// See also [supplierBranches].
  const SupplierBranchesFamily();

  /// See also [supplierBranches].
  SupplierBranchesProvider call(String supplierId) {
    return SupplierBranchesProvider(supplierId);
  }

  @override
  SupplierBranchesProvider getProviderOverride(
    covariant SupplierBranchesProvider provider,
  ) {
    return call(provider.supplierId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'supplierBranchesProvider';
}

/// See also [supplierBranches].
class SupplierBranchesProvider
    extends AutoDisposeFutureProvider<List<Map<String, dynamic>>> {
  /// See also [supplierBranches].
  SupplierBranchesProvider(String supplierId)
    : this._internal(
        (ref) => supplierBranches(ref as SupplierBranchesRef, supplierId),
        from: supplierBranchesProvider,
        name: r'supplierBranchesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$supplierBranchesHash,
        dependencies: SupplierBranchesFamily._dependencies,
        allTransitiveDependencies:
            SupplierBranchesFamily._allTransitiveDependencies,
        supplierId: supplierId,
      );

  SupplierBranchesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.supplierId,
  }) : super.internal();

  final String supplierId;

  @override
  Override overrideWith(
    FutureOr<List<Map<String, dynamic>>> Function(SupplierBranchesRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SupplierBranchesProvider._internal(
        (ref) => create(ref as SupplierBranchesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        supplierId: supplierId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Map<String, dynamic>>> createElement() {
    return _SupplierBranchesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SupplierBranchesProvider && other.supplierId == supplierId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, supplierId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin SupplierBranchesRef
    on AutoDisposeFutureProviderRef<List<Map<String, dynamic>>> {
  /// The parameter `supplierId` of this provider.
  String get supplierId;
}

class _SupplierBranchesProviderElement
    extends AutoDisposeFutureProviderElement<List<Map<String, dynamic>>>
    with SupplierBranchesRef {
  _SupplierBranchesProviderElement(super.provider);

  @override
  String get supplierId => (origin as SupplierBranchesProvider).supplierId;
}

String _$supplierBranchContactInfoHash() =>
    r'd0db69d21e5a24135a4a4b7007aaa974c48022ad';

/// See also [supplierBranchContactInfo].
@ProviderFor(supplierBranchContactInfo)
const supplierBranchContactInfoProvider = SupplierBranchContactInfoFamily();

/// See also [supplierBranchContactInfo].
class SupplierBranchContactInfoFamily
    extends Family<AsyncValue<Map<String, dynamic>?>> {
  /// See also [supplierBranchContactInfo].
  const SupplierBranchContactInfoFamily();

  /// See also [supplierBranchContactInfo].
  SupplierBranchContactInfoProvider call(String branchId) {
    return SupplierBranchContactInfoProvider(branchId);
  }

  @override
  SupplierBranchContactInfoProvider getProviderOverride(
    covariant SupplierBranchContactInfoProvider provider,
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
  String? get name => r'supplierBranchContactInfoProvider';
}

/// See also [supplierBranchContactInfo].
class SupplierBranchContactInfoProvider
    extends AutoDisposeFutureProvider<Map<String, dynamic>?> {
  /// See also [supplierBranchContactInfo].
  SupplierBranchContactInfoProvider(String branchId)
    : this._internal(
        (ref) => supplierBranchContactInfo(
          ref as SupplierBranchContactInfoRef,
          branchId,
        ),
        from: supplierBranchContactInfoProvider,
        name: r'supplierBranchContactInfoProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$supplierBranchContactInfoHash,
        dependencies: SupplierBranchContactInfoFamily._dependencies,
        allTransitiveDependencies:
            SupplierBranchContactInfoFamily._allTransitiveDependencies,
        branchId: branchId,
      );

  SupplierBranchContactInfoProvider._internal(
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
    FutureOr<Map<String, dynamic>?> Function(
      SupplierBranchContactInfoRef provider,
    )
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: SupplierBranchContactInfoProvider._internal(
        (ref) => create(ref as SupplierBranchContactInfoRef),
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
  AutoDisposeFutureProviderElement<Map<String, dynamic>?> createElement() {
    return _SupplierBranchContactInfoProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is SupplierBranchContactInfoProvider &&
        other.branchId == branchId;
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
mixin SupplierBranchContactInfoRef
    on AutoDisposeFutureProviderRef<Map<String, dynamic>?> {
  /// The parameter `branchId` of this provider.
  String get branchId;
}

class _SupplierBranchContactInfoProviderElement
    extends AutoDisposeFutureProviderElement<Map<String, dynamic>?>
    with SupplierBranchContactInfoRef {
  _SupplierBranchContactInfoProviderElement(super.provider);

  @override
  String get branchId => (origin as SupplierBranchContactInfoProvider).branchId;
}

String _$paginatedSupplierOrdersHash() =>
    r'a0777aa0b5ae4e7ae90528c9c42b55c44c0c4124';

/// See also [PaginatedSupplierOrders].
@ProviderFor(PaginatedSupplierOrders)
final paginatedSupplierOrdersProvider =
    AutoDisposeAsyncNotifierProvider<
      PaginatedSupplierOrders,
      PaginatedState<SupplierOrder>
    >.internal(
      PaginatedSupplierOrders.new,
      name: r'paginatedSupplierOrdersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$paginatedSupplierOrdersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PaginatedSupplierOrders =
    AutoDisposeAsyncNotifier<PaginatedState<SupplierOrder>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
