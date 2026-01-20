import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/models/user_profile.dart';
import '../../domain/models/shipping_method.dart';

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

  // --- Shipping Methods ---
  Future<List<ShippingMethod>> getShippingMethods(String userId) async {
    try {
      final data = await _supabase
          .from('shipping_methods')
          .select()
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
      // If setting as primary, we might want to handle unsetting others here or rely on specific logic.
      // For now, let's assume the UI handles the "unset others" logic or we do a batch update.
      // Simple upsert:
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
            .eq('user_id', method.userId);
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
            .eq('user_id', method.userId);
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
    String userId,
    Uint8List bytes,
    String fileExt,
  ) async {
    try {
      final fileName =
          '$userId/${DateTime.now().millisecondsSinceEpoch}_logo.$fileExt';
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
          .eq('user_id', userId);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      throw Exception('Error fetching verification documents: $e');
    }
  }

  Future<void> uploadVerificationDocument(
    String userId,
    String documentType,
    Uint8List bytes,
    String fileExt,
  ) async {
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

      // Insert record
      await _supabase.from('verification_documents').insert({
        'user_id': userId,
        'document_type': documentType,
        'file_path': fileName,
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('Error uploading verification document: $e');
    }
  }
}
