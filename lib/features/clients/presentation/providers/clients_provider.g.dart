// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'clients_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$clientsRepositoryHash() => r'9edacd6f527f595bc204bd7e633f024d62df5073';

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
String _$clientsHash() => r'7b35825ad4eeb45222fb6f02eaa48cf008838de4';

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
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
