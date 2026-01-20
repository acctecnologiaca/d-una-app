import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_clients_repository.dart';
import '../../data/models/client_model.dart';

part 'clients_provider.g.dart';

// Repository Provider
@riverpod
SupabaseClientsRepository clientsRepository(Ref ref) {
  return SupabaseClientsRepository(Supabase.instance.client);
}

// Clients List Provider
@riverpod
class Clients extends _$Clients {
  @override
  FutureOr<List<Client>> build() async {
    return ref.read(clientsRepositoryProvider).getClients();
  }

  Future<void> addClient(Map<String, dynamic> clientData) async {
    state = AsyncValue<List<Client>>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await ref.read(clientsRepositoryProvider).addClient(clientData);
      return ref.read(clientsRepositoryProvider).getClients();
    });
  }

  Future<void> updateClient(String id, Map<String, dynamic> updates) async {
    state = AsyncValue<List<Client>>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await ref.read(clientsRepositoryProvider).updateClient(id, updates);
      return ref.read(clientsRepositoryProvider).getClients();
    });
  }

  Future<void> deleteClient(String id) async {
    state = AsyncValue<List<Client>>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await ref.read(clientsRepositoryProvider).deleteClient(id);
      return ref.read(clientsRepositoryProvider).getClients();
    });
  }

  Future<void> addContact(
    String clientId,
    Map<String, dynamic> contactData,
  ) async {
    state = AsyncValue<List<Client>>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await ref
          .read(clientsRepositoryProvider)
          .addContact(clientId, contactData);
      return ref.read(clientsRepositoryProvider).getClients();
    });
  }

  Future<void> updateContact(String id, Map<String, dynamic> updates) async {
    state = AsyncValue<List<Client>>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await ref.read(clientsRepositoryProvider).updateContact(id, updates);
      return ref.read(clientsRepositoryProvider).getClients();
    });
  }

  Future<void> deleteContact(String id) async {
    state = AsyncValue<List<Client>>.loading().copyWithPrevious(state);
    state = await AsyncValue.guard(() async {
      await ref.read(clientsRepositoryProvider).deleteContact(id);
      return ref.read(clientsRepositoryProvider).getClients();
    });
  }

  Future<bool> checkClientExists(String taxId, {String? excludeId}) async {
    return ref
        .read(clientsRepositoryProvider)
        .checkClientExists(taxId, excludeId: excludeId);
  }
}
