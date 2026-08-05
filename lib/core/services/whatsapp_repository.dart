import 'dart:typed_data';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

part 'whatsapp_repository.g.dart';

class WhatsAppRepository {
  final SupabaseClient _client;

  WhatsAppRepository(this._client);

  /// Sends a document via WhatsApp Cloud API using a Supabase Edge Function.
  ///
  /// [phone] Receiver's phone number in international format (no '+').
  /// [pdfBytes] The PDF file content.
  /// [fileName] The name of the file (e.g., 'Cotizacion_123.pdf').
  /// [templateName] The name of the approved Meta template.
  /// [bodyVariables] List of strings to fill the template placeholders {{1}}, {{2}}, etc.
  Future<void> sendDocument({
    required String phone,
    required Uint8List pdfBytes,
    required String fileName,
    required String templateName,
    required List<String> bodyVariables,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) throw Exception('Usuario no autenticado');

    // 1. Upload to Supabase Storage
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}_$fileName';
    
    await _client.storage.from('quote_documents').uploadBinary(
          path,
          pdfBytes,
          fileOptions: const FileOptions(contentType: 'application/pdf'),
        );

    // 2. Generate Signed URL (12 hours = 43200 seconds)
    final signedUrl = await _client.storage
        .from('quote_documents')
        .createSignedUrl(path, 43200);

    // 3. Invoke Edge Function
    final response = await _client.functions.invoke(
      'send_whatsapp_message',
      body: {
        'phone': phone,
        'templateName': templateName,
        'documentUrl': signedUrl,
        'documentName': fileName,
        'bodyVariables': bodyVariables,
      },
    );

    if (response.status != 200) {
      throw Exception('Error al enviar WhatsApp: ${response.data}');
    }
  }

  /// Sends a template message via WhatsApp Cloud API without attaching a document file.
  Future<void> sendMessage({
    required String phone,
    required String templateName,
    required List<String> bodyVariables,
  }) async {
    final response = await _client.functions.invoke(
      'send_whatsapp_message',
      body: {
        'phone': phone,
        'templateName': templateName,
        'bodyVariables': bodyVariables,
      },
    );

    if (response.status != 200) {
      throw Exception('Error al enviar WhatsApp: ${response.data}');
    }
  }
}

@riverpod
WhatsAppRepository whatsappRepository(WhatsappRepositoryRef ref) {
  return WhatsAppRepository(Supabase.instance.client);
}
