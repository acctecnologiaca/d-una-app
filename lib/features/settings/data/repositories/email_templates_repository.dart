import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/email_template.dart';

class EmailTemplatesRepository {
  final SupabaseClient _supabase;

  EmailTemplatesRepository(this._supabase);

  Future<List<EmailTemplate>> getEmailTemplates() async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('email_templates')
        .select()
        .eq('user_id', userId);

    final data = response as List<dynamic>;
    return data.map((json) => EmailTemplate.fromJson(json)).toList();
  }

  Future<EmailTemplate?> getTemplateByType(String documentType) async {
    final userId = _supabase.auth.currentUser!.id;
    final response = await _supabase
        .from('email_templates')
        .select()
        .eq('user_id', userId)
        .eq('document_type', documentType)
        .maybeSingle();

    if (response == null) return null;
    return EmailTemplate.fromJson(response);
  }

  Future<void> saveEmailTemplate(EmailTemplate template) async {
    final userId = _supabase.auth.currentUser!.id;
    
    final data = template.toJson();
    data['user_id'] = userId; // Ensure correct user_id
    data.remove('id'); // Remove ID for upsert if it's new or let DB handle it

    await _supabase.from('email_templates').upsert(
      data,
      onConflict: 'user_id, document_type',
    );
  }

  Future<void> deleteEmailTemplate(String id) async {
    await _supabase.from('email_templates').delete().eq('id', id);
  }
}
