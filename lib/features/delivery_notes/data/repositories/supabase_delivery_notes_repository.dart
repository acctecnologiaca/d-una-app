import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/delivery_note_model.dart';
import '../../domain/models/delivery_note_status.dart';
import '../../domain/repositories/delivery_notes_repository.dart';

final deliveryNotesRepositoryProvider = Provider<DeliveryNotesRepository>((ref) {
  return SupabaseDeliveryNotesRepository(Supabase.instance.client);
});

class SupabaseDeliveryNotesRepository implements DeliveryNotesRepository {
  final SupabaseClient _supabase;

  SupabaseDeliveryNotesRepository(this._supabase);

  static const _selectQuery = '''
    *,
    clients(name, tax_id, identification_id),
    contacts(name, phone, email),
    shipping_companies(name),
    delivery_note_items(
      *,
      delivery_note_serials(*)
    ),
    delivery_note_observations(*)
  ''';

  @override
  Future<List<DeliveryNoteModel>> getDeliveryNotes({bool? isArchived}) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    var query = _supabase
        .from('delivery_notes')
        .select(_selectQuery)
        .eq('user_id', currentUserId);

    if (isArchived != null) {
      query = query.eq('is_archived', isArchived);
    }

    final response = await query
        .order('date', ascending: false)
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => DeliveryNoteModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DeliveryNoteModel?> getDeliveryNoteById(String id) async {
    final response = await _supabase
        .from('delivery_notes')
        .select(_selectQuery)
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return DeliveryNoteModel.fromJson(response);
  }

  @override
  Future<DeliveryNoteModel?> getDeliveryNoteWithDetails(String id) =>
      getDeliveryNoteById(id);

  @override
  Future<List<DeliveryNoteModel>> getDeliveryNotesPaginated({
    required int offset,
    int limit = 25,
    String? searchQuery,
    String? statusFilter,
    bool includeArchived = false,
    String orderBy = 'date',
    bool ascending = false,
  }) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    var query = _supabase
        .from('delivery_notes')
        .select(_selectQuery)
        .eq('user_id', currentUserId);

    if (!includeArchived) {
      query = query.eq('is_archived', false);
    }

    if (statusFilter != null && statusFilter.isNotEmpty) {
      query = query.eq('status', statusFilter);
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim();
      query = query.or('delivery_note_number.ilike.%$q%,notes.ilike.%$q%,client_po_number.ilike.%$q%');
    }

    final response = await query
        .order(orderBy, ascending: ascending)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => DeliveryNoteModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<DeliveryNoteModel> createDeliveryNote(DeliveryNoteModel note) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    final headerData = note.toJson();
    headerData.remove('id');
    headerData['user_id'] = currentUserId;

    if (note.deliveryNoteNumber.isEmpty ||
        note.deliveryNoteNumber == 'NE-PENDIENTE') {
      headerData.remove('delivery_note_number'); // Let DB trigger generate it
    }

    // Determine missing serials flag
    headerData['has_missing_serials'] = note.items.any((i) => i.hasMissingSerials);

    final res = await _supabase
        .from('delivery_notes')
        .insert(headerData)
        .select('id')
        .single();
    final newId = res['id'] as String;

    // Insert items & serials
    for (var i = 0; i < note.items.length; i++) {
      final item = note.items[i];
      final itemData = item.toJson();
      itemData.remove('id');
      itemData['delivery_note_id'] = newId;
      itemData['order_index'] = i;

      final itemRes = await _supabase
          .from('delivery_note_items')
          .insert(itemData)
          .select('id')
          .single();
      final newItemId = itemRes['id'] as String;

      if (item.serials.isNotEmpty) {
        final serialsToInsert = item.serials.map((s) => {
          'delivery_note_item_id': newItemId,
          'product_id': item.productId,
          if (s.productSerialId != null) 'product_serial_id': s.productSerialId,
          'serial_number': s.serialNumber,
        }).toList();

        await _supabase.from('delivery_note_serials').insert(serialsToInsert);
      }
    }

    // Insert observations
    if (note.observations.isNotEmpty) {
      final obsToInsert = note.observations.asMap().entries.map((e) {
        final o = e.value;
        final oData = o.toJson();
        oData.remove('id');
        oData['delivery_note_id'] = newId;
        oData['order_index'] = e.key;
        return oData;
      }).toList();

      await _supabase.from('delivery_note_observations').insert(obsToInsert);
    }

