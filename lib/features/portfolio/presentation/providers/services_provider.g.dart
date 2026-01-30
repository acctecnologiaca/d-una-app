// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$servicesRepositoryHash() =>
    r'b128953d881d7b62c6e0ac426e4a12f4e1b3703f';

/// See also [servicesRepository].
@ProviderFor(servicesRepository)
final servicesRepositoryProvider =
    AutoDisposeProvider<ServicesRepository>.internal(
      servicesRepository,
      name: r'servicesRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$servicesRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ServicesRepositoryRef = AutoDisposeProviderRef<ServicesRepository>;
String _$servicesHash() => r'751722bdb937f35bb9917d502fbb6bbd790cb3b7';

/// See also [Services].
@ProviderFor(Services)
final servicesProvider =
    AutoDisposeAsyncNotifierProvider<Services, List<ServiceModel>>.internal(
      Services.new,
      name: r'servicesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$servicesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Services = AutoDisposeAsyncNotifier<List<ServiceModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
