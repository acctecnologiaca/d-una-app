import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/user_company.dart';
import '../../../settings/data/models/shipping_method.dart';

class ProfileRepository {
  final SupabaseClient _supabase;

  ProfileRepository(this._supabase);

  // --- Profile ---
  Future<UserProfile?> getProfile(String userId) async {
    try {
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserProfile.fromJson(data);
    } catch (e) {
      throw Exception('Error fetching profile: $e');
    }
  }

  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _supabase
          .from('profiles')
          .update(profile.toJson())
          .eq('id', profile.id);
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // --- Company ---
  Future<UserCompany?> getCompany(String userId) async {
    try {
      final data = await _supabase
          .from('user_companies')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UserCompany.fromJson(data);
    } catch (e) {
      throw Exception('Error fetching company: $e');
    }
  }

  Future<UserCompany> upsertCompany(UserCompany company) async {
    try {
      final json = company.toJson();
      if (company.id.isEmpty) {
        json.remove('id');
      }
      final data = await _supabase
          .from('user_companies')
          .upsert(json, onConflict: 'user_id')
          .select()
          .single();
      return UserCompany.fromJson(data);
    } catch (e) {
      throw Exception('Error saving company: $e');
    }
  }

  Future<void> deleteCompany(String companyId) async {
    try {
      await _supabase.from('user_companies').delete().eq('id', companyId);
    } catch (e) {
      throw Exception('Error deleting company: $e');
    }
  }

  // --- Shipping Methods ---
  Future<List<ShippingMethod>> getShippingMethods(String userId) async {
    try {
      final data = await _supabase
          .from('shipping_methods')
          .select('*, company:shipping_companies(*)')
          .eq('user_id', userId)
          .order('is_primary', ascending: false) // Primary first
          .order('created_at', ascending: true);

      return (data as List).map((e) => ShippingMethod.fromJson(e)).toList();
    } catch (e) {
      throw Exception('Error fetching shipping methods: $e');
    }
  }

  Future<void> saveShippingMethod(ShippingMethod method) async {
    try {
      await _supabase.from('shipping_methods').upsert(method.toJson());
    } catch (e) {
      throw Exception('Error saving shipping method: $e');
    }
  }

  Future<void> addShippingMethod(ShippingMethod method) async {
    try {
      if (method.isPrimary) {
        await _supabase
            .from('shipping_methods')
            .update({'is_primary': false})
            .eq('user_id', method.userId!);
      }

      final json = method.toJson();
      if (method.id.isEmpty) {
        json.remove('id');
      }
      await _supabase.from('shipping_methods').insert(json);
    } catch (e) {
      throw Exception('Error adding shipping method: $e');
    }
  }

  Future<void> updateShippingMethod(ShippingMethod method) async {
    try {
      if (method.isPrimary) {
        await _supabase
            .from('shipping_methods')
            .update({'is_primary': false})
            .eq('user_id', method.userId!);
      }

      await _supabase
          .from('shipping_methods')
          .update(method.toJson())
          .eq('id', method.id);
    } catch (e) {
      throw Exception('Error updating shipping method: $e');
    }
  }

  Future<void> deleteShippingMethod(String id) async {
    try {
      await _supabase.from('shipping_methods').delete().eq('id', id);
    } catch (e) {
      throw Exception('Error deleting shipping method: $e');
    }
  }

  // --- Storage ---
  Future<String> uploadAvatar(
    String userId,
    Uint8List bytes,
    String fileExt,
  ) async {
    try {
      final fileName = '$userId/avatar.$fileExt';
      await _supabase.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      final url = _supabase.storage.from('avatars').getPublicUrl(fileName);
      return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      throw Exception('Error uploading avatar: $e');
    }
  }