    final created = await getDeliveryNoteById(newId);
    if (created == null) {
      throw Exception('No se pudo recuperar la nota de entrega recién creada');
    }
    return created;
  }

  @override
  Future<DeliveryNoteModel> updateDeliveryNote(DeliveryNoteModel note) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    final headerData = note.toJson();
    headerData.remove('id');
    headerData['has_missing_serials'] = note.items.any((i) => i.hasMissingSerials);
    headerData['updated_at'] = DateTime.now().toIso8601String();

    await _supabase
        .from('delivery_notes')
        .update(headerData)
        .eq('id', note.id);

    // Delete existing items & observations (serials cascade automatically)
    await _supabase
        .from('delivery_note_items')
        .delete()
        .eq('delivery_note_id', note.id);

    await _supabase
        .from('delivery_note_observations')
        .delete()
        .eq('delivery_note_id', note.id);

    // Insert new items & serials
    for (var i = 0; i < note.items.length; i++) {
      final item = note.items[i];
      final itemData = item.toJson();
      itemData.remove('id');
      itemData['delivery_note_id'] = note.id;
      itemData['order_index'] = i;

      final itemRes = await _supabase
          .from('delivery_note_items')
          .insert(itemData)
          .select('id')
          .single();
      final newItemId = itemRes['id'] as String;

      if (item.serials.isNotEmpty) {
        final serialsToInsert = item.serials.map((s) => {
          'delivery_note_item_id': newItemId,
          'product_id': item.productId,
          if (s.productSerialId != null) 'product_serial_id': s.productSerialId,
          'serial_number': s.serialNumber,
        }).toList();

        await _supabase.from('delivery_note_serials').insert(serialsToInsert);
      }
    }

    // Insert new observations
    if (note.observations.isNotEmpty) {
      final obsToInsert = note.observations.asMap().entries.map((e) {
        final o = e.value;
        final oData = o.toJson();
        oData.remove('id');
        oData['delivery_note_id'] = note.id;
        oData['order_index'] = e.key;
        return oData;
      }).toList();

      await _supabase.from('delivery_note_observations').insert(obsToInsert);
    }

    final updated = await getDeliveryNoteById(note.id);
    if (updated == null) {
      throw Exception('No se pudo recuperar la nota de entrega actualizada');
    }
    return updated;
  }

  @override
  Future<void> deleteDeliveryNote(String id) async {
    await _supabase.from('delivery_notes').delete().eq('id', id);
  }

  @override
  Future<void> setArchived(String id, bool isArchived) async {
    await _supabase.from('delivery_notes').update({
      'is_archived': isArchived,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> archiveDeliveryNote(String id, bool isArchived) =>
      setArchived(id, isArchived);

  @override
  Future<void> updateStatus(String id, DeliveryNoteStatus status) async {
    await _supabase.from('delivery_notes').update({
      'status': status.dbValue,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<void> updateDeliveryNoteStatus(String id, DeliveryNoteStatus status) =>
      updateStatus(id, status);

  @override
  Future<void> confirmReception(
    String id, {
    required String receivedByName,
    required String receivedById,
    String? receivedByPhone,
    String? receiverRelationship,
    String? signatureData,
    DeliveryNoteStatus? status,
  }) async {
    await registerPhysicalSignature(
      id,
      receivedByName: receivedByName,
      receivedById: receivedById,
      receivedByPhone: receivedByPhone,
      receiverRelationship: receiverRelationship,
      signatureData: signatureData ?? '',
    );
  }

  @override
  Future<void> batchUpdateStatus(List<String> ids, DeliveryNoteStatus status) async {
    if (ids.isEmpty) return;
    await _supabase.from('delivery_notes').update({
      'status': status.dbValue,
      'updated_at': DateTime.now().toIso8601String(),
    }).inFilter('id', ids);
  }

  @override
  Future<void> batchArchive(List<String> ids, bool isArchived) async {
    if (ids.isEmpty) return;
    await _supabase.from('delivery_notes').update({
      'is_archived': isArchived,
      'updated_at': DateTime.now().toIso8601String(),
    }).inFilter('id', ids);
  }

  @override
  Future<void> batchDelete(List<String> ids) async {
    if (ids.isEmpty) return;
    await _supabase.from('delivery_notes').delete().inFilter('id', ids).eq('status', 'draft');
  }

  @override
  Future<void> registerPhysicalSignature(
    String id, {
    required String receivedByName,
    required String receivedById,
    String? receivedByPhone,
    String? receiverRelationship,
    required String signatureData,
  }) async {
    await _supabase.from('delivery_notes').update({
      'status': DeliveryNoteStatus.finalized.dbValue,
      'received_by_name': receivedByName,
      'received_by_id': receivedById,
      'received_by_phone': receivedByPhone,
      'receiver_relationship': receiverRelationship,
      'signature_data': signatureData,
      'received_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  @override
  Future<String> generateActionToken(String id) async {
    final result = await _supabase.rpc(
      'generate_delivery_note_action_token',
      params: {'p_note_id': id},
    );
    return result as String;
  }

  @override
  Stream<List<DeliveryNoteModel>> watchDeliveryNotes() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    return _supabase
        .from('delivery_notes')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false)
        .asyncMap((_) => getDeliveryNotes(isArchived: false));
  }

  @override
  Future<List<DeliveryNoteModel>> getDeliveryNotesByQuoteId(String quoteId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    final response = await _supabase
        .from('delivery_notes')
        .select(_selectQuery)
        .eq('quote_id', quoteId)
        .neq('status', 'cancelled')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => DeliveryNoteModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<DeliveryNoteModel>> getDeliveryNotesBySupplierOrderId(
    String supplierOrderId,
  ) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('Usuario no autenticado');

    final response = await _supabase
        .from('delivery_notes')
        .select(_selectQuery)
        .eq('supplier_order_id', supplierOrderId)
        .neq('status', 'cancelled')
        .order('created_at', ascending: false);

    return (response as List)
        .map((json) => DeliveryNoteModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<String?> getLastDeliveryNoteNumber() async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return null;

    final response = await _supabase
        .from('delivery_notes')
        .select('delivery_note_number')
        .eq('user_id', currentUserId)
        .order('created_at', ascending: false)
        .limit(1)
        .maybeSingle();

    return response?['delivery_note_number'] as String?;
  }
}
