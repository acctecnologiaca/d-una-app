import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/collaborator.dart';

class CollaboratorsRepository {
  final SupabaseClient _client;

  CollaboratorsRepository(this._client);

  Future<List<Collaborator>> getCollaborators({bool? activeOnly}) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return [];

    var query = _client.from('collaborators').select().eq('user_id', userId);
    if (activeOnly != null) {
      query = query.eq('is_active', activeOnly);
    }
    final response = await query.order('full_name', ascending: true);
    return (response as List).map((e) => Collaborator.fromJson(e)).toList();
  }

  Future<Collaborator> addCollaborator({
    required String fullName,
    String? identificationId,
    String? phone,
    String? email,
    String? charge,
    bool isActive = true,
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
          'is_active': isActive,
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
    bool? isActive,
  }) async {
    final updateData = <String, dynamic>{
      'full_name': fullName,
      'identification_id': identificationId,
      'phone': phone,
      'email': email,
      'charge': charge,
    };
    if (isActive != null) {
      updateData['is_active'] = isActive;
    }

    final response = await _client
        .from('collaborators')
        .update(updateData)
        .eq('id', id)
        .select()
        .single();
    return Collaborator.fromJson(response);
  }

  Future<bool> hasLinkedDocuments(String collaboratorId) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      // 1. Check in quotes
      final quotes = await _client
          .from('quotes')
          .select('id')
          .eq('advisor_id', collaboratorId)
          .limit(1);
      if ((quotes as List).isNotEmpty) return true;

      // 2. Check in service_reports
      try {
        final reports = await _client
            .from('service_reports')
            .select('id')
            .eq('advisor_id', collaboratorId)
            .limit(1);
        if ((reports as List).isNotEmpty) return true;
      } catch (_) {}

      // 3. Check in supplier_orders
      try {
        final orders = await _client
            .from('supplier_orders')
            .select('id')
            .eq('receiver_collaborator_id', collaboratorId)
            .limit(1);
        if ((orders as List).isNotEmpty) return true;
      } catch (_) {}

      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> deleteCollaborator(String id) async {
    final hasDocs = await hasLinkedDocuments(id);
    if (hasDocs) {
      throw Exception(
        'No se puede eliminar el colaborador porque tiene documentos asociados.',
      );
    }
    await _client.from('collaborators').delete().eq('id', id);
  }

  Future<void> toggleCollaboratorStatus(String id, bool isActive) async {
    await _client
        .from('collaborators')
        .update({'is_active': isActive})
        .eq('id', id);
  }

  Future<Collaborator?> getSelfCollaborator() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final response = await _client
        .from('collaborators')
        .select()
        .eq('user_id', userId)
        .eq('is_user_record', true)
        .maybeSingle();

    if (response == null) return null;
    return Collaborator.fromJson(response);
  }
}