  Future<String> uploadCompanyLogo(
    String ownerId,
    Uint8List bytes,
    String fileExt,
  ) async {
    try {
      final fileName =
          '$ownerId/${DateTime.now().millisecondsSinceEpoch}_logo.$fileExt';
      await _supabase.storage
          .from('company_logos')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );
      return _supabase.storage.from('company_logos').getPublicUrl(fileName);
    } catch (e) {
      throw Exception('Error uploading company logo: $e');
    }
  }

  // --- Verification ---
  Future<List<Map<String, dynamic>>> getVerificationDocuments(
    String userId,
  ) async {
    try {
      final data = await _supabase
          .from('verification_documents')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Error fetching verification documents: $e');
    }
  }

  Future<void> uploadVerificationDocument(
    String userId,
    String documentType,
    Uint8List bytes,
    String fileExt, {
    String? companyId,
  }) async {
    try {
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}_$documentType.$fileExt';

      // Upload to storage
      await _supabase.storage
          .from('verification_documents')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // Check for existing record of same document_type and scope (personal vs company)
      var query = _supabase
          .from('verification_documents')
          .select('id')
          .eq('user_id', userId)
          .eq('document_type', documentType);

      if (companyId != null) {
        query = query.eq('company_id', companyId);
      } else {
        query = query.isFilter('company_id', null);
      }

      final existing = await query.maybeSingle();

      if (existing != null) {
        await _supabase
            .from('verification_documents')
            .update({
              'file_path': fileName,
              'status': 'pending',
              'company_id': companyId,
              'created_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existing['id']);
      } else {
        await _supabase.from('verification_documents').insert({
          'user_id': userId,
          'company_id': companyId,
          'document_type': documentType,
          'file_path': fileName,
          'status': 'pending',
        });
      }
    } catch (e) {
      throw Exception('Error uploading verification document: $e');
    }
  }

  Future<void> sendVerificationChangeRequest({
    required UserProfile profile,
    UserCompany? company,
    required String userEmail,
  }) async {
    try {
      final userName = '${profile.firstName ?? ''} ${profile.lastName ?? ''}'
          .trim();
      final accountType = profile.isBusinessOwner ? 'business' : 'individual';
      final companyName = company?.companyName ?? profile.companyName;
      final companyRif = company?.companyRif ?? profile.companyRif;

      // 1. Insert audit record in DB
      await _supabase.from('verification_change_requests').insert({
        'user_id': profile.id,
        'account_type': accountType,
        'user_email': userEmail,
        'user_name': userName.isEmpty ? 'Usuario' : userName,
        'company_name': companyName,
        'company_rif': companyRif,
        'status': 'pending',
      });

      // 2. Build email body
      final nowFormatted = DateTime.now().toLocal().toString().split('.')[0];
      final subject =
          '[Solicitud de Modificación] Verificación de cuenta - ${userName.isEmpty ? userEmail : userName}';
      final bodyHtml =
          '''
<div style="font-family: Arial, sans-serif; color: #1E293B; line-height: 1.6; max-width: 600px; margin: 0 auto;">
  <div style="background-color: #0F172A; padding: 20px; border-radius: 8px 8px 0 0; text-align: center;">
    <h2 style="color: #FFFFFF; margin: 0; font-size: 18px;">Solicitud de Modificación de Verificación</h2>
  </div>
  <div style="padding: 24px; border: 1px solid #E2E8F0; border-top: none; border-radius: 0 0 8px 8px; background-color: #FFFFFF;">
    <p>Se ha recibido una nueva solicitud de un usuario verificado para modificar sus datos o tipo de verificación:</p>
    
    <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
      <tr style="border-bottom: 1px solid #F1F5F9;">
        <td style="padding: 8px 0; font-weight: bold; color: #64748B;">Usuario:</td>
        <td style="padding: 8px 0; color: #0F172A;">${userName.isEmpty ? 'No especificado' : userName}</td>
      </tr>
      <tr style="border-bottom: 1px solid #F1F5F9;">
        <td style="padding: 8px 0; font-weight: bold; color: #64748B;">Email registrado:</td>
        <td style="padding: 8px 0; color: #0F172A;">$userEmail</td>
      </tr>
      <tr style="border-bottom: 1px solid #F1F5F9;">
        <td style="padding: 8px 0; font-weight: bold; color: #64748B;">Teléfono:</td>
        <td style="padding: 8px 0; color: #0F172A;">${profile.phone ?? 'No especificado'}</td>
      </tr>
      <tr style="border-bottom: 1px solid #F1F5F9;">
        <td style="padding: 8px 0; font-weight: bold; color: #64748B;">Tipo de Cuenta Actual:</td>
        <td style="padding: 8px 0; color: #0F172A;">${profile.isBusinessOwner ? 'Empresa' : 'Persona Natural'}</td>
      </tr>
      ${profile.isBusinessOwner ? '''
      <tr style="border-bottom: 1px solid #F1F5F9;">
        <td style="padding: 8px 0; font-weight: bold; color: #64748B;">Empresa:</td>
        <td style="padding: 8px 0; color: #0F172A;">${companyName ?? 'N/A'}</td>
      </tr>
      <tr style="border-bottom: 1px solid #F1F5F9;">
        <td style="padding: 8px 0; font-weight: bold; color: #64748B;">RIF / Identificación:</td>
        <td style="padding: 8px 0; color: #0F172A;">${companyRif ?? 'N/A'}</td>
      </tr>
      ''' : ''}
      <tr style="border-bottom: 1px solid #F1F5F9;">
        <td style="padding: 8px 0; font-weight: bold; color: #64748B;">Fecha de Solicitud:</td>
        <td style="padding: 8px 0; color: #0F172A;">$nowFormatted</td>
      </tr>
      <tr>
        <td style="padding: 8px 0; font-weight: bold; color: #64748B;">User ID:</td>
        <td style="padding: 8px 0; color: #64748B; font-size: 12px;">${profile.id}</td>
      </tr>
    </table>

    <p style="background-color: #F8FAFC; padding: 12px 16px; border-radius: 6px; font-size: 13px; color: #475569;">
      <strong>Nota:</strong> El usuario solicita que se revise su cuenta para actualizar documentos o cambiar su tipo de cuenta.
    </p>
  </div>
</div>
''';

      // 3. Send email via Edge Function
      await _supabase.functions.invoke(
        'send_document_email',
        body: {
          'documentType': 'verification_request',
          'recipientEmails': [userEmail],
          'userContext': {
            'name': userName.isEmpty ? 'Usuario' : userName,
            'companyName': companyName,
            'phone': profile.phone,
            'replyToEmail': userEmail,
            'companyLogo': profile.companyLogoUrl,
          },
          'emailContent': {'subject': subject, 'bodyHtml': bodyHtml},
        },
      );
    } catch (e) {
      throw Exception('Error enviando solicitud de modificación: \$e');
    }
  }
}
