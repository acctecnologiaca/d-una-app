// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clients_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$clientsRepositoryHash() => r'0fb644c83fcca5017493b7ec28a27b8f5ef39d81';

/// See also [clientsRepository].
@ProviderFor(clientsRepository)
final clientsRepositoryProvider =
    AutoDisposeProvider<SupabaseClientsRepository>.internal(
      clientsRepository,
      name: r'clientsRepositoryProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$clientsRepositoryHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ClientsRepositoryRef =
    AutoDisposeProviderRef<SupabaseClientsRepository>;
String _$clientsHash() => r'8cd694c822be9e6492a85f2c0e22f955a7e18ccc';

/// See also [Clients].
@ProviderFor(Clients)
final clientsProvider =
    AutoDisposeAsyncNotifierProvider<Clients, List<Client>>.internal(
      Clients.new,
      name: r'clientsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$clientsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Clients = AutoDisposeAsyncNotifier<List<Client>>;
String _$paginatedClientsHash() => r'94e10024f0682729227dd64e7af82a76bf15e7b5';

/// See also [PaginatedClients].
@ProviderFor(PaginatedClients)
final paginatedClientsProvider =
    AutoDisposeAsyncNotifierProvider<
      PaginatedClients,
      PaginatedState<Client>
    >.internal(
      PaginatedClients.new,
      name: r'paginatedClientsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$paginatedClientsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PaginatedClients = AutoDisposeAsyncNotifier<PaginatedState<Client>>;
String _$paginatedClientSearchHash() =>
    r'5b03f86e1aca918477eae70a616297a592836137';

/// See also [PaginatedClientSearch].
@ProviderFor(PaginatedClientSearch)
final paginatedClientSearchProvider =
    AutoDisposeAsyncNotifierProvider<
      PaginatedClientSearch,
      PaginatedState<Client>
    >.internal(
      PaginatedClientSearch.new,
      name: r'paginatedClientSearchProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$paginatedClientSearchHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$PaginatedClientSearch =
    AutoDisposeAsyncNotifier<PaginatedState<Client>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
