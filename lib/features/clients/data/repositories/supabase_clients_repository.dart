import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/client_model.dart';
// Note: You should have an abstract ClientsRepository interface.
// For now I'm implementing it directly or as a concrete class to replace the provider mock.

class SupabaseClientsRepository {
  final SupabaseClient _supabase;

  SupabaseClientsRepository(this._supabase);

  Future<List<Client>> getClients() async {
    final response = await _supabase
        .from('clients')
        .select('*, contacts(*)'); // Fetch clients with their contacts

    // ignore: unnecessary_cast
    final data = response as List<dynamic>;
    return data.map((json) => Client.fromJson(json)).toList();
  }

  Future<Client?> getClient(String id) async {
    final response = await _supabase
        .from('clients')
        .select('*, contacts(*)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Client.fromJson(response);
  }

  Future<void> addClient(Map<String, dynamic> clientData) async {
    final userId = _supabase.auth.currentUser!.id;

    final taxId = clientData['rif'] ?? clientData['personalID'];

    // Check for duplicate Tax ID if provided
    if (taxId != null && taxId.toString().isNotEmpty) {
      final existingResponse = await _supabase
          .from('clients')
          .select('id')
          .eq('tax_id', taxId)
          .eq('owner_id', userId)
          .maybeSingle();

      if (existingResponse != null) {
        throw Exception('Ya existe un cliente registrado con este RIF/Cédula');
      }
    }

    final dbData = {
      'owner_id': userId,
      'name': clientData['name'],
      'type': clientData['type'], // 'company' or 'person'
      'tax_id': taxId,
      'alias': clientData['alias'],
      'email': clientData['email'],
      'phone': clientData['phone'],
      'address': clientData['address'],
      'city': clientData['city'],
      'state': clientData['state'],
      'country': clientData['country'],
      // 'created_at': DateTime.now().toIso8601String(), // Let DB handle default
    };

    final clientResponse = await _supabase
        .from('clients')
        .insert(dbData)
        .select()
        .single();

    final clientId = clientResponse['id'];

    // Handle contacts if any
    if (clientData['contacts'] != null) {
      final contacts = clientData['contacts'] as List;
      for (var c in contacts) {
        await addContact(clientId, c);
      }
    }
  }

  Future<void> updateClient(String id, Map<String, dynamic> updates) async {
    final userId = _supabase.auth.currentUser!.id;

    // Check for duplicate Tax ID if it's being updated
    final newTaxId = updates['rif'] ?? updates['tax_id'];
    if (newTaxId != null && newTaxId.toString().isNotEmpty) {
      final existingResponse = await _supabase
          .from('clients')
          .select('id')
          .eq('tax_id', newTaxId)
          .eq('owner_id', userId)
          .neq('id', id) // Exclude self
          .maybeSingle();

      if (existingResponse != null) {
        throw Exception('Ya existe otro cliente con este RIF/Cédula');
      }
    }

    final dbUpdates = <String, dynamic>{};
    if (updates.containsKey('name')) dbUpdates['name'] = updates['name'];
    if (updates.containsKey('rif')) dbUpdates['tax_id'] = updates['rif'];
    if (updates.containsKey('tax_id')) dbUpdates['tax_id'] = updates['tax_id'];
    if (updates.containsKey('alias')) dbUpdates['alias'] = updates['alias'];
    if (updates.containsKey('email')) dbUpdates['email'] = updates['email'];
    if (updates.containsKey('phone')) dbUpdates['phone'] = updates['phone'];
    if (updates.containsKey('address')) {
      dbUpdates['address'] = updates['address'];
    }
    if (updates.containsKey('city')) dbUpdates['city'] = updates['city'];
    if (updates.containsKey('state')) dbUpdates['state'] = updates['state'];
    if (updates.containsKey('country')) {
      dbUpdates['country'] = updates['country'];
    }

    if (dbUpdates.isNotEmpty) {
      await _supabase.from('clients').update(dbUpdates).eq('id', id);
    }
  }

  Future<void> deleteClient(String id) async {
    await _supabase.from('clients').delete().eq('id', id);
  }

  // Contact Operations
  Future<void> addContact(
    String clientId,
    Map<String, dynamic> contactData,
  ) async {
    final dbData = {
      'client_id': clientId,
      'name': contactData['name'],
      'role': contactData['role'],
      'email': contactData['email'],
      'phone': contactData['phone'],
      'department': contactData['department'],
      'is_primary': contactData['isPrimary'] == true,
    };

    // If this contact is primary, set all others to false first
    if (contactData['isPrimary'] == true) {
      await _supabase
          .from('contacts')
          .update({'is_primary': false})
          .eq('client_id', clientId);
    }

    await _supabase.from('contacts').insert(dbData);
  }

  Future<void> updateContact(String id, Map<String, dynamic> updates) async {
    final dbUpdates = <String, dynamic>{};
    if (updates.containsKey('name')) dbUpdates['name'] = updates['name'];
    if (updates.containsKey('role')) dbUpdates['role'] = updates['role'];
    if (updates.containsKey('email')) dbUpdates['email'] = updates['email'];
    if (updates.containsKey('phone')) dbUpdates['phone'] = updates['phone'];
    if (updates.containsKey('department')) {
      dbUpdates['department'] = updates['department'];
    }
    if (updates.containsKey('isPrimary')) {
      dbUpdates['is_primary'] = updates['isPrimary'];
    }

    if (dbUpdates.isNotEmpty) {
      // If setting to primary, unset others for this client
      if (dbUpdates['is_primary'] == true) {
        // Fetch the contact to get client_id
        final contact = await _supabase
            .from('contacts')
            .select('client_id')
            .eq('id', id)
            .single();
        final clientId = contact['client_id'];

        if (clientId != null) {
          await _supabase
              .from('contacts')
              .update({'is_primary': false})
              .eq('client_id', clientId);
        }
      }

      await _supabase.from('contacts').update(dbUpdates).eq('id', id);
    }
  }

  Future<void> deleteContact(String id) async {
    await _supabase.from('contacts').delete().eq('id', id);
  }

  Future<bool> checkClientExists(String taxId, {String? excludeId}) async {
    final userId = _supabase.auth.currentUser!.id;
    var query = _supabase
        .from('clients')
        .select('id')
        .eq('tax_id', taxId)
        .eq('owner_id', userId);

    if (excludeId != null) {
      query = query.neq('id', excludeId);
    }

    final response = await query.maybeSingle();
    return response != null;
  }
}
