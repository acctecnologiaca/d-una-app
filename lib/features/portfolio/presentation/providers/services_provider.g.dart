// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'services_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$servicesRepositoryHash() =>
    r'd3bb6a1ec8cc013e10074ed58bceecd05c3bce31';

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
String _$servicesHash() => r'e49f23bb045eb6250729826f925eebf9be570add';

/// See also [Services].
@ProviderFor(Services)
final servicesProvider =
    AsyncNotifierProvider<Services, List<ServiceModel>>.internal(
      Services.new,
      name: r'servicesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$servicesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Services = AsyncNotifier<List<ServiceModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
