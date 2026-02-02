// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suppliers_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$suppliersRepositoryHash() =>
    r'cabea85e954535e1033223120c454a1713b5c052';

/// See also [suppliersRepository].
@ProviderFor(suppliersRepository)
final suppliersRepositoryProvider =
    AutoDisposeProvider<SuppliersRepository>.internal(
      suppliersRepository,
      name: r'suppliersRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$suppliersRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SuppliersRepositoryRef = AutoDisposeProviderRef<SuppliersRepository>;
String _$suppliersHash() => r'76b6b997247802fbdc29e5a6e338e6c943037e41';

/// See also [suppliers].
@ProviderFor(suppliers)
final suppliersProvider = AutoDisposeFutureProvider<List<Supplier>>.internal(
  suppliers,
  name: r'suppliersProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$suppliersHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SuppliersRef = AutoDisposeFutureProviderRef<List<Supplier>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
