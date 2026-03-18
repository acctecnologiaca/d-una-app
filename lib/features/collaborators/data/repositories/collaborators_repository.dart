import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/collaborator.dart';

class CollaboratorsRepository {
  final SupabaseClient _client;

  CollaboratorsRepository(this._client);

  Future<List<Collaborator>> getCollaborators() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await _client
        .from('collaborators')
        .select()
        .eq('user_id', userId)
        .eq('is_active', true)
        .order('full_name', ascending: true);
    return (response as List).map((e) => Collaborator.fromJson(e)).toList();
  }

  Future<Collaborator> addCollaborator({
    required String fullName,
    String? identificationId,
    String? phone,
    String? email,
    String? charge,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('User not authenticated');

    final response = await _client
        .from('collaborators')
        .insert({
          'user_id': userId,
          'full_name': fullName,
          'identification_id': identificationId,
          'phone': phone,
          'email': email,
          'charge': charge,
          'is_active': true,
        })
        .select()
        .single();
    return Collaborator.fromJson(response);
  }

  Future<Collaborator> updateCollaborator({
    required String id,
    required String fullName,
    String? identificationId,
    String? phone,
    String? email,
    String? charge,
  }) async {
    final response = await _client
        .from('collaborators')
        .update({
          'full_name': fullName,
          'identification_id': identificationId,
          'phone': phone,
          'email': email,
          'charge': charge,
        })
        .eq('id', id)
        .select()
        .single();
    return Collaborator.fromJson(response);
  }
}
