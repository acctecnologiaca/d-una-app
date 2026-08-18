import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/credit_status.dart';
import '../models/credit_transaction_model.dart';

class CreditsRepository {
  final SupabaseClient _client;

  CreditsRepository(this._client);

  /// Obtiene el estado actual de créditos del usuario authenticado.
  Future<CreditStatus> getCreditStatus() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final response = await _client.rpc(
      'get_user_credit_status',
      params: {'p_user_id': userId},
    );

    return CreditStatus.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Descuenta 1 crédito por envío de documento (Email o WhatsApp).
  Future<CreditStatus> consumeCredit({
    required String documentType,
    required String channel, // 'email' | 'whatsapp'
    String? referenceId,
    String? documentNumber,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final response = await _client.rpc(
      'consume_user_credit',
      params: {
        'p_user_id': userId,
        'p_doc_type': documentType,
        'p_channel': channel,
        'p_ref_id': referenceId,
        'p_doc_number': documentNumber,
      },
    );

    return CreditStatus.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Consulta el historial de transacciones de créditos del usuario authenticado.
  Future<List<CreditTransactionModel>> getCreditTransactions({
    int limit = 50,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    final response = await _client
        .from('credit_transactions')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List)
        .map(
          (json) =>
              CreditTransactionModel.fromJson(Map<String, dynamic>.from(json)),
        )
        .toList();
  }
}
